import 'package:moment_app/features/users/presentation/user_identity_view.dart';
import 'package:moment_app/features/users/presentation/friend_chat_screen.dart';
import 'package:moment_app/features/users/data/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moment_app/features/chat/data/chat_api_client.dart';
import 'package:moment_app/features/chat/data/chat_repository.dart';
import 'package:moment_app/features/chat/domain/chat_message.dart';
import 'package:moment_app/features/chat/presentation/chat_screen.dart';
import 'package:moment_app/features/groups/data/groups_api_client.dart';
import 'package:moment_app/features/groups/data/groups_repository.dart';
import 'package:moment_app/features/groups/presentation/group_members_screen.dart';
import 'package:moment_app/features/users/data/friend_conversations_api_client.dart';
import 'package:moment_app/features/users/data/friend_requests_api_client.dart';
import 'package:moment_app/features/users/data/friends_api_client.dart';
import 'package:moment_app/features/users/data/users_repository.dart';
import 'package:moment_app/features/users/data/conversations_repository.dart';

class _ChatRepository implements ChatRepository {
  _ChatRepository({this.messages});
  final List<ChatMessage>? messages;
  @override
  void joinConversation(String conversationId) {}
  @override
  void leaveConversation(String conversationId) {}
  @override
  Stream<ChatMessage> get messageStream => const Stream.empty();
  @override
  Future<ChatMessagePage> loadMessagesForConversation({
    required String conversationId,
    int limit = 50,
  }) async => ChatMessagePage(
    writable: true,
    items:
        messages ??
        [
          ChatMessage(
            id: 'message',
            conversationId: conversationId,
            senderId: 'alice',
            senderUsername: 'Alice',
            senderAvatarUrl: 'preset:gold',
            content: 'Hello everyone',
            createdAt: DateTime(2026, 9, 26, 12),
          ),
        ],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GroupsRepository implements GroupsRepository {
  bool fail = false;
  @override
  Future<List<GroupSummary>> listMyGroups() async {
    if (fail) throw StateError('Offline');
    return const [
      GroupSummary(
        id: 'group',
        name: 'Book Club',
        inviteCode: 'books',
        conversationId: 'group-chat',
      ),
    ];
  }

  @override
  Future<List<GroupMemberSummary>> listGroupMembers(String groupId) async =>
      const [GroupMemberSummary(id: 'alice', username: 'Alice', isSelf: false)];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FriendsRepository implements UsersRepository {
  @override
  Future<List<FriendSummary>> loadFriends() async => const [
    FriendSummary(id: 'alice', username: 'Alice'),
  ];
  @override
  Future<List<FriendRequestItem>> loadIncomingRequests() async => [];
  @override
  Future<List<FriendRequestItem>> loadOutgoingRequests() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessagingRepository implements ConversationsRepository {
  @override
  Future<FriendConversationSummary> ensureFriendConversation(
    String friendId,
  ) async {
    expect(friendId, 'alice');
    return const FriendConversationSummary(
      conversationId: 'alice-chat',
      displayName: 'Alice',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpChat(WidgetTester tester, _GroupsRepository groups) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const ChatScreen(
          conversationId: 'group-chat',
          isGroup: true,
          title: 'Book Club',
        ),
      ),
      GoRoute(
        path: '/friend/:userId',
        builder: (_, state) => FriendChatScreen(
          userId: state.pathParameters['userId']!,
          title: 'Alice',
        ),
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Opened ${state.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeAccountIdProvider.overrideWithValue('me'),
        chatRepositoryProvider.overrideWithValue(_ChatRepository()),
        groupsRepositoryProvider.overrideWithValue(groups),
        usersRepositoryProvider.overrideWithValue(_FriendsRepository()),
        conversationsRepositoryProvider.overrideWithValue(
          _MessagingRepository(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final kind in ['direct', 'group', 'moment']) {
    testWidgets(
      '$kind chat groups consecutive senders and places time beside text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final senders = ['alice', 'alice', 'me', 'me', 'alice'];
        final messages = [
          for (var i = 0; i < senders.length; i++)
            ChatMessage(
              id: 'message-$i',
              conversationId: 'chat',
              senderId: senders[i],
              senderUsername: senders[i] == 'me' ? 'Me' : 'Alice',
              senderAvatarUrl: 'preset:gold',
              content: 'Text $i',
              createdAt: DateTime(2026, 9, 26, 12, i),
            ),
        ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeAccountIdProvider.overrideWithValue('me'),
              chatRepositoryProvider.overrideWithValue(
                _ChatRepository(messages: messages),
              ),
              usersRepositoryProvider.overrideWithValue(_FriendsRepository()),
            ],
            child: MaterialApp(
              home: ChatScreen(
                conversationId: 'chat',
                isGroup: kind == 'group',
                isTemporary: kind == 'moment',
                title: 'Chat',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(UserName), findsNWidgets(2));
        expect(find.text('Me'), findsNothing);
        expect(find.byType(UserIdentityView), findsNWidgets(2));
        for (var i = 0; i < messages.length; i++) {
          final text = tester.getRect(find.text('Text $i'));
          final time = tester.getRect(find.text('12:0$i'));
          expect(time.left, greaterThan(text.right));
          expect(time.bottom, closeTo(text.bottom, 1));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('group chat opens group info and member opens friend chat', (
    tester,
  ) async {
    await _pumpChat(tester, _GroupsRepository());
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Group info'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupMembersScreen), findsOneWidget);
    expect(find.text('Invite Code'), findsOneWidget);

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChatScreen>(find.byType(ChatScreen).last).conversationId,
      'alice-chat',
    );
    GoRouter.of(tester.element(find.byType(ChatScreen).last)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(GroupMembersScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('group title opens info and failed requests can be retried', (
    tester,
  ) async {
    final groups = _GroupsRepository()..fail = true;
    await _pumpChat(tester, groups);
    await tester.tap(find.text('Book Club'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load group details. Try again.'),
      findsOneWidget,
    );

    groups.fail = false;
    await tester.tap(find.byTooltip('Group info'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupMembersScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
  });
}

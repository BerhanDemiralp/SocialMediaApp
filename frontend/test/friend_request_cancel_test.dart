import 'package:moment_app/features/users/data/user_session.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moment_app/features/groups/data/groups_api_client.dart';
import 'package:moment_app/features/groups/data/groups_repository.dart';
import 'package:moment_app/features/groups/presentation/group_members_screen.dart';
import 'package:moment_app/features/users/data/friend_requests_api_client.dart';
import 'package:moment_app/features/users/data/friends_api_client.dart';
import 'package:moment_app/features/users/data/users_repository.dart';
import 'package:moment_app/features/users/data/conversations_repository.dart';
import 'package:moment_app/features/users/data/user_search_api_client.dart';
import 'package:moment_app/features/home/presentation/home_friends_screen.dart';

class _FriendsRepository implements UsersRepository {
  bool pending = false;
  bool failCancel = false;
  bool incoming = false;
  bool isFriend = false;
  bool failRespond = false;
  Completer<void>? responseGate;
  final acceptedIds = <String>[];
  final rejectedIds = <String>[];
  int sent = 0;
  final cancelledIds = <String>[];

  @override
  Future<List<UserSummary>> searchUsers(String query) async => const [
    UserSummary(id: 'alice', username: 'Alice'),
  ];
  @override
  Future<List<FriendSummary>> loadFriends() async =>
      isFriend ? [const FriendSummary(id: 'alice', username: 'Alice')] : [];
  @override
  Future<List<FriendRequestItem>> loadIncomingRequests() async => incoming
      ? [
          const FriendRequestItem(
            id: 'incoming-1',
            userId: 'alice',
            username: 'Alice',
            avatarUrl: null,
            direction: FriendRequestDirection.incoming,
          ),
        ]
      : [];

  @override
  Future<void> acceptRequest(String id) async {
    acceptedIds.add(id);
    if (responseGate != null) await responseGate!.future;
    if (failRespond) throw StateError('Offline');
    incoming = false;
    isFriend = true;
  }

  @override
  Future<void> rejectRequest(String id) async {
    rejectedIds.add(id);
    if (failRespond) throw StateError('Offline');
    incoming = false;
  }

  @override
  Future<List<FriendRequestItem>> loadOutgoingRequests() async => pending
      ? [
          const FriendRequestItem(
            id: 'request-1',
            userId: 'alice',
            username: 'Alice',
            avatarUrl: null,
            direction: FriendRequestDirection.outgoing,
          ),
        ]
      : [];
  @override
  Future<void> sendFriendRequest(String targetUserId) async {
    expect(targetUserId, 'alice');
    sent++;
    pending = true;
  }

  @override
  Future<void> cancelRequest(String id) async {
    cancelledIds.add(id);
    if (failCancel) throw StateError('Offline');
    pending = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GroupsRepository implements GroupsRepository {
  @override
  Future<List<GroupSummary>> listMyGroups() async => [];
  @override
  Future<List<GroupMemberSummary>> listGroupMembers(String groupId) async =>
      const [GroupMemberSummary(id: 'alice', username: 'Alice', isSelf: false)];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessagingRepository implements ConversationsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FriendsRepository repo, {
  required bool group,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeAccountIdProvider.overrideWithValue('me'),
        usersRepositoryProvider.overrideWithValue(repo),
        groupsRepositoryProvider.overrideWithValue(_GroupsRepository()),
        conversationsRepositoryProvider.overrideWithValue(
          _MessagingRepository(),
        ),
      ],
      child: MaterialApp(
        home: group
            ? const GroupMembersScreen(
                groupId: 'group',
                groupName: 'Books',
                inviteCode: 'code',
              )
            : const HomeFriendsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (!group) {
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final accept in [true, false]) {
    testWidgets(
      'group incoming request can be ${accept ? 'accepted' : 'declined'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = _FriendsRepository()..incoming = true;
        await _pumpScreen(tester, repo, group: true);
        expect(find.text('Requested you'), findsNothing);
        expect(find.text('Accept'), findsOneWidget);
        expect(find.byTooltip('Decline request'), findsOneWidget);
        await tester.tap(
          accept ? find.text('Accept') : find.byTooltip('Decline request'),
        );
        await tester.pumpAndSettle();
        expect(accept ? repo.acceptedIds : repo.rejectedIds, ['incoming-1']);
        expect(repo.cancelledIds, isEmpty);
        expect(find.text('Accept'), findsNothing);
        expect(
          accept ? find.byTooltip('Friend options') : find.text('Add friend'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 4));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('failed incoming response preserves actions for retry', (
    tester,
  ) async {
    final repo = _FriendsRepository()
      ..incoming = true
      ..failRespond = true;
    await _pumpScreen(tester, repo, group: true);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text('Could not accept request. Try again.'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(repo.incoming, isTrue);
    repo.failRespond = false;
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Friend options'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('both incoming actions are disabled while responding', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = _FriendsRepository()
      ..incoming = true
      ..responseGate = gate;
    await _pumpScreen(tester, repo, group: true);
    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Accept'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
          .onPressed,
      isNull,
    );
    expect(repo.acceptedIds, ['incoming-1']);
    expect(repo.rejectedIds, isEmpty);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Friend options'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  for (final group in [false, true]) {
    testWidgets(
      'can send, cancel and resend from ${group ? 'group' : 'search'}',
      (tester) async {
        final repo = _FriendsRepository();
        await _pumpScreen(tester, repo, group: group);
        await tester.tap(find.text('Add friend'));
        await tester.pumpAndSettle();
        expect(repo.sent, 1);
        expect(find.byTooltip('Cancel request'), findsWidgets);

        await tester.tap(find.byTooltip('Cancel request').first);
        await tester.pumpAndSettle();
        expect(repo.cancelledIds, ['request-1']);
        expect(find.byTooltip('Cancel request'), findsNothing);
        expect(find.text('Add friend'), findsOneWidget);

        await tester.tap(find.text('Add friend'));
        await tester.pumpAndSettle();
        expect(repo.sent, 2);
        expect(find.byTooltip('Cancel request'), findsWidgets);
        await tester.pump(const Duration(seconds: 4));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('failed cancellation keeps pending request and allows retry', (
    tester,
  ) async {
    final repo = _FriendsRepository()
      ..pending = true
      ..failCancel = true;
    await _pumpScreen(tester, repo, group: true);
    await tester.tap(find.byTooltip('Cancel request').first);
    await tester.pumpAndSettle();
    expect(repo.pending, isTrue);
    expect(
      find.text('Could not cancel friend request. Try again.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Cancel request'), findsWidgets);

    repo.failCancel = false;
    await tester.tap(find.byTooltip('Cancel request').first);
    await tester.pumpAndSettle();
    expect(repo.cancelledIds, ['request-1', 'request-1']);
    expect(find.text('Add friend'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });
}

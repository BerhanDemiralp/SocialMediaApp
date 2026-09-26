import 'package:moment_app/features/users/presentation/friend_chat_screen.dart';
import 'package:moment_app/core/theme/app_theme.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moment_app/features/home/presentation/home_messages_screen.dart';
import 'package:moment_app/features/users/data/conversations_repository.dart';
import 'package:moment_app/features/users/data/friend_conversations_api_client.dart';
import 'package:moment_app/features/users/data/friends_api_client.dart';
import 'package:moment_app/features/users/data/user_session.dart';
import 'package:moment_app/features/users/data/users_repository.dart';
import 'package:moment_app/features/users/domain/user_identity.dart';
import 'package:moment_app/features/users/domain/user_relationship.dart';
import 'package:moment_app/features/users/presentation/app_avatar.dart';
import 'package:moment_app/features/users/presentation/user_card.dart';
import 'package:moment_app/features/users/presentation/user_conversations.dart';
import 'package:moment_app/features/users/presentation/user_identity_view.dart';
import 'package:moment_app/features/users/presentation/user_relationships_controller.dart';
import 'support/fake_users.dart';

const alice = UserIdentity(
  id: 'alice',
  username: 'Alice',
  avatarUrl: 'preset:gold',
);

class FakeConversations implements ConversationsRepository {
  int ensured = 0;
  List<FriendConversationSummary> items = [];
  Completer<List<FriendConversationSummary>>? loadGate;
  Completer<void>? gate;
  @override
  Future<FriendConversationSummary> ensureFriendConversation(
    String friendId,
  ) async {
    ensured++;
    if (gate != null) await gate!.future;
    return const FriendConversationSummary(
      conversationId: 'alice-chat',
      displayName: 'Alice',
      friendId: 'alice',
    );
  }

  @override
  Future<List<FriendConversationSummary>> loadFriendConversations() async =>
      loadGate == null ? items : await loadGate!.future;
}

Widget cardView(RelationshipKind kind, {UserIdentity user = alice}) =>
    UserCardView(
      user: user,
      kind: kind,
      busy: false,
      needsRetry: kind == RelationshipKind.unknown,
      loading: false,
      onRetry: () {},
      onMessage: () {},
      onAction: (_) {},
    );

void main() {
  testWidgets('all user card states have equal standard dimensions', (
    tester,
  ) async {
    for (final width in [320.0, 390.0, 600.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Column(
                children: [
                  for (final kind in RelationshipKind.values) cardView(kind),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sizes = [
        for (final card in find.byType(Card).evaluate())
          tester.getSize(find.byWidget(card.widget)),
      ];
      expect(sizes.toSet().length, 1, reason: 'width=$width: $sizes');
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('card actions stay to the right of avatar and name', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: cardView(RelationshipKind.incoming)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final identity = tester.getRect(find.byType(UserIdentityView));
    final accept = tester.getRect(find.widgetWithText(FilledButton, 'Accept'));
    final cancel = tester.getRect(find.byTooltip('Decline request'));
    expect(accept.left, greaterThan(identity.right));
    expect(cancel.left, greaterThan(identity.right));
    expect((accept.top + cancel.bottom) / 2, identity.center.dy);
  });

  testWidgets('known friend opens directly without ensure or list reload', (
    tester,
  ) async {
    final messaging = FakeConversations();
    final users = FakeUsersRepository()
      ..friends = [const FriendSummary(id: 'alice', username: 'Alice')];
    final container = ProviderContainer(
      overrides: [
        activeAccountIdProvider.overrideWithValue('me'),
        usersRepositoryProvider.overrideWithValue(users),
        conversationsRepositoryProvider.overrideWithValue(messaging),
        userConversationsProvider.overrideWith(
          (ref) async => [
            const FriendConversationSummary(
              conversationId: 'known-chat',
              displayName: 'Alice',
              friendId: 'alice',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: UserCard(user: alice)),
        ),
        GoRoute(
          path: '/conversation/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Chat ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await container.read(userConversationsProvider.future);
    await container.read(userRelationshipsProvider.notifier).refresh();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final revision = container.read(conversationsRevisionProvider);
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Chat known-chat'), findsOneWidget);
    expect(messaging.ensured, 0);
    expect(container.read(conversationsRevisionProvider), revision);
    router.pop();
    await tester.pumpAndSettle();
  });

  test(
    'resolved friend IDs are reused and cleared on account switch',
    () async {
      final account = StateProvider<String?>((ref) => 'me');
      final messaging = FakeConversations();
      final users = FakeUsersRepository()
        ..friends = [const FriendSummary(id: 'alice', username: 'Alice')];
      final container = ProviderContainer(
        overrides: [
          activeAccountIdProvider.overrideWith((ref) => ref.watch(account)),
          usersRepositoryProvider.overrideWithValue(users),
          conversationsRepositoryProvider.overrideWithValue(messaging),
        ],
      );
      addTearDown(container.dispose);
      await container.read(userRelationshipsProvider.notifier).refresh();
      expect(
        await container.read(friendChatIdProvider('alice').future),
        'alice-chat',
      );
      expect(
        await container.read(friendChatIdProvider('alice').future),
        'alice-chat',
      );
      expect(messaging.ensured, 1);
      container.read(account.notifier).state = null;
      await expectLater(
        container.read(friendChatIdProvider('alice').future),
        throwsStateError,
      );
    },
  );

  testWidgets('returning from chat retains rows while refreshing previews', (
    tester,
  ) async {
    final messaging = FakeConversations()
      ..items = [
        const FriendConversationSummary(
          conversationId: 'known-chat',
          displayName: 'Alice',
          friendId: 'alice',
          lastMessagePreview: 'Previous message',
        ),
      ];
    final users = FakeUsersRepository()
      ..friends = [const FriendSummary(id: 'alice', username: 'Alice')];
    final container = ProviderContainer(
      overrides: [
        activeAccountIdProvider.overrideWithValue('me'),
        usersRepositoryProvider.overrideWithValue(users),
        conversationsRepositoryProvider.overrideWithValue(messaging),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: HomeMessagesScreen()),
        ),
        GoRoute(
          path: '/conversation/:id',
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const Scaffold(body: Text('Chat opened')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Chat opened'), findsOneWidget);
    messaging.loadGate = Completer<List<FriendConversationSummary>>();
    router.pop();
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Previous message'), findsOneWidget);
      expect(find.byType(UserCard), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    }
    messaging.loadGate!.complete([
      const FriendConversationSummary(
        conversationId: 'known-chat',
        displayName: 'Alice',
        friendId: 'alice',
        lastMessagePreview: 'Latest message',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Latest message'), findsOneWidget);
    expect(find.byType(UserCard), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('all card states fit 320px with 200% text in $brightness', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final kind in RelationshipKind.values) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: brightness == Brightness.dark
                  ? AppTheme.dark
                  : AppTheme.light,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 1100),
                  textScaler: TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: cardView(
                      kind,
                      user: const UserIdentity(
                        id: 'alice',
                        username:
                            'A very long name that must never hide any available action',
                        avatarUrl: 'preset:gold',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: kind.name);
        for (final button in find.byType(FilledButton).evaluate()) {
          final size = tester.getSize(find.byWidget(button.widget));
          expect(size.height, greaterThanOrEqualTo(48));
          expect(size.width, greaterThanOrEqualTo(48));
        }
        if (kind == RelationshipKind.incoming) {
          expect(find.text('Accept'), findsOneWidget);
          expect(find.byTooltip('Decline request'), findsOneWidget);
        }
        if (kind == RelationshipKind.friend) {
          expect(find.text('Message'), findsNothing);
          expect(find.byTooltip('Friend options'), findsOneWidget);
          await tester.tap(find.byTooltip('Friend options'));
          await tester.pumpAndSettle();
          expect(find.text('Remove friend'), findsOneWidget);
          await tester.tap(find.text('Remove friend'));
          await tester.pumpAndSettle();
        }
      }
    });
  }

  testWidgets(
    'avatar presets, invalid values and failed URLs have visible fallbacks',
    (tester) async {
      for (final value in [
        'preset:gold',
        ' preset:gold ',
        '',
        'broken',
        'https://invalid.test/avatar.png',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: AppAvatar(username: 'Alice', avatarUrl: value),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byIcon(
            value.trim() == 'preset:gold' ? Icons.wb_sunny : Icons.person,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'profile edit updates all identity variants despite older list data',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  UserIdentityView(user: alice),
                  UserIdentityView(
                    user: alice,
                    layout: UserIdentityLayout.header,
                  ),
                  UserIdentityView(
                    user: alice,
                    layout: UserIdentityLayout.avatar,
                  ),
                  UserName(user: alice),
                ],
              ),
            ),
          ),
        ),
      );
      container.read(userIdentityOverridesProvider.notifier).state = {
        'alice': const UserIdentity(
          id: 'alice',
          username: 'Alice Updated',
          avatarUrl: 'preset:blue',
        ),
      };
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Alice Updated'), findsNWidgets(3));
      expect(find.byIcon(Icons.bolt), findsNWidgets(3));
    },
  );

  testWidgets(
    'accept/remove updates multiple cards and Messages without reloading',
    (tester) async {
      final repo = FakeUsersRepository()
        ..incoming = [FakeUsersRepository.request('alice')];
      final messaging = FakeConversations();
      final container = ProviderContainer(
        overrides: [
          activeAccountIdProvider.overrideWithValue('me'),
          usersRepositoryProvider.overrideWithValue(repo),
          conversationsRepositoryProvider.overrideWithValue(messaging),
        ],
      );
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  UserCard(user: alice),
                  UserCard(user: alice),
                  Expanded(child: HomeMessagesScreen()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accept'), findsNWidgets(2));
      final gate = Completer<void>();
      repo.beforeMutation = (_, _) => gate.future;
      await tester.tap(find.text('Accept').first);
      await tester.pump();
      for (final button in tester.widgetList<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept'),
      )) {
        expect(button.onPressed, isNull);
      }
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Message'), findsNothing);
      expect(find.byTooltip('Friend options'), findsNWidgets(3));
      expect(
        container
            .read(userRelationshipsProvider)
            .usersOfKind(RelationshipKind.incoming),
        isEmpty,
      );
      await tester.tap(find.byTooltip('Friend options').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove friend'));
      await tester.pumpAndSettle();
      expect(find.text('Message'), findsNothing);
      expect(find.text('Add friend'), findsNWidgets(2));
      expect(repo.calls, [
        (UserAction.accept, 'alice-request'),
        (UserAction.remove, 'alice'),
      ]);
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chat surface opens before ensure; account switch discards late result',
    (tester) async {
      final account = StateProvider<String?>((ref) => 'first');
      final first = FakeUsersRepository()
        ..friends = [const FriendSummary(id: 'alice', username: 'Alice')];
      final messaging = FakeConversations()..gate = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          activeAccountIdProvider.overrideWith((ref) => ref.watch(account)),
          usersRepositoryProvider.overrideWithValue(first),
          conversationsRepositoryProvider.overrideWithValue(messaging),
        ],
      );
      addTearDown(container.dispose);
      late BuildContext page;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) {
              page = context;
              return const Scaffold(body: Text('Home'));
            },
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
            builder: (_, _) => const Scaffold(body: Text('Chat opened')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await container.read(userRelationshipsProvider.notifier).refresh();
      final coordinator = container.read(
        userConversationCoordinatorProvider.notifier,
      );
      final pending = coordinator.open(page, user: alice);
      await coordinator.open(page, user: alice);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(FriendChatScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(messaging.ensured, 1);
      container.read(account.notifier).state = null;
      expect(
        identical(
          container.read(userConversationCoordinatorProvider.notifier),
          coordinator,
        ),
        isFalse,
      );
      messaging.gate!.complete();

      await tester.pumpAndSettle();
      expect(find.text('Chat opened'), findsNothing);
      expect(find.text('Could not open conversation.'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await pending;
      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets(
    'historical conversation uses existing ID even without friendship',
    (tester) async {
      final repo = FakeUsersRepository();
      final messaging = FakeConversations();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: HomeMessagesScreen()),
          ),
          GoRoute(
            path: '/conversation/:id',
            builder: (_, state) =>
                Scaffold(body: Text('History ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAccountIdProvider.overrideWithValue('me'),
            usersRepositoryProvider.overrideWithValue(repo),
            conversationsRepositoryProvider.overrideWithValue(messaging),
            userConversationsProvider.overrideWith(
              (ref) async => [
                const FriendConversationSummary(
                  conversationId: 'old-chat',
                  friendId: 'alice',
                  displayName: 'Alice',
                  writable: false,
                ),
              ],
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Read-only history'), findsOneWidget);
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.text('History old-chat'), findsOneWidget);
      expect(messaging.ensured, 0);
    },
  );

  testWidgets(
    'account reload hides retained conversations before the next response',
    (tester) async {
      final account = StateProvider<String?>((ref) => 'first');
      final next = Completer<List<FriendConversationSummary>>();
      final container = ProviderContainer(
        overrides: [
          activeAccountIdProvider.overrideWith((ref) => ref.watch(account)),
          usersRepositoryProvider.overrideWithValue(FakeUsersRepository()),
          conversationsRepositoryProvider.overrideWithValue(
            FakeConversations(),
          ),
          userConversationsProvider.overrideWith((ref) {
            return ref.watch(activeAccountIdProvider) == 'first'
                ? Future.value([
                    const FriendConversationSummary(
                      conversationId: 'private',
                      friendId: 'alice',
                      displayName: 'First account contact',
                    ),
                  ])
                : next.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HomeMessagesScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('First account contact'), findsOneWidget);
      container.read(account.notifier).state = 'second';
      await tester.pump();
      expect(find.text('First account contact'), findsNothing);
      next.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('First account contact'), findsNothing);
    },
  );

  testWidgets('capture shared cards for visual review', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_USER_CARDS')) return;
    final disabledShadows = debugDisableShadows;
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = disabledShadows);
    await tester.runAsync(() async {
      final font = FontLoader('ReviewFont')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes(),
            ),
          ),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light.copyWith(
            textTheme: AppTheme.light.textTheme.apply(fontFamily: 'ReviewFont'),
            textButtonTheme: TextButtonThemeData(
              style: AppTheme.light.textButtonTheme.style!.copyWith(
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(
                    fontFamily: 'ReviewFont',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              appBar: AppBar(title: const Text('People')),
              body: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  cardView(
                    RelationshipKind.none,
                    user: const UserIdentity(
                      id: 'a',
                      username: 'Deniz',
                      avatarUrl: 'preset:teal',
                    ),
                  ),
                  cardView(
                    RelationshipKind.outgoing,
                    user: const UserIdentity(
                      id: 'b',
                      username: 'Ece',
                      avatarUrl: 'preset:coral',
                    ),
                  ),
                  cardView(
                    RelationshipKind.incoming,
                    user: const UserIdentity(
                      id: 'c',
                      username: 'Can',
                      avatarUrl: 'preset:gold',
                    ),
                  ),
                  cardView(
                    RelationshipKind.friend,
                    user: const UserIdentity(
                      id: 'd',
                      username: 'Mert',
                      avatarUrl: 'preset:blue',
                    ),
                  ),
                  cardView(
                    RelationshipKind.self,
                    user: const UserIdentity(
                      id: 'me',
                      username: 'Berhan',
                      avatarUrl: 'preset:green',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/verification/user-cards.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    debugDisableShadows = disabledShadows;
  });
}

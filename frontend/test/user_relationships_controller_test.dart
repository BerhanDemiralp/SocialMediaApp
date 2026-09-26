import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moment_app/features/users/data/friends_api_client.dart';
import 'package:moment_app/features/users/data/user_session.dart';
import 'package:moment_app/features/users/data/users_repository.dart';
import 'package:moment_app/features/users/domain/user_identity.dart';
import 'package:moment_app/features/users/domain/user_relationship.dart';
import 'package:moment_app/features/users/presentation/user_identity_view.dart';
import 'package:moment_app/features/users/presentation/user_relationships_controller.dart';
import 'support/fake_users.dart';

const alice = UserIdentity(id: 'alice', username: 'Alice');
const bob = UserIdentity(id: 'bob', username: 'Bob');
const carl = UserIdentity(id: 'carl', username: 'Carl');
Future<void> flush() => Future<void>.delayed(Duration.zero);

UserRelationshipsController create(FakeUsersRepository repo) {
  final controller = UserRelationshipsController(
    accountId: 'me',
    repository: repo,
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  test(
    'unknown until a complete snapshot; failed initial load can retry',
    () async {
      final repo = FakeUsersRepository()..readGate = Completer<void>();
      final controller = create(repo);
      expect(controller.state.kindFor('me'), RelationshipKind.self);
      expect(controller.state.kindFor('alice'), RelationshipKind.unknown);
      repo.failReads = true;
      repo.readGate!.complete();
      await flush();
      expect(controller.state.loaded, isFalse);
      expect(controller.state.error, isNotNull);
      expect(
        await controller.perform(alice, UserAction.add),
        isA<UserActionResult>(),
      );
      expect(repo.calls, isEmpty);
      repo.failReads = false;
      await controller.refresh();
      expect(controller.state.kindFor('alice'), RelationshipKind.none);
      expect(controller.state.error, isNull);
    },
  );

  test(
    'friend wins over stale requests; conflicting directions stay unknown',
    () async {
      final repo = FakeUsersRepository()
        ..friends = [const FriendSummary(id: 'alice', username: 'Alice')]
        ..incoming = [
          FakeUsersRepository.request('alice'),
          FakeUsersRepository.request('bob'),
        ]
        ..outgoing = [
          FakeUsersRepository.request('alice', outgoing: true),
          FakeUsersRepository.request('bob', outgoing: true),
        ];
      final controller = create(repo);
      await flush();
      expect(controller.state.kindFor('alice'), RelationshipKind.friend);
      expect(controller.state.kindFor('bob'), RelationshipKind.unknown);
      expect(controller.state.error, isNotNull);
      repo.outgoing.removeWhere((r) => r.userId == 'bob');
      await controller.refresh();
      expect(controller.state.kindFor('bob'), RelationshipKind.incoming);
    },
  );

  test(
    'all transitions use request IDs and update shared projections',
    () async {
      final repo = FakeUsersRepository()
        ..incoming = [
          FakeUsersRepository.request('alice'),
          FakeUsersRepository.request('bob'),
        ];
      final controller = create(repo);
      await flush();
      await controller.perform(carl, UserAction.add);
      expect(controller.state.records['carl']?.requestId, 'carl-request');
      await controller.perform(carl, UserAction.cancel);
      expect(controller.state.kindFor('carl'), RelationshipKind.none);
      await controller.perform(alice, UserAction.accept);
      expect(controller.state.kindFor('alice'), RelationshipKind.friend);
      await controller.perform(alice, UserAction.remove);
      expect(controller.state.kindFor('alice'), RelationshipKind.none);
      await controller.perform(bob, UserAction.decline);
      expect(controller.state.kindFor('bob'), RelationshipKind.none);
      expect(repo.calls, [
        (UserAction.add, 'carl'),
        (UserAction.cancel, 'carl-request'),
        (UserAction.accept, 'alice-request'),
        (UserAction.remove, 'alice'),
        (UserAction.decline, 'bob-request'),
      ]);
    },
  );

  test(
    'one operation per target while other users remain actionable',
    () async {
      final gate = Completer<void>();
      final repo = FakeUsersRepository()
        ..incoming = [FakeUsersRepository.request('alice')];
      repo.beforeMutation = (_, id) async {
        if (id == 'alice-request') await gate.future;
      };
      final controller = create(repo);
      await flush();
      final acceptance = controller.perform(alice, UserAction.accept);
      expect(controller.state.busy, contains('alice'));
      expect(await controller.perform(alice, UserAction.decline), isNull);
      await controller.perform(bob, UserAction.add);
      expect(controller.state.kindFor('bob'), RelationshipKind.outgoing);
      gate.complete();
      await acceptance;
      expect(repo.calls.length, 2);
      expect(controller.state.busy, isEmpty);
    },
  );

  test(
    'failed mutation preserves confirmed relationship and permits retry',
    () async {
      final repo = FakeUsersRepository()
        ..incoming = [FakeUsersRepository.request('alice')]
        ..failMutations = true;
      final controller = create(repo);
      await flush();
      expect(
        (await controller.perform(alice, UserAction.accept))?.succeeded,
        isFalse,
      );
      expect(controller.state.kindFor('alice'), RelationshipKind.incoming);
      expect(controller.state.busy, isEmpty);
      repo.failMutations = false;
      expect(
        (await controller.perform(alice, UserAction.accept))?.succeeded,
        isTrue,
      );
      expect(controller.state.kindFor('alice'), RelationshipKind.friend);
    },
  );

  test(
    'post-success refresh failure retains transition and resolves missing ID on retry',
    () async {
      final repo = FakeUsersRepository();
      final controller = create(repo);
      await flush();
      repo.failReads = true;
      expect(
        (await controller.perform(alice, UserAction.add))?.succeeded,
        isTrue,
      );
      expect(controller.state.kindFor('alice'), RelationshipKind.outgoing);
      expect(controller.state.records['alice']?.requestId, isNull);
      expect(controller.state.error, isNotNull);
      await controller.perform(alice, UserAction.cancel);
      expect(repo.calls.length, 1);
      repo.failReads = false;
      await controller.refresh();
      await controller.perform(alice, UserAction.cancel);
      expect(repo.calls.last, (UserAction.cancel, 'alice-request'));
    },
  );

  test('older refresh finishing after mutation cannot undo it', () async {
    final repo = FakeUsersRepository()
      ..incoming = [FakeUsersRepository.request('alice')];
    final controller = create(repo);
    await flush();
    final gate = Completer<void>();
    repo.readGate = gate;
    final oldRefresh = controller.refresh();
    repo.readGate = null;
    await controller.perform(alice, UserAction.accept);
    gate.complete();
    await oldRefresh;
    expect(controller.state.kindFor('alice'), RelationshipKind.friend);
    expect(controller.state.loading, isFalse);
  });

  test(
    'account switch disposes pending work and resets identities and locks',
    () async {
      final account = StateProvider<String?>((ref) => 'first');
      final first = FakeUsersRepository()
        ..incoming = [FakeUsersRepository.request('alice')];
      final second = FakeUsersRepository();
      final gate = Completer<void>();
      first.beforeMutation = (_, _) => gate.future;
      final container = ProviderContainer(
        overrides: [
          activeAccountIdProvider.overrideWith((ref) => ref.watch(account)),
          usersRepositoryProvider.overrideWith(
            (ref) => ref.watch(account) == 'first' ? first : second,
          ),
        ],
      );
      addTearDown(container.dispose);
      final old = container.read(userRelationshipsProvider.notifier);
      await flush();
      container.read(userIdentityOverridesProvider.notifier).state = {
        'alice': alice,
      };
      final pending = old.perform(alice, UserAction.accept);
      container.read(account.notifier).state = 'second';
      final fresh = container.read(userRelationshipsProvider.notifier);
      await flush();
      expect(fresh.state.accountId, 'second');
      expect(container.read(userIdentityOverridesProvider), isEmpty);
      gate.complete();
      expect(await pending, isNull);
      expect(old.isActive, isFalse);
      expect(fresh.state.kindFor('alice'), RelationshipKind.none);
      expect(fresh.state.busy, isEmpty);
      container.read(account.notifier).state = null;
      expect(container.read(userRelationshipsProvider).accountId, isNull);
      expect(container.read(userRelationshipsProvider).records, isEmpty);
    },
  );
}

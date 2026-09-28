import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_identity_adapters.dart';
import '../data/user_session.dart';
import '../data/users_repository.dart';
import '../domain/user_identity.dart';
import '../domain/user_relationship.dart';

class UserActionResult {
  const UserActionResult(this.message, {this.succeeded = true});
  final String message;
  final bool succeeded;
}

class UserRelationshipsController
    extends StateNotifier<UserRelationshipsState> {
  UserRelationshipsController({
    required String? accountId,
    required UsersRepository? repository,
    this.onChanged,
  }) : _repository = repository,
       super(UserRelationshipsState(accountId: accountId)) {
    if (accountId != null && repository != null) unawaited(refresh());
  }

  final UsersRepository? _repository;
  final void Function()? onChanged;
  bool get isActive => mounted;
  final Map<String, int> _versions = {};
  int _fetchSerial = 0;

  Future<void> refresh() async {
    if (!mounted || _repository == null || state.accountId == null) return;
    final serial = ++_fetchSerial;
    final versions = Map<String, int>.of(_versions);
    state = state.copyWith(loading: true);
    try {
      // Start all three reads together; publish only a complete snapshot.
      final friendsFuture = _repository.loadFriends();
      final incomingFuture = _repository.loadIncomingRequests();
      final outgoingFuture = _repository.loadOutgoingRequests();
      await Future.wait<Object>([
        friendsFuture,
        incomingFuture,
        outgoingFuture,
      ]);
      if (!mounted || serial != _fetchSerial) return;
      // Futures retain their types; Future.wait observes every failure.
      final friends = await friendsFuture;
      final incoming = await incomingFuture;
      final outgoing = await outgoingFuture;
      if (!mounted || serial != _fetchSerial) return;
      final records = <String, UserRelationship>{};
      for (final request in incoming) {
        records[request.userId] = UserRelationship(
          request.identity,
          RelationshipKind.incoming,
          requestId: request.id,
        );
      }
      for (final request in outgoing) {
        final conflict = records.containsKey(request.userId);
        records[request.userId] = UserRelationship(
          request.identity,
          conflict ? RelationshipKind.unknown : RelationshipKind.outgoing,
          requestId: conflict ? null : request.id,
        );
      }
      for (final friend in friends) {
        records[friend.id] = UserRelationship(
          friend.identity,
          RelationshipKind.friend,
        );
      }
      for (final id in {
        ...records.keys,
        ...state.records.keys,
        ..._versions.keys,
      }) {
        if ((_versions[id] ?? 0) != (versions[id] ?? 0)) {
          final current = state.records[id];
          if (current == null) {
            records.remove(id);
          } else {
            records[id] = current;
          }
        }
      }
      state = state.copyWith(
        records: records,
        loaded: true,
        loading: false,
        error: records.values.any((r) => r.kind == RelationshipKind.unknown)
            ? 'Some relationships could not be resolved. Please retry.'
            : null,
      );
    } catch (_) {
      if (!mounted || serial != _fetchSerial) return;
      state = state.copyWith(
        loading: false,
        error: 'Could not refresh relationships. Try again.',
      );
    }
  }

  Future<UserActionResult?> perform(
    UserIdentity user,
    UserAction action,
  ) async {
    if (!mounted ||
        _repository == null ||
        state.accountId == null ||
        state.busy.contains(user.id)) {
      return null;
    }
    final kind = state.kindFor(user.id);
    final expected = switch (action) {
      UserAction.add => RelationshipKind.none,
      UserAction.cancel => RelationshipKind.outgoing,
      UserAction.accept || UserAction.decline => RelationshipKind.incoming,
      UserAction.remove => RelationshipKind.friend,
    };
    final requestId = state.records[user.id]?.requestId;
    final needsRequest =
        action == UserAction.cancel ||
        action == UserAction.accept ||
        action == UserAction.decline;
    if (kind != expected || (needsRequest && requestId == null)) {
      return const UserActionResult(
        'Refresh this relationship before trying again.',
        succeeded: false,
      );
    }
    _versions[user.id] = (_versions[user.id] ?? 0) + 1;
    state = state.copyWith(busy: {...state.busy, user.id});
    try {
      switch (action) {
        case UserAction.add:
          await _repository.sendFriendRequest(user.id);
        case UserAction.cancel:
          await _repository.cancelRequest(requestId!);
        case UserAction.accept:
          await _repository.acceptRequest(requestId!);
        case UserAction.decline:
          await _repository.rejectRequest(requestId!);
        case UserAction.remove:
          await _repository.removeFriend(user.id);
      }
      if (!mounted) return null;
      _versions[user.id] = (_versions[user.id] ?? 0) + 1;
      final nextKind = switch (action) {
        UserAction.add => RelationshipKind.outgoing,
        UserAction.accept => RelationshipKind.friend,
        _ => RelationshipKind.none,
      };
      state = state.copyWith(
        records: {...state.records, user.id: UserRelationship(user, nextKind)},
      );
      onChanged?.call();
      // Failure here is a refresh error, never a failed successful mutation.
      await refresh();
      if (!mounted) return null;
      return UserActionResult(switch (action) {
        UserAction.add => 'Friend request sent to ${user.username}',
        UserAction.cancel => 'Friend request cancelled.',
        UserAction.accept => 'Friend request accepted.',
        UserAction.decline => 'Friend request declined.',
        UserAction.remove => 'Friend removed.',
      });
    } catch (_) {
      if (!mounted) return null;
      return UserActionResult(switch (action) {
        UserAction.add => 'Could not send friend request. Try again.',
        UserAction.cancel => 'Could not cancel friend request. Try again.',
        UserAction.accept => 'Could not accept request. Try again.',
        UserAction.decline => 'Could not decline request. Try again.',
        UserAction.remove => 'Could not remove friend. Try again.',
      }, succeeded: false);
    } finally {
      if (mounted) {
        state = state.copyWith(
          busy: {...state.busy}..remove(user.id),
          error: state.error,
        );
      }
    }
  }
}

final userRelationshipsProvider =
    StateNotifierProvider<UserRelationshipsController, UserRelationshipsState>((
      ref,
    ) {
      final accountId = ref.watch(activeAccountIdProvider);
      final controller = UserRelationshipsController(
        accountId: accountId,
        repository: accountId == null
            ? null
            : ref.watch(usersRepositoryProvider),
        onChanged: () =>
            ref.read(conversationsRevisionProvider.notifier).state++,
      );
      ref.listen(
        appResyncRevisionProvider,
        (_, _) => unawaited(controller.refresh()),
      );
      return controller;
    });

import 'dart:async';
import 'package:moment_app/features/users/data/friend_requests_api_client.dart';
import 'package:moment_app/features/users/data/friends_api_client.dart';
import 'package:moment_app/features/users/data/user_search_api_client.dart';
import 'package:moment_app/features/users/data/users_repository.dart';
import 'package:moment_app/features/users/domain/user_relationship.dart';

class FakeUsersRepository implements UsersRepository {
  List<FriendSummary> friends = [];
  List<FriendRequestItem> incoming = [];
  List<FriendRequestItem> outgoing = [];
  List<UserSummary> search = [];
  bool failReads = false;
  bool failMutations = false;
  Completer<void>? readGate;
  Future<void> Function(UserAction, String)? beforeMutation;
  final calls = <(UserAction, String)>[];
  int reads = 0;

  Future<List<T>> _read<T>(List<T> data) async {
    reads++;
    final snapshot = List<T>.of(data);
    if (readGate != null) await readGate!.future;
    if (failReads) throw StateError('Offline');
    return snapshot;
  }

  Future<void> _mutate(UserAction action, String id) async {
    calls.add((action, id));
    await beforeMutation?.call(action, id);
    if (failMutations) throw StateError('Offline');
  }

  @override
  Future<List<FriendSummary>> loadFriends() => _read(friends);
  @override
  Future<List<FriendRequestItem>> loadIncomingRequests() => _read(incoming);
  @override
  Future<List<FriendRequestItem>> loadOutgoingRequests() => _read(outgoing);
  @override
  Future<List<UserSummary>> searchUsers(String query) => _read(search);

  @override
  Future<void> sendFriendRequest(String id) async {
    await _mutate(UserAction.add, id);
    outgoing.add(request(id, outgoing: true));
  }

  @override
  Future<void> cancelRequest(String id) async {
    await _mutate(UserAction.cancel, id);
    outgoing.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> acceptRequest(String id) async {
    await _mutate(UserAction.accept, id);
    final item = incoming.firstWhere((r) => r.id == id);
    incoming.remove(item);
    friends.add(
      FriendSummary(
        id: item.userId,
        username: item.username,
        avatarUrl: item.avatarUrl,
      ),
    );
  }

  @override
  Future<void> rejectRequest(String id) async {
    await _mutate(UserAction.decline, id);
    incoming.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> removeFriend(String id) async {
    await _mutate(UserAction.remove, id);
    friends.removeWhere((f) => f.id == id);
  }

  static FriendRequestItem request(String id, {bool outgoing = false}) =>
      FriendRequestItem(
        id: '$id-request',
        userId: id,
        username: id,
        avatarUrl: 'preset:gold',
        direction: outgoing
            ? FriendRequestDirection.outgoing
            : FriendRequestDirection.incoming,
      );
}

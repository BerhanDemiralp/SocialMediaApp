import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/timing_http_client.dart';
import 'friend_requests_api_client.dart';
import 'friends_api_client.dart';
import 'user_search_api_client.dart';

final homeFriendsRepositoryProvider =
    Provider<HomeFriendsRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  final httpClient = TimingHttpClient();
  final searchApi = UserSearchApiClient(httpClient, supabaseClient);
  final requestsApi = FriendRequestsApiClient(httpClient, supabaseClient);
  final friendsApi = FriendsApiClient(httpClient, supabaseClient);

  ref.onDispose(httpClient.close);

  return HomeFriendsRepository(
    searchApiClient: searchApi,
    friendRequestsApiClient: requestsApi,
    friendsApiClient: friendsApi,
  );
});

class HomeFriendsRepository {
  HomeFriendsRepository({
    required UserSearchApiClient searchApiClient,
    required FriendRequestsApiClient friendRequestsApiClient,
    required FriendsApiClient friendsApiClient,
  })  : _searchApiClient = searchApiClient,
        _friendRequestsApiClient = friendRequestsApiClient,
        _friendsApiClient = friendsApiClient;

  final UserSearchApiClient _searchApiClient;
  final FriendRequestsApiClient _friendRequestsApiClient;
  final FriendsApiClient _friendsApiClient;

  Future<List<UserSummary>> searchUsers(String query) {
    return _searchApiClient.searchUsers(query: query);
  }

  Future<void> sendFriendRequest(String targetUserId) {
    return _friendRequestsApiClient.sendRequest(targetUserId: targetUserId);
  }

  Future<List<FriendRequestItem>> loadIncomingRequests() {
    return _friendRequestsApiClient.listIncoming();
  }

  Future<List<FriendRequestItem>> loadOutgoingRequests() {
    return _friendRequestsApiClient.listOutgoing();
  }

  Future<void> acceptRequest(String id) {
    return _friendRequestsApiClient.acceptRequest(id);
  }

  Future<void> rejectRequest(String id) {
    return _friendRequestsApiClient.rejectRequest(id);
  }

  Future<void> cancelRequest(String id) {
    return _friendRequestsApiClient.cancelRequest(id);
  }

  Future<List<FriendSummary>> loadFriends() {
    return _friendsApiClient.listFriends();
  }

  Future<void> removeFriend(String friendId) {
    return _friendsApiClient.removeFriend(friendId: friendId);
  }
}

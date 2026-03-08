import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'friend_requests_api_client.dart';
import 'user_search_api_client.dart';

final homeFriendsRepositoryProvider =
    Provider<HomeFriendsRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  final httpClient = http.Client();
  final searchApi = UserSearchApiClient(httpClient, supabaseClient);
  final requestsApi = FriendRequestsApiClient(httpClient, supabaseClient);

  ref.onDispose(httpClient.close);

  return HomeFriendsRepository(
    searchApiClient: searchApi,
    friendRequestsApiClient: requestsApi,
  );
});

class HomeFriendsRepository {
  HomeFriendsRepository({
    required UserSearchApiClient searchApiClient,
    required FriendRequestsApiClient friendRequestsApiClient,
  })  : _searchApiClient = searchApiClient,
        _friendRequestsApiClient = friendRequestsApiClient;

  final UserSearchApiClient _searchApiClient;
  final FriendRequestsApiClient _friendRequestsApiClient;

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
}


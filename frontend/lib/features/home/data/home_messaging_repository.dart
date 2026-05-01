import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/timing_http_client.dart';
import 'friend_conversations_api_client.dart';

final homeMessagingRepositoryProvider =
    Provider<HomeMessagingRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  final httpClient = TimingHttpClient();
  final apiClient = FriendConversationsApiClient(httpClient, supabaseClient);

  ref.onDispose(httpClient.close);

  return HomeMessagingRepository(apiClient: apiClient);
});

class HomeMessagingRepository {
  HomeMessagingRepository({required FriendConversationsApiClient apiClient})
      : _apiClient = apiClient;

  final FriendConversationsApiClient _apiClient;

  Future<List<FriendConversationSummary>> loadFriendConversations() {
    return _apiClient.listFriendConversations();
  }

  Future<FriendConversationSummary> ensureFriendConversation(
    String friendId,
  ) {
    return _apiClient.ensureFriendConversation(friendId: friendId);
  }
}

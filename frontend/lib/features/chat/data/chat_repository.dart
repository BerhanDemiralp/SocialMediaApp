import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/timing_http_client.dart';
import '../domain/chat_message.dart';
import 'chat_api_client.dart';
import 'chat_socket_client.dart';

class ChatRepository {
  ChatRepository({
    required ChatApiClient apiClient,
    required ChatSocketClient socketClient,
  })  : _apiClient = apiClient,
        _socketClient = socketClient;

  final ChatApiClient _apiClient;
  final ChatSocketClient _socketClient;

  Stream<ChatMessage> get messageStream => _socketClient.messageStream;

  String? get currentUserId => _apiClient.currentUserId;

  Future<List<ChatMessage>> loadMessagesForConversation({
    required String conversationId,
    int limit = 50,
  }) {
    return _apiClient.getMessagesForConversation(
      conversationId: conversationId,
      limit: limit,
    );
  }

  void joinConversation(String conversationId) {
    _socketClient.joinConversation(conversationId);
  }

  void leaveConversation(String conversationId) {
    _socketClient.leaveConversation(conversationId);
  }

  void sendMessage({
    required String conversationId,
    required String content,
  }) {
    _socketClient.sendMessage(
      conversationId: conversationId,
      content: content,
    );
  }

  void setTyping({
    required String conversationId,
    required bool isTyping,
  }) {
    _socketClient.setTyping(conversationId: conversationId, isTyping: isTyping);
  }

  Future<ChatMessage> sendMessageToConversation({
    required String conversationId,
    required String content,
  }) {
    return _apiClient.sendMessageToConversation(
      conversationId: conversationId,
      content: content,
    );
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  final apiClient = ChatApiClient(TimingHttpClient(), supabaseClient);
  final socketClient = ChatSocketClient(supabaseClient);
  ref.onDispose(() {
    apiClient.close();
    socketClient.dispose();
  });
  return ChatRepository(apiClient: apiClient, socketClient: socketClient);
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<List<ChatMessage>> loadMessages({
    required String matchId,
    int limit = 50,
  }) {
    return _apiClient.getMessages(matchId: matchId, limit: limit);
  }

  Future<List<ChatMessage>> loadMessagesForConversation({
    required String conversationId,
    int limit = 50,
  }) {
    return _apiClient.getMessagesForConversation(
      conversationId: conversationId,
      limit: limit,
    );
  }

  void joinMatch(String matchId) {
    _socketClient.joinMatch(matchId);
  }

  void leaveMatch(String matchId) {
    _socketClient.leaveMatch(matchId);
  }

  void sendMessage({
    required String matchId,
    required String content,
  }) {
    _socketClient.sendMessage(matchId: matchId, content: content);
  }

  void setTyping({
    required String matchId,
    required bool isTyping,
  }) {
    _socketClient.setTyping(matchId: matchId, isTyping: isTyping);
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
  final apiClient = ChatApiClient(http.Client(), supabaseClient);
  final socketClient = ChatSocketClient(supabaseClient);
  ref.onDispose(socketClient.dispose);
  return ChatRepository(apiClient: apiClient, socketClient: socketClient);
});

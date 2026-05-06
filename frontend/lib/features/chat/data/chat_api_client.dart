import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';
import '../domain/chat_message.dart';

class ChatMessagePage {
  const ChatMessagePage({
    required this.items,
    required this.writable,
  });

  final List<ChatMessage> items;
  final bool writable;
}

class ChatApiClient {
  ChatApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  String? get currentUserId => _supabaseClient.auth.currentUser?.id;

  void close() {
    _httpClient.close();
  }

  Future<ChatMessagePage> getMessagesForConversation({
    required String conversationId,
    int limit = 50,
  }) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for chat requests.');
    }

    final uri = Uri.parse(
      '${AppEnv.apiBaseUrl}/conversations/$conversationId/messages?limit=$limit',
    );

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load messages (status ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> items = body['items'] as List<dynamic>? ?? <dynamic>[];

    return ChatMessagePage(
      items: items
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      writable: body['writable'] as bool? ?? true,
    );
  }

  Future<ChatMessage> sendMessageToConversation({
    required String conversationId,
    required String content,
  }) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for chat requests.');
    }

    final uri = Uri.parse(
      '${AppEnv.apiBaseUrl}/conversations/$conversationId/messages',
    );

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw StateError(
        'Failed to send message (status ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    return ChatMessage.fromJson(body);
  }
}

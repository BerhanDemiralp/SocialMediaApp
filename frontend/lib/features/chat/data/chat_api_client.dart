import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';
import '../domain/chat_message.dart';

class ChatApiClient {
  ChatApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  Future<List<ChatMessage>> getMessages({
    required String matchId,
    int limit = 50,
  }) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for chat requests.');
    }

    final uri = Uri.parse(
      '${AppEnv.apiBaseUrl}/matches/$matchId/messages?limit=$limit',
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

    final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;

    return body
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}


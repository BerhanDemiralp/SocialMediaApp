import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';

class FriendSummary {
  const FriendSummary({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;
}

class FriendsApiClient {
  FriendsApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  Future<List<FriendSummary>> listFriends() async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for friends.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/friends');
    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load friends (status ${response.statusCode}).',
      );
    }

    final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;

    return body
        .map((e) {
          final map = e as Map<String, dynamic>;
          return FriendSummary(
            id: map['id'] as String,
            username: map['username'] as String,
            avatarUrl: map['avatar_url'] as String?,
          );
        })
        .toList();
  }

  Future<void> removeFriend({required String friendId}) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for friends.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/friends/$friendId');
    final response = await _httpClient.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw StateError(
        'Failed to remove friend (status ${response.statusCode}).',
      );
    }
  }
}

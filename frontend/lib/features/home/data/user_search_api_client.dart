import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';

class UserSummary {
  const UserSummary({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class UserSearchApiClient {
  UserSearchApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  Future<List<UserSummary>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for user search.');
    }

    final uri = Uri.parse(
      '${AppEnv.apiBaseUrl}/users/search?query=${Uri.encodeQueryComponent(query)}&limit=$limit',
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
        'Failed to search users (status ${response.statusCode}).',
      );
    }

    final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;

    return body
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}


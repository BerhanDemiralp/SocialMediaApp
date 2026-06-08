import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';
import '../../../core/network/timing_http_client.dart';

final userProfileApiClientProvider = Provider<UserProfileApiClient>((ref) {
  final httpClient = TimingHttpClient();
  ref.onDispose(httpClient.close);
  return UserProfileApiClient(httpClient, Supabase.instance.client);
});

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String email;
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class UserProfileApiClient {
  UserProfileApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  String _token() {
    final token = _supabaseClient.auth.currentSession?.accessToken;
    if (token == null) {
      throw StateError('No auth token available for profile.');
    }
    return token;
  }

  Future<UserProfile> getMyProfile() async {
    final response = await _httpClient.get(
      Uri.parse('${AppEnv.apiBaseUrl}/users/me'),
      headers: _headers(_token()),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load profile (status ${response.statusCode}).',
      );
    }

    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProfile> updateMyProfile({
    required String username,
    required String avatarUrl,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('${AppEnv.apiBaseUrl}/users/me'),
      headers: _headers(_token()),
      body: jsonEncode({'username': username, 'avatar_url': avatarUrl}),
    );

    if (response.statusCode != 200) {
      String message = 'Failed to update profile.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final rawMessage = body['message'];
        if (rawMessage is String && rawMessage.isNotEmpty) {
          message = rawMessage;
        }
      } catch (_) {
        // Keep the generic message.
      }
      throw StateError(message);
    }

    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

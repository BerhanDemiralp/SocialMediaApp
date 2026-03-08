import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';

class FriendRequestItem {
  const FriendRequestItem({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.direction,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final FriendRequestDirection direction;
}

enum FriendRequestDirection { incoming, outgoing }

class FriendRequestsApiClient {
  FriendRequestsApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<void> sendRequest({required String targetUserId}) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for friend requests.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/friends/requests');
    final response = await _httpClient.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({'targetUserId': targetUserId}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw StateError(
        'Failed to send friend request (status ${response.statusCode}).',
      );
    }
  }

  Future<List<FriendRequestItem>> listIncoming() async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for friend requests.');
    }

    final uri =
        Uri.parse('${AppEnv.apiBaseUrl}/friends/requests/incoming');
    final response = await _httpClient.get(
      uri,
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load incoming friend requests (status ${response.statusCode}).',
      );
    }

    final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;

    return body
        .map(
          (e) => FriendRequestItem(
            id: (e as Map<String, dynamic>)['id'] as String,
            username: (e['from'] as Map<String, dynamic>)['username'] as String,
            avatarUrl:
                (e['from'] as Map<String, dynamic>)['avatar_url'] as String?,
            direction: FriendRequestDirection.incoming,
          ),
        )
        .toList();
  }

  Future<List<FriendRequestItem>> listOutgoing() async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for friend requests.');
    }

    final uri =
        Uri.parse('${AppEnv.apiBaseUrl}/friends/requests/outgoing');
    final response = await _httpClient.get(
      uri,
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load outgoing friend requests (status ${response.statusCode}).',
      );
    }

    final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;

    return body
        .map(
          (e) => FriendRequestItem(
            id: (e as Map<String, dynamic>)['id'] as String,
            username: (e['to'] as Map<String, dynamic>)['username'] as String,
            avatarUrl:
                (e['to'] as Map<String, dynamic>)['avatar_url'] as String?,
            direction: FriendRequestDirection.outgoing,
          ),
        )
        .toList();
  }

  Future<void> acceptRequest(String id) async {
    await _patchRequest(id, 'accept');
  }

  Future<void> rejectRequest(String id) async {
    await _patchRequest(id, 'reject');
  }

  Future<void> cancelRequest(String id) async {
    await _patchRequest(id, 'cancel');
  }

  Future<void> _patchRequest(String id, String action) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for friend requests.');
    }

    final uri =
        Uri.parse('${AppEnv.apiBaseUrl}/friends/requests/$id/$action');
    final response = await _httpClient.patch(
      uri,
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to $action friend request (status ${response.statusCode}).',
      );
    }
  }
}


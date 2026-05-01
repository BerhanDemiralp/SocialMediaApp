import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.conversationId,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String? conversationId;
}

class GroupsApiClient {
  GroupsApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  Future<List<GroupSummary>> listMyGroups() async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth context available for groups.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/groups');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load groups (status ${response.statusCode}).',
      );
    }

    final List<dynamic> items =
        jsonDecode(response.body) as List<dynamic>? ?? <dynamic>[];

    return items
        .map((raw) => _mapSummaryFromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<GroupSummary> createGroup({required String name}) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth context available for groups.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/groups');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(
        'Failed to create group (status ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> map =
        jsonDecode(response.body) as Map<String, dynamic>;

    return _mapSummaryFromJson(map);
  }

  Future<GroupSummary> joinGroup({required String inviteCode}) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth context available for groups.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/groups/join');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inviteCode': inviteCode}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(
        'Failed to join group (status ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> map =
        jsonDecode(response.body) as Map<String, dynamic>;

    return _mapSummaryFromJson(map);
  }

  Future<void> leaveGroup({required String groupId}) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth context available for groups.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/groups/$groupId/leave');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Treat any 2xx as success, and also tolerate 404
    // (already not a member). Anything else is an error.
    final status = response.statusCode;
    final is2xx = status >= 200 && status < 300;
    if (!is2xx && status != 404) {
      throw StateError(
        'Failed to leave group (status $status).',
      );
    }
  }

  Future<List<GroupMemberSummary>> listGroupMembers(String groupId) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth context available for groups.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/groups/$groupId/members');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load group members (status ${response.statusCode}).',
      );
    }

    final List<dynamic> items =
        jsonDecode(response.body) as List<dynamic>? ?? <dynamic>[];

    return items
        .map(
          (raw) => GroupMemberSummary.fromJson(raw as Map<String, dynamic>),
        )
        .toList();
  }

  GroupSummary _mapSummaryFromJson(Map<String, dynamic> map) {
    return GroupSummary(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      inviteCode: map['invite_code'] as String? ?? '',
      conversationId: map['conversation_id'] as String?,
    );
  }
}

class GroupMemberSummary {
  const GroupMemberSummary({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.isSelf,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final bool isSelf;

  factory GroupMemberSummary.fromJson(Map<String, dynamic> map) {
    return GroupMemberSummary(
      id: map['id'] as String,
      username: map['username'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      isSelf: map['is_self'] as bool? ?? false,
    );
  }
}

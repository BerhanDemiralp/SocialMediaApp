import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';

class FriendConversationSummary {
  const FriendConversationSummary({
    this.friendId,
    required this.conversationId,
    this.matchId,
    required this.displayName,
    this.conversationType = 'friend',
    this.groupId,
    this.groupName,
    this.avatarUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.writable = true,
  });

  final String? friendId;
  final String conversationId;
  final String? matchId;
  final String displayName;
  final String conversationType;
  final String? groupId;
  final String? groupName;
  final String? avatarUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final bool writable;

  bool get isGroup => conversationType == 'group' || conversationType == 'group_pair';
  bool get isTemporary => conversationType == 'group_pair';
}

class FriendConversationsApiClient {
  FriendConversationsApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  Future<FriendConversationSummary> ensureFriendConversation({
    required String friendId,
  }) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;
    final currentUserId = session?.user.id;

    if (token == null || currentUserId == null) {
      throw StateError('No auth context available for conversations.');
    }

    final uri = Uri.parse('${AppEnv.apiBaseUrl}/conversations/friends');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'friendId': friendId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(
        'Failed to ensure friend conversation (status ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> map =
        jsonDecode(response.body) as Map<String, dynamic>;

    return _mapSummaryFromJson(map, currentUserId);
  }

  Future<List<FriendConversationSummary>> listFriendConversations({
    int limit = 50,
  }) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;
    final currentUserId = session?.user.id;

    if (token == null || currentUserId == null) {
      throw StateError('No auth context available for conversations.');
    }

    final uri = Uri.parse(
      '${AppEnv.apiBaseUrl}/conversations?limit=$limit',
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
        'Failed to load conversations (status ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> items = body['items'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map((raw) =>
            _mapSummaryFromJson(raw as Map<String, dynamic>, currentUserId))
        .toList();
  }

  FriendConversationSummary _mapSummaryFromJson(
    Map<String, dynamic> map,
    String currentUserId,
  ) {
    final participants =
        (map['participants'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>();

    Map<String, dynamic>? other;
    if (participants.isNotEmpty) {
      other = participants.firstWhere(
        (p) => p['id'] != currentUserId,
        orElse: () => participants.first,
      );
    }

    final lastMessage =
        map['lastMessage'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final createdAtRaw = lastMessage['created_at'] as String?;
    final createdAt =
        createdAtRaw != null ? DateTime.parse(createdAtRaw) : null;
    final conversationType = map['type'] as String? ?? 'friend';
    final groupName = map['groupName'] as String?;

    return FriendConversationSummary(
      friendId: conversationType == 'group'
          ? null
          : other != null
              ? other['id'] as String
              : currentUserId,
      conversationId: map['id'] as String,
      matchId: map['friendMatchId'] as String?,
      displayName: conversationType == 'group'
          ? groupName ?? map['title'] as String? ?? 'Group chat'
          : (other != null ? other['username'] : map['title']) as String? ??
              'Conversation',
      conversationType: conversationType,
      groupId: map['groupId'] as String?,
      groupName: groupName,
      avatarUrl: conversationType == 'group'
          ? null
          : other != null
              ? other['avatar_url'] as String?
              : null,
      lastMessagePreview: lastMessage['content'] as String?,
      lastMessageAt: createdAt,
      writable: map['writable'] as bool? ?? true,
    );
  }
}

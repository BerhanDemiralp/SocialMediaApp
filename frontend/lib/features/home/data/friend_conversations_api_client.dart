import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';

class FriendConversationSummary {
  const FriendConversationSummary({
    required this.conversationId,
    this.matchId,
    required this.displayName,
    this.avatarUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  final String conversationId;
  final String? matchId;
  final String displayName;
  final String? avatarUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
}

class FriendConversationsApiClient {
  FriendConversationsApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

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
      '${AppEnv.apiBaseUrl}/conversations?type=friend&limit=$limit',
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
        'Failed to load friend conversations (status ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> items = body['items'] as List<dynamic>? ?? <dynamic>[];

    return items.map((raw) {
      final map = raw as Map<String, dynamic>;

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

      return FriendConversationSummary(
        conversationId: map['id'] as String,
        matchId: map['friendMatchId'] as String?,
        displayName: (other != null ? other['username'] : map['title'])
                as String? ??
            'Conversation',
        avatarUrl: other != null ? other['avatar_url'] as String? : null,
        lastMessagePreview: lastMessage['content'] as String?,
        lastMessageAt: createdAt,
      );
    }).toList();
  }
}


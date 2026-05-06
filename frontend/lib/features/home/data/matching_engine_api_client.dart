import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';
import '../../../core/network/timing_http_client.dart';

final matchingEngineApiClientProvider =
    Provider<MatchingEngineApiClient>((ref) {
  final httpClient = TimingHttpClient();
  ref.onDispose(httpClient.close);
  return MatchingEngineApiClient(httpClient, Supabase.instance.client);
});

final activeMomentsProvider =
    FutureProvider.autoDispose<List<MomentSummary>>((ref) {
  return ref.watch(matchingEngineApiClientProvider).getCurrentMoments();
});

class MomentParticipantSummary {
  const MomentParticipantSummary({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;

  factory MomentParticipantSummary.fromJson(Map<String, dynamic> json) {
    return MomentParticipantSummary(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'Someone',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class MomentSummary {
  const MomentSummary({
    required this.id,
    required this.matchType,
    required this.status,
    required this.conversationId,
    required this.expiresAt,
    required this.participants,
    required this.writable,
  });

  final String id;
  final String matchType;
  final String status;
  final String conversationId;
  final DateTime expiresAt;
  final List<MomentParticipantSummary> participants;
  final bool writable;

  bool get isGroup => matchType == 'group';

  String otherParticipantName(String? currentUserId) {
    MomentParticipantSummary? other;
    for (final participant in participants) {
      if (participant.id != currentUserId) {
        other = participant;
        break;
      }
    }
    return other?.username ??
        (participants.isNotEmpty ? participants.first.username : 'Moment');
  }

  factory MomentSummary.fromJson(Map<String, dynamic> json) {
    final participants =
        (json['participants'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (item) => MomentParticipantSummary.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

    return MomentSummary(
      id: json['id'] as String,
      matchType: json['matchType'] as String? ?? 'friend',
      status: json['status'] as String? ?? 'active',
      conversationId: json['conversation_id'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      participants: participants,
      writable: json['writable'] as bool? ?? true,
    );
  }
}

class MatchingEngineApiClient {
  MatchingEngineApiClient(this._httpClient, this._supabaseClient);

  final http.Client _httpClient;
  final SupabaseClient _supabaseClient;

  String? get currentUserId => _supabaseClient.auth.currentUser?.id;

  Future<List<MomentSummary>> getCurrentMoments() async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for Moment requests.');
    }

    final response = await _httpClient.get(
      Uri.parse('${AppEnv.apiBaseUrl}/matching-engine/me/current'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load active Moments (status ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    final items = decoded is List
        ? decoded
        : (decoded as Map<String, dynamic>)['items'] as List<dynamic>? ??
            <dynamic>[];

    return items
        .map((item) => MomentSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> optInToGroupMoment(String matchId) async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw StateError('No auth token available for Moment requests.');
    }

    final response = await _httpClient.post(
      Uri.parse('${AppEnv.apiBaseUrl}/matching-engine/$matchId/opt-in'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(
        'Failed to opt in to Moment (status ${response.statusCode}).',
      );
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:moment_app/features/chat/presentation/chat_controller.dart';
import 'package:moment_app/features/home/data/matching_engine_api_client.dart';

void main() {
  test('MomentSummary parses active group Moment data', () {
    final moment = MomentSummary.fromJson({
      'id': 'moment-1',
      'matchType': 'group',
      'status': 'active',
      'user_a_id': 'user-1',
      'user_b_id': 'user-2',
      'user_a_friend_consent': null,
      'user_b_friend_consent': true,
      'conversation_id': 'conv-1',
      'scheduled_at': '2026-05-05T17:00:00.000Z',
      'expires_at': '2026-05-05T18:00:00.000Z',
      'writable': true,
      'participants': [
        {'id': 'user-1', 'username': 'alice', 'avatar_url': null},
        {'id': 'user-2', 'username': 'ben', 'avatar_url': 'avatar.png'},
      ],
    });

    expect(moment.isGroup, isTrue);
    expect(moment.conversationId, 'conv-1');
    expect(moment.scheduledAt.isUtc, isFalse);
    expect(moment.otherParticipantName('user-1'), 'ben');
    expect(moment.writable, isTrue);
    expect(moment.hasPendingFriendConsentFor('user-1'), isFalse);
  });

  test('MomentSummary detects pending group friendship consent', () {
    final moment = MomentSummary.fromJson({
      'id': 'moment-1',
      'matchType': 'group',
      'status': 'successful',
      'user_a_id': 'user-1',
      'user_b_id': 'user-2',
      'user_a_friend_consent': true,
      'user_b_friend_consent': null,
      'conversation_id': 'conv-1',
      'scheduled_at': '2026-05-05T17:00:00.000Z',
      'expires_at': '2026-05-05T18:00:00.000Z',
      'writable': true,
      'participants': [
        {'id': 'user-1', 'username': 'alice', 'avatar_url': null},
        {'id': 'user-2', 'username': 'ben', 'avatar_url': null},
      ],
    });

    expect(moment.hasPendingFriendConsentFor('user-1'), isFalse);
    expect(moment.hasPendingFriendConsentFor('user-2'), isTrue);
  });

  test('ChatState carries writable state for read-only Moment history', () {
    final state = ChatState.initial().copyWith(
      isLoading: false,
      writable: false,
    );

    expect(state.isLoading, isFalse);
    expect(state.writable, isFalse);
  });
}

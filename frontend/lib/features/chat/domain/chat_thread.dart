import 'chat_participant.dart';

enum ChatMatchType { friends, groups }

enum ChatStatus { active, expired, successful }

class ChatThread {
  final String id;
  final ChatMatchType matchType;
  final ChatStatus status;
  final ChatParticipant otherParticipant;

  const ChatThread({
    required this.id,
    required this.matchType,
    required this.status,
    required this.otherParticipant,
  });
}

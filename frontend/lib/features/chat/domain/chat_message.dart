class ChatMessage {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}


class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderUsername;
  final String? senderAvatarUrl;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderUsername,
    this.senderAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderUsername: (json['sender'] as Map<String, dynamic>?)?['username']
          as String?,
      senderAvatarUrl: (json['sender'] as Map<String, dynamic>?)?['avatar_url']
          as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

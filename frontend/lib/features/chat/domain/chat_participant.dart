class ChatParticipant {
  final String id;
  final String? username;
  final String? avatarUrl;

  const ChatParticipant({
    required this.id,
    this.username,
    this.avatarUrl,
  });
}


class UserIdentity {
  const UserIdentity({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;
}

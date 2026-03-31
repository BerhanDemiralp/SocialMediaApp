import 'package:flutter/material.dart';

/// Pure UI user card used across the app.
/// It does not know about repositories or providers.
/// All behavior is injected via callbacks.
class UserActionTile extends StatelessWidget {
  const UserActionTile({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.isSelf = false,
    required this.isFriend,
    required this.hasIncomingRequest,
    required this.hasOutgoingRequest,
    this.onAddFriend,
    this.onRemoveFriend,
    this.onOpenChat,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isSelf;
  final bool isFriend;
  final bool hasIncomingRequest;
  final bool hasOutgoingRequest;
  final VoidCallback? onAddFriend;
  final VoidCallback? onRemoveFriend;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    Widget trailing;

    if (isSelf) {
      trailing = const SizedBox.shrink();
    } else if (isFriend) {
      trailing = FilledButton.icon(
        onPressed: onRemoveFriend,
        icon: const Icon(Icons.person_remove),
        label: const Text('Remove friend'),
      );
    } else if (hasOutgoingRequest) {
      trailing = FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_empty, size: 18),
        label: const Text('Requested'),
      );
    } else if (hasIncomingRequest) {
      trailing = FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.mail_outline, size: 18),
        label: const Text('Requested you'),
      );
    } else {
      trailing = FilledButton.icon(
        onPressed: onAddFriend,
        icon: const Icon(Icons.person_add),
        label: const Text('Add friend'),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        child: avatarUrl == null
            ? Text(
                username.isNotEmpty
                    ? username[0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Text(isSelf ? '$username (You)' : username),
      trailing: trailing,
      onTap: () async {
        if (!isFriend || onOpenChat == null || isSelf) return;
        onOpenChat!();
      },
    );
  }
}

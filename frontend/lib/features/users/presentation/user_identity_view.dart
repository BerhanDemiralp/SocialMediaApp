import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_session.dart';
import '../domain/user_identity.dart';
import 'app_avatar.dart';
import 'user_relationships_controller.dart';

/// Explicit profile edits take precedence over older API list snapshots.
final userIdentityOverridesProvider = StateProvider<Map<String, UserIdentity>>((
  ref,
) {
  ref.watch(activeAccountIdProvider);
  return {};
});

enum UserIdentityLayout { avatar, compact, header }

UserIdentity _resolvedIdentity(WidgetRef ref, UserIdentity user) {
  final override = ref.watch(
    userIdentityOverridesProvider.select((users) => users[user.id]),
  );
  final known = ref.watch(
    userRelationshipsProvider.select((state) => state.records[user.id]?.user),
  );
  return override ??
      (known == null
          ? user
          : UserIdentity(
              id: user.id,
              username: known.username.isEmpty ? user.username : known.username,
              avatarUrl: known.avatarUrl ?? user.avatarUrl,
            ));
}

class UserName extends ConsumerWidget {
  const UserName({super.key, required this.user, this.style});
  final UserIdentity user;
  final TextStyle? style;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Text(
    _resolvedIdentity(ref, user).username,
    style: style,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}

class UserIdentityView extends ConsumerWidget {
  const UserIdentityView({
    super.key,
    required this.user,
    this.layout = UserIdentityLayout.compact,
    this.radius,
    this.isSelf = false,
    this.onTap,
    this.subtitle,
  });
  final UserIdentity user;
  final UserIdentityLayout layout;
  final double? radius;
  final bool isSelf;
  final VoidCallback? onTap;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = _resolvedIdentity(ref, user);
    final avatar = AppAvatar(
      username: identity.username,
      avatarUrl: identity.avatarUrl,
      radius: radius ?? (layout == UserIdentityLayout.header ? 40 : 20),
    );
    final name = Text(
      isSelf ? '${identity.username} (You)' : identity.username,
      maxLines: layout == UserIdentityLayout.header ? null : 2,
      overflow: layout == UserIdentityLayout.header
          ? null
          : TextOverflow.ellipsis,
      style: layout == UserIdentityLayout.header
          ? Theme.of(context).textTheme.titleLarge
          : null,
    );
    final Widget content = switch (layout) {
      UserIdentityLayout.avatar => Semantics(
        label: identity.username,
        image: true,
        child: avatar,
      ),
      UserIdentityLayout.header => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(height: 10),
          name,
          if (subtitle != null) subtitle!,
        ],
      ),
      UserIdentityLayout.compact => Row(
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [name, if (subtitle != null) subtitle!],
            ),
          ),
        ],
      ),
    };
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: 'Message ${identity.username}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: content,
        ),
      ),
    );
  }
}

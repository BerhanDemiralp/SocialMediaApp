import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../users/data/friend_conversations_api_client.dart';
import '../../users/data/user_identity_adapters.dart';
import '../../users/data/user_session.dart';
import '../../users/domain/user_relationship.dart';
import '../../users/presentation/user_card.dart';
import '../../users/presentation/user_conversations.dart';
import '../../users/presentation/user_identity_view.dart';
import '../../users/presentation/user_relationships_controller.dart';

final _messagesSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

class HomeMessagesScreen extends ConsumerWidget {
  const HomeMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_messagesSearchQueryProvider).trim().toLowerCase();
    final conversations = ref.watch(userConversationsProvider);
    final relationships = ref.watch(userRelationshipsProvider);
    final currentUserId = ref.watch(activeAccountIdProvider);
    // A dependency reload can mean a different account. Never render its
    // predecessor's retained AsyncValue while the new request is pending.
    final items = conversations.isReloading
        ? const <FriendConversationSummary>[]
        : conversations.valueOrNull ?? const <FriendConversationSummary>[];
    final existingFriends = {
      for (final c in items)
        if (!c.isGroup && c.friendId != null) c.friendId!,
    };
    final friends = relationships
        .usersOfKind(RelationshipKind.friend)
        .where(
          (u) =>
              !existingFriends.contains(u.id) &&
              u.username.toLowerCase().contains(query),
        )
        .toList();
    final filtered = items
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(query) ||
              (c.lastMessagePreview ?? '').toLowerCase().contains(query),
        )
        .toList();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppTextField(
              decoration: const InputDecoration(
                hintText: 'Search conversations or friends',
                prefixIcon: Icon(Icons.search),
              ),
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) =>
                  ref.read(_messagesSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userConversationsProvider);
                await ref.read(userRelationshipsProvider.notifier).refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                children: [
                  if ((conversations.isLoading &&
                          (!conversations.hasValue ||
                              conversations.isReloading)) ||
                      (relationships.loading && !relationships.loaded))
                    const LinearProgressIndicator(),
                  if (conversations.hasError)
                    ListTile(
                      title: const Text('Could not load conversations.'),
                      trailing: TextButton(
                        onPressed: () =>
                            ref.invalidate(userConversationsProvider),
                        child: const Text('Retry'),
                      ),
                    ),
                  if (relationships.error != null)
                    ListTile(
                      title: Text(relationships.error!),
                      trailing: TextButton(
                        onPressed: ref
                            .read(userRelationshipsProvider.notifier)
                            .refresh,
                        child: const Text('Retry'),
                      ),
                    ),
                  if (!conversations.isLoading &&
                      !relationships.loading &&
                      !conversations.hasError &&
                      filtered.isEmpty &&
                      friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No conversations match your search.'),
                    ),
                  for (final conversation in filtered)
                    _ConversationRow(
                      conversation: conversation,
                      currentUserId: currentUserId,
                    ),
                  for (final user in friends)
                    UserCard(key: ValueKey(user.id), user: user),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends ConsumerWidget {
  const _ConversationRow({required this.conversation, this.currentUserId});
  final FriendConversationSummary conversation;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = conversation;
    final group = c.conversationType == 'group';
    final preview = c.lastMessagePreview;
    final text = !c.writable
        ? 'Read-only history'
        : preview == null || preview.isEmpty
        ? 'No messages yet.'
        : currentUserId != null && c.lastMessageSenderId == currentUserId
        ? 'You: $preview'
        : c.isGroup
        ? '${c.lastMessageSenderUsername ?? 'Someone'}: $preview'
        : preview;
    final subtitle = Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    return InkWell(
      onTap: () => ref
          .read(userConversationCoordinatorProvider.notifier)
          .open(
            context,
            user: c.identity,
            conversationId: c.conversationId,
            isGroup: c.isGroup,
            isTemporary: c.isTemporary,
            title: c.displayName,
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: group
                  ? Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: const Icon(Icons.groups),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle,
                            ],
                          ),
                        ),
                        const Icon(Icons.tag, size: 16),
                      ],
                    )
                  : UserIdentityView(user: c.identity, subtitle: subtitle),
            ),
            if (c.lastMessageAt != null) ...[
              const SizedBox(width: 12),
              Flexible(
                flex: 0,
                child: Text(
                  _formatTime(c.lastMessageAt!),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(time.year, time.month, time.day)).inDays;
    if (diff == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (diff == 1) return 'Yesterday';
    return '${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}.${time.year}';
  }
}

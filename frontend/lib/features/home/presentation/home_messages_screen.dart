import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/network/timing_http_client.dart';
import '../data/friend_conversations_api_client.dart';
import '../data/friends_api_client.dart';
import '../data/home_messaging_repository.dart';
import 'app_avatar.dart';

final _messagesSearchQueryProvider = StateProvider<String>((ref) => '');

final friendConversationsProvider =
    FutureProvider.autoDispose<List<FriendConversationSummary>>((ref) {
      final repo = ref.watch(homeMessagingRepositoryProvider);
      return repo.loadFriendConversations();
    });

final messagesFriendsProvider = FutureProvider.autoDispose<List<FriendSummary>>(
  (ref) async {
    final supabaseClient = Supabase.instance.client;
    final httpClient = TimingHttpClient();
    final apiClient = FriendsApiClient(httpClient, supabaseClient);

    ref.onDispose(httpClient.close);

    return apiClient.listFriends();
  },
);

class HomeMessagesScreen extends ConsumerWidget {
  const HomeMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(_messagesSearchQueryProvider);
    final conversationsAsync = ref.watch(friendConversationsProvider);
    final friendsAsync = ref.watch(messagesFriendsProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search conversations or friends',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
              onChanged: (value) {
                ref.read(_messagesSearchQueryProvider.notifier).state = value;
                final analytics = ref.read(appAnalyticsProvider);
                analytics.trackEvent('messages_search_changed', {
                  'query_length': value.length,
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(friendConversationsProvider);
                ref.invalidate(messagesFriendsProvider);
              },
              child: friendsAsync.when(
                data: (friends) {
                  final conversations = conversationsAsync.maybeWhen(
                    data: (items) => items,
                    orElse: () => const <FriendConversationSummary>[],
                  );

                  final convoByFriendId = {
                    for (final c in conversations)
                      if (!c.isGroup && c.friendId != null) c.friendId!: c,
                  };
                  final normalizedQuery = searchQuery.trim().toLowerCase();

                  final filteredConversations = normalizedQuery.isEmpty
                      ? conversations
                      : conversations
                            .where(
                              (c) =>
                                  c.displayName.toLowerCase().contains(
                                    normalizedQuery,
                                  ) ||
                                  (c.lastMessagePreview ?? '')
                                      .toLowerCase()
                                      .contains(normalizedQuery),
                            )
                            .toList();

                  final filteredFriends = friends
                      .where(
                        (friend) => !convoByFriendId.containsKey(friend.id),
                      )
                      .where(
                        (friend) =>
                            normalizedQuery.isEmpty ||
                            friend.username.toLowerCase().contains(
                              normalizedQuery,
                            ),
                      )
                      .toList();

                  if (filteredConversations.isEmpty &&
                      filteredFriends.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        SizedBox(height: 24),
                        Text('No conversations match your search.'),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount:
                        filteredConversations.length + filteredFriends.length,
                    itemBuilder: (context, index) {
                      if (index < filteredConversations.length) {
                        final convo = filteredConversations[index];
                        final analytics = ref.read(appAnalyticsProvider);

                        return _ConversationListTile(
                          conversation: convo,
                          currentUserId: currentUserId,
                          formattedTime: convo.lastMessageAt != null
                              ? _formatTime(convo.lastMessageAt!)
                              : null,
                          onTap: () async {
                            analytics.trackEvent(
                              convo.isGroup
                                  ? 'group_conversation_opened'
                                  : 'friend_conversation_opened',
                              {'conversation_id': convo.conversationId},
                            );

                            final route = convo.isGroup
                                ? Uri(
                                    path:
                                        '/conversation/${convo.conversationId}',
                                    queryParameters: {
                                      'type': 'group',
                                      'title': convo.displayName,
                                      if (convo.isTemporary) 'temporary': '1',
                                    },
                                  ).toString()
                                : '/conversation/${convo.conversationId}';

                            await context.push(route);
                            ref.invalidate(friendConversationsProvider);
                          },
                        );
                      }

                      final friend =
                          filteredFriends[index - filteredConversations.length];
                      final analytics = ref.read(appAnalyticsProvider);

                      return ListTile(
                        leading: AppAvatar(
                          username: friend.username,
                          avatarUrl: friend.avatarUrl,
                        ),
                        title: Text(friend.username),
                        subtitle: const Text('No messages yet.'),
                        onTap: () async {
                          final repo = ref.read(
                            homeMessagingRepositoryProvider,
                          );

                          try {
                            // If we already have a conversation for this friend, reuse it
                            // to allow opening historical chats even if friendship has changed.
                            final conversationId =
                                (await repo.ensureFriendConversation(
                                  friend.id,
                                )).conversationId;

                            analytics.trackEvent('friend_conversation_opened', {
                              'conversation_id': conversationId,
                            });

                            ref.invalidate(friendConversationsProvider);

                            if (!context.mounted) return;

                            // Wait for the conversation screen to be popped,
                            // then refresh summaries so the last message preview
                            // is up to date when returning to the Messages tab.
                            await context.push('/conversation/$conversationId');
                            ref.invalidate(friendConversationsProvider);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not open conversation with friend.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    SizedBox(height: 24),
                    Text('Error loading friends. Pull to retry.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final messageDate = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    final dayDiff = today.difference(messageDate).inDays;

    if (dayDiff == 0) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minutes = time.minute.toString().padLeft(2, '0');
      return '$hour:$minutes';
    }

    if (dayDiff == 1) {
      return 'Yesterday';
    }

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day.$month.${time.year}';
  }
}

class _ConversationListTile extends StatelessWidget {
  const _ConversationListTile({
    required this.conversation,
    required this.onTap,
    this.currentUserId,
    this.formattedTime,
  });

  final FriendConversationSummary conversation;
  final VoidCallback onTap;
  final String? currentUserId;
  final String? formattedTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = conversation.isGroup;
    final lastMessageText = _formatLastMessagePreview(conversation);

    return ListTile(
      leading: isGroup
          ? CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              child: const Icon(Icons.groups),
            )
          : AppAvatar(
              username: conversation.displayName,
              avatarUrl: conversation.avatarUrl,
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isGroup) ...[
            const SizedBox(width: 8),
            Icon(Icons.tag, size: 16, color: theme.colorScheme.secondary),
          ],
        ],
      ),
      subtitle: Text(
        conversation.writable ? lastMessageText : 'Read-only history',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: formattedTime != null
          ? Text(formattedTime!, style: theme.textTheme.bodySmall)
          : null,
      onTap: onTap,
    );
  }

  String _formatLastMessagePreview(FriendConversationSummary conversation) {
    final message = conversation.lastMessagePreview;

    if (message == null || message.isEmpty) {
      return 'No messages yet.';
    }

    if (conversation.lastMessageSenderId == currentUserId) {
      return 'You: $message';
    }

    if (conversation.isGroup) {
      final username = conversation.lastMessageSenderUsername ?? 'Someone';
      return '$username: $message';
    }

    return message;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics/app_analytics.dart';
import '../data/friend_conversations_api_client.dart';
import '../data/friends_api_client.dart';
import '../data/home_messaging_repository.dart';

final _messagesSearchQueryProvider = StateProvider<String>((ref) => '');

final friendConversationsProvider =
    FutureProvider.autoDispose<List<FriendConversationSummary>>((ref) {
  final repo = ref.watch(homeMessagingRepositoryProvider);
  return repo.loadFriendConversations();
});

final messagesFriendsProvider =
    FutureProvider.autoDispose<List<FriendSummary>>((ref) async {
  final supabaseClient = Supabase.instance.client;
  final httpClient = http.Client();
  final apiClient = FriendsApiClient(httpClient, supabaseClient);

  ref.onDispose(httpClient.close);

  return apiClient.listFriends();
});

class HomeMessagesScreen extends ConsumerWidget {
  const HomeMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(_messagesSearchQueryProvider);
    final conversationsAsync = ref.watch(friendConversationsProvider);
    final friendsAsync = ref.watch(messagesFriendsProvider);

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
                  if (friends.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        SizedBox(height: 24),
                        Text('You have no friends yet.'),
                      ],
                    );
                  }

                  final conversations = conversationsAsync.maybeWhen(
                    data: (items) => items,
                    orElse: () => const <FriendConversationSummary>[],
                  );

                  final convoByFriendId = {
                    for (final c in conversations) c.friendId: c,
                  };

                  final filteredFriends = searchQuery.trim().isEmpty
                      ? friends
                      : friends
                          .where(
                            (f) => f.username
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase()),
                          )
                          .toList();

                  if (filteredFriends.isEmpty) {
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
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
                      final convo = convoByFriendId[friend.id];
                      final analytics = ref.read(appAnalyticsProvider);

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            friend.username.isNotEmpty
                                ? friend.username[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(friend.username),
                        subtitle: Text(
                          convo?.lastMessagePreview ?? 'No messages yet.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: convo?.lastMessageAt != null
                            ? Text(
                                _formatTime(convo!.lastMessageAt!),
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            : null,
                        onTap: () async {
                          final repo =
                              ref.read(homeMessagingRepositoryProvider);

                          try {
                            // If we already have a conversation for this friend, reuse it
                            // to allow opening historical chats even if friendship has changed.
                            final conversationId = convo != null
                                ? convo.conversationId
                                : (await repo.ensureFriendConversation(
                                        friend.id))
                                    .conversationId;

                            analytics.trackEvent('friend_conversation_opened', {
                              'conversation_id': conversationId,
                            });

                            // Refresh cached conversations list when we had to ensure it.
                            if (convo == null) {
                              ref.invalidate(friendConversationsProvider);
                            }

                            if (context.mounted) {
                              context.push('/conversation/$conversationId');
                            }
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
    if (now.difference(time).inDays >= 1) {
      final date = DateTime(time.year, time.month, time.day);
      final today = DateTime(now.year, now.month, now.day);
      if (date == today) {
        final minutes = time.minute.toString().padLeft(2, '0');
        return '${time.hour}:$minutes';
      }
      return '${time.month}/${time.day}';
    }
    final minutes = time.minute.toString().padLeft(2, '0');
    return '${time.hour}:$minutes';
  }
}

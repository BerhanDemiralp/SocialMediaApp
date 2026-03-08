import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/app_analytics.dart';
import '../data/friend_conversations_api_client.dart';
import '../data/home_messaging_repository.dart';

final friendConversationsProvider =
    FutureProvider.autoDispose<List<FriendConversationSummary>>((ref) {
  final repo = ref.watch(homeMessagingRepositoryProvider);
  return repo.loadFriendConversations();
});

class HomeMessagesScreen extends ConsumerWidget {
  const HomeMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(friendConversationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(friendConversationsProvider);
      },
      child: conversationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 24),
                Text(
                  'No conversations yet.\nStart by messaging a friend from the Home tab.',
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final convo = items[index];
              final analytics = ref.read(appAnalyticsProvider);

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    convo.displayName.isNotEmpty
                        ? convo.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(convo.displayName),
                subtitle: Text(
                  convo.lastMessagePreview ?? 'No messages yet.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: convo.lastMessageAt != null
                    ? Text(
                        _formatTime(convo.lastMessageAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
                onTap: () {
                  analytics.trackEvent('friend_conversation_opened', {
                    'conversation_id': convo.conversationId,
                    'match_id': convo.matchId,
                  });

                  if (convo.matchId != null) {
                    context.push('/chat/${convo.matchId}');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'This conversation cannot be opened yet.',
                        ),
                      ),
                    );
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
            Text('Error loading conversations. Pull to retry.'),
          ],
        ),
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


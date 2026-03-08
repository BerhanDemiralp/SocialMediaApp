import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/home_friends_repository.dart';
import '../data/friend_requests_api_client.dart';
import '../data/friends_api_client.dart';
import '../data/user_search_api_client.dart';
import '../data/home_messaging_repository.dart';
import 'home_messages_screen.dart';
import '../../../core/analytics/app_analytics.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<UserSummary>>((ref) async {
  final query = ref.watch(_searchQueryProvider);
  if (query.trim().isEmpty) {
    return [];
  }
  final repo = ref.watch(homeFriendsRepositoryProvider);
  return repo.searchUsers(query);
});

final incomingRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequestItem>>((ref) {
  final repo = ref.watch(homeFriendsRepositoryProvider);
  return repo.loadIncomingRequests();
});

final outgoingRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequestItem>>((ref) {
  final repo = ref.watch(homeFriendsRepositoryProvider);
  return repo.loadOutgoingRequests();
});

final friendsProvider =
    FutureProvider.autoDispose<List<FriendSummary>>((ref) {
  final repo = ref.watch(homeFriendsRepositoryProvider);
  return repo.loadFriends();
});

class HomeFriendsScreen extends ConsumerWidget {
  const HomeFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(_searchQueryProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);
    final friendsAsync = ref.watch(friendsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomingRequestsProvider);
        ref.invalidate(outgoingRequestsProvider);
        ref.invalidate(friendsProvider);
        if (searchQuery.trim().isNotEmpty) {
          ref.invalidate(searchResultsProvider);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by username',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              ref.read(_searchQueryProvider.notifier).state = value;
              final analytics = ref.read(appAnalyticsProvider);
              analytics.trackEvent('home_search_changed', {
                'query_length': value.length,
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Search results',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          searchAsync.when(
            data: (results) {
              if (searchQuery.trim().isEmpty) {
                return const Text('Start typing to search for friends.');
              }
              if (results.isEmpty) {
                return const Text('No users found for this query.');
              }

              final hasRelationshipData = friendsAsync.hasValue &&
                  incomingAsync.hasValue &&
                  outgoingAsync.hasValue;

              final friends = hasRelationshipData
                  ? friendsAsync.requireValue
                  : const <FriendSummary>[];
              final incoming = hasRelationshipData
                  ? incomingAsync.requireValue
                  : const <FriendRequestItem>[];
              final outgoing = hasRelationshipData
                  ? outgoingAsync.requireValue
                  : const <FriendRequestItem>[];

              final friendIds = friends.map((f) => f.id).toSet();
              final incomingUserIds =
                  incoming.map((r) => r.userId).toSet();
              final outgoingUserIds =
                  outgoing.map((r) => r.userId).toSet();

              return Column(
                children: results
                    .map(
                      (u) {
                        final isFriend = friendIds.contains(u.id);
                        final hasOutgoingRequest =
                            outgoingUserIds.contains(u.id);
                        final hasIncomingRequest =
                            incomingUserIds.contains(u.id);

                        Widget trailing;

                        if (!hasRelationshipData) {
                          trailing = const SizedBox.shrink();
                        } else if (isFriend) {
                          trailing = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Friends',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_remove),
                                tooltip: 'Remove friend',
                                onPressed: () async {
                                  final repo = ref.read(
                                      homeFriendsRepositoryProvider);
                                  final analytics =
                                      ref.read(appAnalyticsProvider);
                                  try {
                                    await repo.removeFriend(u.id);
                                    analytics.trackEvent('friend_removed', {
                                      'friend_id': u.id,
                                    });
                                    ref.invalidate(friendsProvider);
                                    ref.invalidate(searchResultsProvider);
                                    // Also refresh Messages tab after unfriend.
                                    ref.invalidate(messagesFriendsProvider);
                                    ref.invalidate(friendConversationsProvider);
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not remove friend.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          );
                        } else if (hasOutgoingRequest) {
                          trailing = const Text(
                            'Requested',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          );
                        } else if (hasIncomingRequest) {
                          trailing = const Text(
                            'Requested you',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          );
                        } else {
                          trailing = IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: () async {
                              final repo =
                                  ref.read(homeFriendsRepositoryProvider);
                              final analytics =
                                  ref.read(appAnalyticsProvider);
                              try {
                                await repo.sendFriendRequest(u.id);
                                analytics.trackEvent('friend_request_sent', {
                                  'target_user_id': u.id,
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Friend request sent to ${u.username}',
                                      ),
                                    ),
                                  );
                                }
                                ref.invalidate(outgoingRequestsProvider);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not send friend request.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            child: u.avatarUrl == null
                                ? Text(
                                    u.username.isNotEmpty
                                        ? u.username[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          title: Text(u.username),
                          trailing: trailing,
                          onTap: () async {
                            // Only allow direct chat from search when the user is already a friend.
                            if (!isFriend) return;

                            final repo =
                                ref.read(homeMessagingRepositoryProvider);
                            final analytics =
                                ref.read(appAnalyticsProvider);

                            try {
                              final ensured =
                                  await repo.ensureFriendConversation(u.id);

                              analytics.trackEvent(
                                'friend_conversation_opened_from_search',
                                {
                                  'conversation_id': ensured.conversationId,
                                },
                              );

                              // Refresh messages summaries so the chat list stays up to date.
                              ref.invalidate(friendConversationsProvider);

                              if (context.mounted) {
                                // Navigate directly to the conversation chat.
                                // Uses the same route as Messages tab.
                                // Requires go_router setup in app_router.dart.
                                // ignore: use_build_context_synchronously
                                context.push(
                                  '/conversation/${ensured.conversationId}',
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open conversation with user.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const Text('Error loading search results.'),
          ),
          const SizedBox(height: 24),
          Text(
            'Incoming requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          incomingAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No incoming requests.');
              }
              return Column(
                children: items
                    .map(
                      (r) => ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            r.username.isNotEmpty
                                ? r.username[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(r.username),
                        subtitle: const Text('Incoming request'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                final repo =
                                    ref.read(homeFriendsRepositoryProvider);
                                final analytics =
                                    ref.read(appAnalyticsProvider);
                                try {
                                  await repo.acceptRequest(r.id);
                                  analytics.trackEvent(
                                    'friend_request_accepted',
                                    {'request_id': r.id},
                                  );
                                  ref.invalidate(incomingRequestsProvider);
                                  ref.invalidate(friendsProvider);
                                  // Keep Messages tab in sync with new friendships.
                                  ref.invalidate(messagesFriendsProvider);
                                  ref.invalidate(friendConversationsProvider);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Could not accept request.'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () async {
                                final repo =
                                    ref.read(homeFriendsRepositoryProvider);
                                final analytics =
                                    ref.read(appAnalyticsProvider);
                                try {
                              await repo.rejectRequest(r.id);
                              analytics.trackEvent(
                                'friend_request_rejected',
                                {'request_id': r.id},
                              );
                              ref.invalidate(incomingRequestsProvider);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Could not reject request.'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const Text('Error loading incoming requests.'),
          ),
          const SizedBox(height: 24),
          Text(
            'Outgoing requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          outgoingAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No outgoing requests.');
              }
              return Column(
                children: items
                    .map(
                      (r) => ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            r.username.isNotEmpty
                                ? r.username[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(r.username),
                        subtitle: const Text('Outgoing request'),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () async {
                            final repo =
                                ref.read(homeFriendsRepositoryProvider);
                            final analytics =
                                ref.read(appAnalyticsProvider);
                            try {
                              await repo.cancelRequest(r.id);
                              analytics.trackEvent(
                                'friend_request_canceled',
                                {'request_id': r.id},
                              );
                              ref.invalidate(outgoingRequestsProvider);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Could not cancel request.'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const Text('Error loading outgoing requests.'),
          ),
        ],
      ),
    );
  }
}

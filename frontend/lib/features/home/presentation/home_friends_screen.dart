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

final _searchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Tracks which user id is currently opening a chat from search
/// so multiple rapid taps don't push multiple chat routes.
final _openingChatForUserIdProvider = StateProvider<String?>((ref) => null);

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
    final theme = Theme.of(context);
    final searchQuery = ref.watch(_searchQueryProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find friends'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(incomingRequestsProvider);
          ref.invalidate(outgoingRequestsProvider);
          ref.invalidate(friendsProvider);
          if (searchQuery.trim().isNotEmpty) {
            ref.invalidate(searchResultsProvider);
          }
        },
        child: Material(
          color: Colors.transparent,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Type a friend\'s username',
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

              // Search results – only visible while there is a query.
              if (searchQuery.trim().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: searchAsync.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return const Text(
                            'No users found for this username.',
                          );
                        }

                        final hasRelationshipData =
                            friendsAsync.hasValue &&
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

                        // Sort search results by action/button state:
                        // 0 = can add friend, 1 = can remove friend,
                        // 2 = pending (requested / requested you), 3 = unknown.
                        int sortKey(UserSummary u) {
                          final isFriend = friendIds.contains(u.id);
                          final hasOutgoingRequest =
                              outgoingUserIds.contains(u.id);
                          final hasIncomingRequest =
                              incomingUserIds.contains(u.id);
                          if (!hasRelationshipData) return 3;
                          if (!isFriend &&
                              !hasOutgoingRequest &&
                              !hasIncomingRequest) {
                            // Can add friend
                            return 0;
                          }
                          if (isFriend) {
                            // Can remove friend
                            return 1;
                          }
                          if (hasOutgoingRequest || hasIncomingRequest) {
                            // Pending state
                            return 2;
                          }
                          return 3;
                        }

                        final sorted = [...results]
                          ..sort((a, b) => sortKey(a).compareTo(sortKey(b)));

                        return Column(
                          children: sorted.map((u) {
                            final isFriend = friendIds.contains(u.id);
                            final hasOutgoingRequest =
                                outgoingUserIds.contains(u.id);
                            final hasIncomingRequest =
                                incomingUserIds.contains(u.id);

                            Widget trailing;

                            if (!hasRelationshipData) {
                              trailing = const SizedBox.shrink();
                            } else if (isFriend) {
                              trailing = FilledButton.icon(
                                onPressed: () async {
                                  final repo = ref.read(
                                    homeFriendsRepositoryProvider,
                                  );
                                  final analytics = ref.read(
                                    appAnalyticsProvider,
                                  );
                                  try {
                                    await repo.removeFriend(u.id);
                                    analytics.trackEvent(
                                      'friend_removed',
                                      {'friend_id': u.id},
                                    );
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
                                icon: const Icon(Icons.person_remove),
                                label: const Text('Remove friend'),
                              );
                            } else if (hasOutgoingRequest) {
                              trailing = FilledButton.tonalIcon(
                                onPressed: null,
                                icon: const Icon(
                                  Icons.hourglass_empty,
                                  size: 18,
                                ),
                                label: const Text('Requested'),
                              );
                            } else if (hasIncomingRequest) {
                              trailing = FilledButton.tonalIcon(
                                onPressed: null,
                                icon: const Icon(
                                  Icons.mail_outline,
                                  size: 18,
                                ),
                                label: const Text('Requested you'),
                              );
                            } else {
                              // Default: add-friend button with icon + label
                              trailing = FilledButton.icon(
                                onPressed: () async {
                                  final repo = ref.read(
                                    homeFriendsRepositoryProvider,
                                  );
                                  final analytics = ref.read(
                                    appAnalyticsProvider,
                                  );
                                  try {
                                    await repo.sendFriendRequest(u.id);
                                    analytics.trackEvent(
                                      'friend_request_sent',
                                      {'target_user_id': u.id},
                                    );
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
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add friend'),
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

                                final openingUserId =
                                    ref.read(_openingChatForUserIdProvider);
                                // If we're already opening a chat for this user, ignore extra taps.
                                if (openingUserId == u.id) return;

                                final openingNotifier = ref.read(
                                  _openingChatForUserIdProvider.notifier,
                                );
                                openingNotifier.state = u.id;

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
                                } finally {
                                  openingNotifier.state = null;
                                }
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, __) =>
                          const Text('Error loading search results.'),
                    ),
                  ),
                ),

              // Incoming requests – only when not searching.
              if (searchQuery.trim().isEmpty)
                incomingAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      // No incoming requests section when there are none.
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Incoming requests',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Column(
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
                                          subtitle: const Text(
                                            'Incoming request',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              FilledButton.icon(
                                                icon: const Icon(Icons.check),
                                                label: const Text('Accept'),
                                                onPressed: () async {
                                                  final repo = ref.read(
                                                    homeFriendsRepositoryProvider,
                                                  );
                                                  final analytics = ref.read(
                                                    appAnalyticsProvider,
                                                  );
                                                  try {
                                                    await repo.acceptRequest(
                                                      r.id,
                                                    );
                                                    analytics.trackEvent(
                                                      'friend_request_accepted',
                                                      {'request_id': r.id},
                                                    );
                                                    ref.invalidate(
                                                      incomingRequestsProvider,
                                                    );
                                                    ref.invalidate(
                                                      friendsProvider,
                                                    );
                                                    // Keep Messages tab in sync
                                                    // with new friendships.
                                                    ref.invalidate(
                                                      messagesFriendsProvider,
                                                    );
                                                    ref.invalidate(
                                                      friendConversationsProvider,
                                                    );
                                                  } catch (_) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Could not accept request.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () async {
                                                  final repo = ref.read(
                                                    homeFriendsRepositoryProvider,
                                                  );
                                                  final analytics = ref.read(
                                                    appAnalyticsProvider,
                                                  );
                                                  try {
                                                    await repo.rejectRequest(
                                                      r.id,
                                                    );
                                                    analytics.trackEvent(
                                                      'friend_request_rejected',
                                                      {'request_id': r.id},
                                                    );
                                                    ref.invalidate(
                                                      incomingRequestsProvider,
                                                    );
                                                  } catch (_) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Could not reject request.',
                                                          ),
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) =>
                      const Text('Error loading incoming requests.'),
                ),

              if (searchQuery.trim().isEmpty) const SizedBox(height: 24),

              // Outgoing requests – only when not searching.
              if (searchQuery.trim().isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outgoing requests',
                          style: theme.textTheme.titleMedium,
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
                                      subtitle:
                                          const Text('Outgoing request'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () async {
                                              final repo = ref.read(
                                                homeFriendsRepositoryProvider,
                                              );
                                              final analytics = ref.read(
                                                appAnalyticsProvider,
                                              );
                                              try {
                                                await repo.cancelRequest(r.id);
                                                analytics.trackEvent(
                                                  'friend_request_canceled',
                                                  {'request_id': r.id},
                                                );
                                                ref.invalidate(
                                                  outgoingRequestsProvider,
                                                );
                                              } catch (_) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Could not cancel request.',
                                                      ),
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
                          error: (_, __) =>
                              const Text('Error loading outgoing requests.'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


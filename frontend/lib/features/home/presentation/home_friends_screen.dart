import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_friends_repository.dart';
import '../data/friend_requests_api_client.dart';
import '../data/user_search_api_client.dart';
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

class HomeFriendsScreen extends ConsumerWidget {
  const HomeFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(_searchQueryProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomingRequestsProvider);
        ref.invalidate(outgoingRequestsProvider);
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
              return Column(
                children: results
                    .map(
                      (u) => ListTile(
                        leading: CircleAvatar(
                          child: u.avatarUrl == null
                              ? Text(u.username.isNotEmpty
                                  ? u.username[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(u.username),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () async {
                            final repo =
                                ref.read(homeFriendsRepositoryProvider);
                            final analytics = ref.read(appAnalyticsProvider);
                            try {
                              await repo.sendFriendRequest(u.id);
                              analytics.trackEvent('friend_request_sent', {
                                'target_user_id': u.id,
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not send friend request.',
                                    ),
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

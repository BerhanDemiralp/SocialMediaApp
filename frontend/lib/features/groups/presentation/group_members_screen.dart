import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/groups_repository.dart';
import '../data/groups_api_client.dart';
import 'groups_controller.dart';
import '../../home/presentation/user_action_tile.dart';
import '../../home/data/home_friends_repository.dart';
import '../../home/data/home_messaging_repository.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../home/presentation/home_friends_screen.dart';
import '../../home/presentation/home_messages_screen.dart';

/// Loads members for a given group id via Riverpod so we don't
/// recreate the Future on every rebuild.
final groupMembersProvider = FutureProvider.family
    .autoDispose<List<GroupMemberSummary>, String>((ref, groupId) {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.listGroupMembers(groupId);
});

class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.inviteCode,
    this.groupConversationId,
  });

  final String groupId;
  final String groupName;
  final String inviteCode;
  final String? groupConversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsController = ref.read(groupsControllerProvider.notifier);
    final friendsRepo = ref.read(homeFriendsRepositoryProvider);
    final messagingRepo = ref.read(homeMessagingRepositoryProvider);
    final analytics = ref.read(appAnalyticsProvider);

    // Shared friend / request state used also by the Find Friends screen.
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.groups,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: groupConversationId == null
                ? null
                : () {
                    final route = Uri(
                      path: '/conversation/$groupConversationId',
                      queryParameters: {
                        'type': 'group',
                        'title': groupName,
                      },
                    ).toString();
                    context.push(route);
                  },
            child: const Text('Open group chat'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invite code copied: $inviteCode'),
                ),
              );
            },
            child: const Text('Invite Code'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ref.watch(groupMembersProvider(groupId)).when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text('Failed to load group members.'),
                  ),
                  data: (members) {
                    if (members.isEmpty) {
                      return const Center(
                        child: Text('No members found in this group.'),
                      );
                    }

                    final hasRelationshipData = friendsAsync.hasValue &&
                        incomingAsync.hasValue &&
                        outgoingAsync.hasValue;

                    final friends = hasRelationshipData
                        ? friendsAsync.requireValue
                        : const <dynamic>[];
                    final incoming = hasRelationshipData
                        ? incomingAsync.requireValue
                        : const <dynamic>[];
                    final outgoing = hasRelationshipData
                        ? outgoingAsync.requireValue
                        : const <dynamic>[];

                    final friendIds =
                        friends.map((f) => f.id as String).toSet();
                    final incomingUserIds =
                        incoming.map((r) => r.userId as String).toSet();
                    final outgoingUserIds =
                        outgoing.map((r) => r.userId as String).toSet();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: members.length + 1,
                      itemBuilder: (context, index) {
                        if (index == members.length) {
                          final isMember = members.any((m) => m.isSelf);
                          if (!isMember) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: FilledButton.tonal(
                              onPressed: () async {
                                try {
                                  await groupsController.leaveGroup(groupId);
                                  ref.invalidate(friendConversationsProvider);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('You left the group.'),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to leave group.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Exit group'),
                            ),
                          );
                        }

                        final member = members[index];

                        final isFriend = friendIds.contains(member.id);
                        final hasIncomingRequest =
                            incomingUserIds.contains(member.id);
                        final hasOutgoingRequest =
                            outgoingUserIds.contains(member.id);

                        return Card(
                          child: UserActionTile(
                            userId: member.id,
                            username: member.username,
                            avatarUrl: member.avatarUrl,
                            isSelf: member.isSelf,
                            isFriend: isFriend,
                            hasIncomingRequest: hasIncomingRequest,
                            hasOutgoingRequest: hasOutgoingRequest,
                            onAddFriend: member.isSelf
                                ? null
                                : () async {
                                    if (!hasRelationshipData) return;
                                    try {
                                      await friendsRepo.sendFriendRequest(
                                        member.id,
                                      );
                                      analytics.trackEvent(
                                        'friend_request_sent_from_group',
                                        {'target_user_id': member.id},
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Friend request sent to ${member.username}',
                                            ),
                                          ),
                                        );
                                      }
                                      ref
                                          .invalidate(outgoingRequestsProvider);
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
                            onRemoveFriend: isFriend
                                ? () async {
                                    try {
                                      await friendsRepo.removeFriend(
                                        member.id,
                                      );
                                      analytics.trackEvent(
                                        'friend_removed_from_group',
                                        {'friend_id': member.id},
                                      );
                                      ref.invalidate(friendsProvider);
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
                                  }
                                : null,
                            onOpenChat: () async {
                              if (!isFriend || member.isSelf) return;
                              try {
                                final ensured =
                                    await messagingRepo.ensureFriendConversation(
                                  member.id,
                                );
                                analytics.trackEvent(
                                  'friend_conversation_opened_from_group',
                                  {'conversation_id': ensured.conversationId},
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pushNamed(
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
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

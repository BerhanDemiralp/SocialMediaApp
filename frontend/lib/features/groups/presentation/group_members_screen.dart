import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_notice.dart';
import '../data/groups_repository.dart';
import '../data/groups_api_client.dart';
import 'groups_controller.dart';
import '../../users/data/user_identity_adapters.dart';
import '../../users/data/user_session.dart';
import '../../users/presentation/user_card.dart';
import '../../users/presentation/user_relationships_controller.dart';

final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMemberSummary>, String>((ref, groupId) {
      ref.watch(activeAccountIdProvider);
      ref.watch(identityRevisionProvider);
      return ref.watch(groupsRepositoryProvider).listGroupMembers(groupId);
    });

class GroupMembersScreen extends ConsumerStatefulWidget {
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
  ConsumerState<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends ConsumerState<GroupMembersScreen> {
  bool _leaving = false;

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    final account = ref.read(activeAccountIdProvider);
    try {
      await ref.read(groupsRepositoryProvider).leaveGroup(widget.groupId);
      if (!mounted || ref.read(activeAccountIdProvider) != account) return;
      ref.invalidate(groupsControllerProvider);
      ref.read(conversationsRevisionProvider.notifier).state++;
      showAppNotice(context, 'You left the group.');
      context.go('/groups');
    } catch (_) {
      if (mounted) showAppNotice(context, 'Failed to leave group.');
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(groupMembersProvider(widget.groupId));
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupMembersProvider(widget.groupId));
          await ref.read(userRelationshipsProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Icon(
              Icons.groups,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: widget.groupConversationId == null
                      ? null
                      : () => context.push(
                          Uri(
                            path: '/conversation/${widget.groupConversationId}',
                            queryParameters: {
                              'type': 'group',
                              'title': widget.groupName,
                            },
                          ).toString(),
                        ),
                  child: const Text('Open group chat'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.inviteCode),
                    );
                    if (context.mounted) {
                      showAppNotice(
                        context,
                        'Invite code copied: ${widget.inviteCode}',
                      );
                    }
                  },
                  child: const Text('Invite Code'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Column(
                children: [
                  const Text('Failed to load group members.'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(groupMembersProvider(widget.groupId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (users) => Column(
                children: [
                  if (users.isEmpty)
                    const Text('No members found in this group.'),
                  for (final member in users)
                    UserCard(key: ValueKey(member.id), user: member.identity),
                  if (users.any((user) => user.isSelf))
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: FilledButton.tonal(
                        onPressed: _leaving ? null : _leave,
                        child: const Text('Exit group'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

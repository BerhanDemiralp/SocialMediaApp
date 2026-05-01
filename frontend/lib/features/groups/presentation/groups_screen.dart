import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/groups_api_client.dart';
import 'groups_controller.dart';
import 'group_members_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupsControllerProvider);
    final controller = ref.read(groupsControllerProvider.notifier);

    void showSnack(String message) {
      if (message.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnack(state.error!);
      });
    }

    void openGroup(GroupSummary group) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroupMembersScreen(
            groupId: group.id,
            groupName: group.name,
            inviteCode: group.inviteCode,
            groupConversationId: group.conversationId,
          ),
        ),
      );
    }

    Future<void> createGroup() async {
      final name = _nameController.text.trim();
      if (name.isEmpty) return;

      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create group?'),
          content: Text('Create "$name" as a new group?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (shouldCreate != true) return;

      _nameController.clear();
      final group = await controller.createGroup(name);
      if (!context.mounted || group == null) return;
      openGroup(group);
    }

    Future<void> joinGroup() async {
      final code = _codeController.text.trim();
      if (code.isEmpty) return;

      _codeController.clear();
      final group = await controller.joinGroup(code);
      if (!context.mounted || group == null) return;
      openGroup(group);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Groups'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Groups'),
              Tab(text: 'Create / Join'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: controller.loadGroups,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (state.groups.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'You are not in any groups yet.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create a new group or join one using an invite code.',
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Groups',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...state.groups.map(
                          (group) => Card(
                            child: ListTile(
                              onTap: () => openGroup(group),
                              title: Text(group.name),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Create group',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: createGroup,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Join with invite code',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.login),
                      onPressed: joinGroup,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

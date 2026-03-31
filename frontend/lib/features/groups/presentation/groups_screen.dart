import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => GroupMembersScreen(
                                      groupId: group.id,
                                      groupName: group.name,
                                      inviteCode: group.inviteCode,
                                    ),
                                  ),
                                );
                              },
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
                      onPressed: () {
                        final name = _nameController.text;
                        _nameController.clear();
                        controller.createGroup(name);
                      },
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
                      onPressed: () {
                        final code = _codeController.text;
                        _codeController.clear();
                        controller.joinGroup(code);
                      },
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

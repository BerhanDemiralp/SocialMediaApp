import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moment_app/features/groups/presentation/groups_controller.dart';
import 'package:moment_app/features/groups/presentation/groups_screen.dart';
import 'package:moment_app/features/groups/data/groups_api_client.dart';

class _FakeGroupsController extends StateNotifier<GroupsState> {
  _FakeGroupsController(GroupsState state) : super(state);

  @override
  Future<void> loadGroups() async {}

  @override
  Future<void> createGroup(String name) async {}

  @override
  Future<void> joinGroup(String inviteCode) async {}

  @override
  Future<void> leaveGroup(String groupId) async {}
}

void main() {
  testWidgets('shows empty state when there are no groups',
      (WidgetTester tester) async {
    final initialState = GroupsState(
      groups: const <GroupSummary>[],
      isLoading: false,
      error: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsControllerProvider.overrideWith(
            (ref) => _FakeGroupsController(initialState),
          ),
        ],
        child: const MaterialApp(
          home: GroupsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.textContaining('You are not in any groups yet.'),
      findsOneWidget,
    );
  });

  testWidgets('renders list of groups', (WidgetTester tester) async {
    final groups = <GroupSummary>[
      const GroupSummary(id: 'g1', name: 'Group One', inviteCode: 'code-1'),
      const GroupSummary(id: 'g2', name: 'Group Two', inviteCode: 'code-2'),
    ];

    final initialState = GroupsState(
      groups: groups,
      isLoading: false,
      error: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsControllerProvider.overrideWith(
            (ref) => _FakeGroupsController(initialState),
          ),
        ],
        child: const MaterialApp(
          home: GroupsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Group One'), findsOneWidget);
    expect(find.text('Group Two'), findsOneWidget);
    expect(find.textContaining('Invite code: code-1'), findsOneWidget);
    expect(find.textContaining('Invite code: code-2'), findsOneWidget);
  });
}


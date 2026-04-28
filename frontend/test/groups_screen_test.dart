import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moment_app/features/groups/presentation/groups_screen.dart';
import 'package:moment_app/features/groups/data/groups_api_client.dart';
import 'package:moment_app/features/groups/data/groups_repository.dart';

class _FakeGroupsRepository extends GroupsRepository {
  _FakeGroupsRepository(this._groups)
    : super(apiClient: _NeverCalledApiClient());

  final List<GroupSummary> _groups;

  @override
  Future<List<GroupSummary>> listMyGroups() async => _groups;

  @override
  Future<GroupSummary> createGroup(String name) async {
    throw UnimplementedError();
  }

  @override
  Future<GroupSummary> joinGroup(String inviteCode) async {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    throw UnimplementedError();
  }
}

class _NeverCalledApiClient implements GroupsApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('shows empty state when there are no groups', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWithValue(
            _FakeGroupsRepository(const <GroupSummary>[]),
          ),
        ],
        child: const MaterialApp(home: GroupsScreen()),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWithValue(
            _FakeGroupsRepository(groups),
          ),
        ],
        child: const MaterialApp(home: GroupsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Group One'), findsOneWidget);
    expect(find.text('Group Two'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
  });
}

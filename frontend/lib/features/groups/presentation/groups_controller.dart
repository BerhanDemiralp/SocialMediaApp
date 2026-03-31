import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/groups_repository.dart';
import '../data/groups_api_client.dart';
import '../../../core/auth/auth_state.dart';

class GroupsState {
  const GroupsState({
    required this.groups,
    required this.isLoading,
    this.error,
  });

  final List<GroupSummary> groups;
  final bool isLoading;
  final String? error;

  GroupsState copyWith({
    List<GroupSummary>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory GroupsState.initial() =>
      const GroupsState(groups: <GroupSummary>[], isLoading: true, error: null);
}

class GroupsController extends StateNotifier<GroupsState> {
  GroupsController(this._repository) : super(GroupsState.initial()) {
    loadGroups();
  }

  final GroupsRepository _repository;

  Future<void> loadGroups() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final groups = await _repository.listMyGroups();
      state = state.copyWith(groups: groups, isLoading: false);
    } catch (_) {
      state = GroupsState(
        groups: const <GroupSummary>[],
        isLoading: false,
        error: 'Failed to load groups.',
      );
    }
  }

  Future<void> createGroup(String name) async {
    if (name.trim().isEmpty) return;

    try {
      await _repository.createGroup(name.trim());
      await loadGroups();
    } catch (_) {
      state = state.copyWith(error: 'Failed to create group.');
    }
  }

  Future<void> joinGroup(String inviteCode) async {
    if (inviteCode.trim().isEmpty) return;

    try {
      await _repository.joinGroup(inviteCode.trim());
      await loadGroups();
    } catch (_) {
      state = state.copyWith(error: 'Failed to join group.');
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _repository.leaveGroup(groupId);
      await loadGroups();
    } catch (_) {
      state = state.copyWith(error: 'Failed to leave group.');
    }
  }
}

final groupsControllerProvider =
    StateNotifierProvider<GroupsController, GroupsState>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  // Watch auth state so when user logs out/logs in as someone else,
  // this provider is rebuilt and groups are reloaded for the new user.
  ref.watch(appAuthStateProvider);
  return GroupsController(repository);
});

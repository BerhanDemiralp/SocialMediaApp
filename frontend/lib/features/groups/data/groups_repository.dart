import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'groups_api_client.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  final httpClient = http.Client();
  final apiClient = GroupsApiClient(httpClient, supabaseClient);

  ref.onDispose(httpClient.close);

  return GroupsRepository(apiClient: apiClient);
});

class GroupsRepository {
  GroupsRepository({required GroupsApiClient apiClient}) : _apiClient = apiClient;

  final GroupsApiClient _apiClient;

  Future<List<GroupSummary>> listMyGroups() {
    return _apiClient.listMyGroups();
  }

  Future<GroupSummary> createGroup(String name) {
    return _apiClient.createGroup(name: name);
  }

  Future<GroupSummary> joinGroup(String inviteCode) {
    return _apiClient.joinGroup(inviteCode: inviteCode);
  }

  Future<void> leaveGroup(String groupId) {
    return _apiClient.leaveGroup(groupId: groupId);
  }

  Future<List<GroupMemberSummary>> listGroupMembers(String groupId) {
    return _apiClient.listGroupMembers(groupId);
  }
}

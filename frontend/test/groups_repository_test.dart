import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:moment_app/features/groups/data/groups_api_client.dart';
import 'package:moment_app/features/groups/data/groups_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient implements SupabaseClient {
  _FakeSupabaseClient(this._token);

  final String? _token;

  @override
  GoTrueClient get auth => _FakeAuthClient(_token);

  // Other members are not used in these tests.
}

class _FakeAuthClient implements GoTrueClient {
  _FakeAuthClient(this._token);

  final String? _token;

  @override
  Session? get currentSession =>
      _token == null ? null : Session(accessToken: _token!, user: User(id: 'u'));

  // Other members are not used in these tests.
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[response.bodyBytes]),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  test('GroupsRepository lists groups and maps fields correctly', () async {
    final fakeHttp = _FakeHttpClient((request) async {
      expect(request.url.path.endsWith('/groups'), isTrue);
      final body = jsonEncode([
        {'id': 'g1', 'name': 'Group One', 'invite_code': 'code-1'},
        {'id': 'g2', 'name': 'Group Two', 'invite_code': 'code-2'},
      ]);
      return http.Response(body, 200, headers: {'content-type': 'application/json'});
    });

    final supabase = _FakeSupabaseClient('token');
    final apiClient = GroupsApiClient(fakeHttp, supabase);
    final repository = GroupsRepository(apiClient: apiClient);

    final groups = await repository.listMyGroups();

    expect(groups, hasLength(2));
    expect(groups[0].id, 'g1');
    expect(groups[0].name, 'Group One');
    expect(groups[0].inviteCode, 'code-1');
  });
}


import 'user_identity.dart';

enum RelationshipKind { self, none, incoming, outgoing, friend, unknown }

enum UserAction { add, cancel, accept, decline, remove }

class UserRelationship {
  const UserRelationship(this.user, this.kind, {this.requestId});
  final UserIdentity user;
  final RelationshipKind kind;
  final String? requestId;
}

class UserRelationshipsState {
  const UserRelationshipsState({
    this.accountId,
    this.records = const {},
    this.busy = const {},
    this.loaded = false,
    this.loading = false,
    this.error,
  });

  final String? accountId;
  final Map<String, UserRelationship> records;
  final Set<String> busy;
  final bool loaded;
  final bool loading;
  final String? error;

  RelationshipKind kindFor(String id) => id == accountId
      ? RelationshipKind.self
      : records[id]?.kind ??
            (loaded ? RelationshipKind.none : RelationshipKind.unknown);

  List<UserIdentity> usersOfKind(RelationshipKind kind) => [
    for (final record in records.values)
      if (record.kind == kind) record.user,
  ];

  UserRelationshipsState copyWith({
    Map<String, UserRelationship>? records,
    Set<String>? busy,
    bool? loaded,
    bool? loading,
    String? error,
  }) => UserRelationshipsState(
    accountId: accountId,
    records: Map.unmodifiable(records ?? this.records),
    busy: Set.unmodifiable(busy ?? this.busy),
    loaded: loaded ?? this.loaded,
    loading: loading ?? this.loading,
    error: error,
  );
}

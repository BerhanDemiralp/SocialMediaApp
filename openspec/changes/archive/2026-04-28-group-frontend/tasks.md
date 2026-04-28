## Tasks

### 1. Data layer: Groups API client

- [x] Add a `GroupsApiClient` in the Flutter frontend data layer that:
  - [x] Uses `AppEnv.apiBaseUrl` as the base URL.
  - [x] Reads the current Supabase session and attaches `Authorization: Bearer <accessToken>` to all requests.
  - [x] Implements methods:
    - [x] `Future<List<GroupSummary>> listMyGroups()`
    - [x] `Future<GroupSummary> createGroup({required String name})`
    - [x] `Future<GroupSummary> joinGroup({required String inviteCode})`
    - [x] `Future<void> leaveGroup({required String groupId})`

### 2. Domain model and repository

- [x] Define a `GroupSummary` domain model with at least:
  - [x] `id`, `name`, `inviteCode`.
- [x] Create a `GroupsRepository` that depends on `GroupsApiClient` and:
  - [x] Exposes the same operations to the rest of the app.
  - [x] Centralizes mapping from backend JSON to `GroupSummary`.
- [x] Add a Riverpod provider for `GroupsRepository` (for example, `groupsRepositoryProvider`).

### 3. State and controllers

- [x] Introduce Riverpod state for group management:
  - [x] A `StateNotifier` for loading the user’s group list.
  - [x] A controller (`GroupsController`) or equivalent methods that:
    - [x] Trigger `createGroup` and refresh the list on success.
    - [x] Trigger `joinGroup` and refresh the list on success.
    - [x] Trigger `leaveGroup` and refresh the list on success.
  - [x] Handle loading and error states for each action, surfacing user-friendly messages.

### 4. UI: Group Management screen

- [x] Add a `GroupsScreen` in the presentation layer that:
  - [x] Subscribes to the groups controller state and renders:
    - [x] Loading state while fetching.
    - [x] Empty state when there are no groups, with actions to create/join.
    - [x] A list of groups when present, showing at least name and invite code.
  - [x] Provides a form or controls to:
    - [x] Create a group by entering a name and submitting.
    - [x] Join a group by entering an invite code and submitting.
  - [x] Provides a “Leave” action on each group row that calls the leave controller.
  - [x] Shows non-blocking error/confirmation messages (e.g., SnackBar) for success/failure of operations.

### 5. Navigation integration

- [x] Add at least one navigation entry point to `GroupsScreen`:
  - [x] From Profile (a “My Groups” row) or equivalent.
  - [x] Ensure navigation respects existing routing patterns in `app_router.dart`.
- [x] Ensure the entry point is only available to authenticated users (consistent with other auth-gated features).

### 6. Tests and polish

- [x] Add unit tests for `GroupsRepository` mapping and error handling.
- [x] Add widget or state tests (where feasible) to cover:
  - [x] Successful list rendering.
  - [x] Empty state.
  - [x] Create/join/leave flows with mocked repository.
- [x] Manually verify flows against a running backend:
  - [x] Create group, confirm appears in backend DB.
  - [x] Join existing group via invite code.
  - [x] Leave group and confirm membership is removed.

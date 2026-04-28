## Context

The backend already exposes a complete groups API (`/groups`) backed by `groups` and `group_members` tables, but the Flutter app currently has no screens, API client, or navigation for group management. The frontend uses a clean architecture pattern (presentation/domain/data) with Riverpod for state and HTTP + Supabase for backend integration, and already has patterns for authenticated API calls (friends, conversations, auth).

This change adds a “Group Management” experience to the frontend that:
- Reuses existing authenticated HTTP patterns (Supabase JWT → `Authorization: Bearer`).
- Integrates with the existing navigation shell (for example, reachable from Home/Profile or a dedicated Groups entry).
- Does NOT introduce group chat yet; it only exposes membership management and basic group metadata.

## Goals / Non-Goals

**Goals:**
- Allow an authenticated user to:
  - See a list of groups they are a member of.
  - Create a new group by name (receiving an invite code).
  - Join an existing group using an invite code.
  - Leave a group.
- Implement a small, testable data layer for groups:
  - HTTP client that talks to existing `/groups` endpoints.
  - Repository that the UI can consume.
- Provide clear loading, error, and empty states for group management.

**Non-Goals:**
- Implement group messaging or group-based matching (those will be future changes).
- Implement public group discovery or search.
- Change backend group semantics, validation, or authorization behavior.
- Introduce new global navigation paradigms beyond a simple entry point into group management.

## Decisions

- **D1: Use a dedicated groups data client + repository**
  - Introduce `GroupsApiClient` (HTTP wrapper) and `GroupsRepository` in the Flutter app’s data layer.
  - These mirror the existing pattern used for friend conversations and auth, with:
    - Base URL from `AppEnv.apiBaseUrl`.
    - Supabase session token for `Authorization` header.
  - *Alternatives considered:*
    - Calling `http` directly from widgets → rejected; breaks clean architecture and testability.
    - Folding groups into an existing repository (e.g., friends) → rejected; mixes separate concerns.

- **D2: Represent groups as simple value objects in the domain layer**
  - Create a `GroupSummary` domain model that includes at least `id`, `name`, and `inviteCode`.
  - Keep domain models decoupled from raw JSON for flexibility.
  - *Alternative:* Use raw JSON maps in the presentation layer → rejected; brittle and harder to refactor.

- **D3: Expose group state via Riverpod providers**
  - Add:
    - A `groupsRepositoryProvider`.
    - A `groupsListProvider` (async) for listing groups.
    - A `groupsController` (StateNotifier) or ad hoc actions for create/join/leave.
  - This aligns with existing Chat/Conversations controllers and reuses familiar patterns.
  - *Alternative:* Use `FutureBuilder` inline with local state → rejected; inconsistent with current architecture.

- **D4: Initial UX: single “Manage Groups” screen**
  - Add a single screen (e.g., `GroupsScreen`) that:
    - Shows the current user’s groups as a list.
    - Provides:
      - “Create group” UI (name input + submit).
      - “Join group” UI (invite code input + submit).
      - “Leave” action on each group row.
  - Entry point:
    - Either from Profile (e.g., “My Groups”) or from Home (e.g., a simple action in a menu).
  - *Alternative:* Add a full dedicated tab for groups → deferred; can be revisited once groups are more central.

- **D5: Error and empty state behavior**
  - For `GET /groups`:
    - Show loading spinner while fetching.
    - On success but empty list → show explicit “You’re not in any groups yet” message with create/join affordances.
    - On error → show a generic error message and offer a retry.
  - For create/join/leave:
    - On success → refresh list and show lightweight confirmation (snackbar or inline message).
    - On error → show error message; keep current list intact.
  - *Alternative:* Silent failures with only console logs → rejected; poor UX.

## Risks / Trade-offs

- **[Risk] API shape mismatch or future backend changes**
  - *Mitigation:* Keep mapping logic centralized in `GroupsApiClient` and `GroupsRepository`, so backend changes only require updates in one place.

- **[Risk] Navigation clutter if groups become more central later**
  - *Mitigation:* Start with a simple entry point (Profile / Home) and keep the screen self-contained; future changes can promote groups into a primary tab without breaking internal contracts.

- **[Risk] Incomplete alignment with future matching or group chat features**
  - *Mitigation:* Only commit to basic group metadata (id, name, invite_code) and membership operations. Avoid encoding assumptions about future matching or chat in this design.

- **[Risk] Auth/session edge cases**
  - *Mitigation:* Reuse existing Supabase-based auth wiring and patterns already used for conversations and Home flows; surface “not authenticated” as a clear error state if needed.


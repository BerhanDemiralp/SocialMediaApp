## Context

The Flutter app uses Riverpod, repositories, GoRouter, and Material 3. `UserActionTile` is partly shared, but Home/Friends and GroupMembersScreen still resolve relationship booleans, select request IDs, call APIs, and invalidate providers independently. Incoming/outgoing Home lists bypass the tile. Messages separately fetches friends; sender avatars and profile headers depend on a widget owned by Home.

The current working tree includes fixes for cancelling outgoing requests, accepting/declining group requests, preset avatars, group/chat navigation, and touch-through notices. These are required baseline behavior, not disposable code during the refactor.

## Goals / Non-Goals

**Goals:**
- One identity renderer and one relationship-card policy across user surfaces.
- One session-scoped owner of relationship data, mutation status, and request IDs.
- Predictable actions, navigation, feedback, and mobile layout.
- Delete redundant implementations after migration.

**Non-Goals:**
- New full profile pages, profile-detail APIs, matching behavior, or social permissions.
- A generic card that renders group entities, chat bubbles, daily answers, and every domain object.
- Backend changes, database changes, new packages, or remote real-time friendship synchronization.

## Decisions

### 1. Shared feature ownership and composable presentation

Create `features/users/{domain,data,presentation}`. Use a small `UserIdentity` model (`id`, `username`, `avatar`) with adapters for existing API DTOs. Move avatar presets and fallback rendering into this shared presentation module. `UserIdentityView` supports avatar-only, compact, and header layouts; `UserCard` composes it with relationship actions. Domain identity contains no widgets, navigation, or API calls.

A connected card resolves shared state and dispatches typed actions; its presentational child only renders a view model. Screens provide user identity and contextual subtitle, not friendship flags or API callbacks. Group and Moment containers keep their own information and compose the identity view.

Alternative considered: make every surface instantiate one large widget with many flags. This would reproduce today's conflicting booleans and couple conversation-specific behavior to friendship controls.

### 2. One relationship snapshot per signed-in account

A `UserRelationshipsController` loads friends, incoming requests, and outgoing requests once per session/refresh through existing API clients and normalizes them by target user ID. Store request IDs separately from user IDs. Represent relationship as one of `self`, `none`, `incoming(requestId)`, `outgoing(requestId)`, `friend`, or `unknown`; track loading/error and pending action independently.

Until the required relationship snapshot succeeds, unknown users have disabled social actions and a retry affordance. Do not infer `none` from an empty loading/error fallback. Known data remains visible during refresh. A confirmed friendship takes precedence over obsolete pending records; contradictory incoming/outgoing records trigger reconciliation rather than enabling conflicting operations.

Scope the controller to the authenticated account ID, reset it on sign-out/account switch, and disregard responses from an older account or disposed controller. Use snapshot/mutation revisions so a pre-mutation refresh cannot overwrite a newer successful action. Refresh is explicit on existing refresh surfaces and after mutation; cards do not issue individual relationship requests.

Alternative considered: preserve separate friends/incoming/outgoing providers and centralize only the widgets. This still permits partial refreshes and duplicated mutation logic. Old providers may temporarily delegate to the new owner during migration, but must not remain independent sources of truth.

### 3. Shared action policy

| Relationship | Primary actions | Secondary behavior |
| --- | --- | --- |
| Self | None | Own profile settings stay on Profile |
| None | Add friend | No new direct chat |
| Outgoing | Cancel request | Successful cancellation restores Add friend |
| Incoming | Accept, Cancel | Cancel calls reject, not outgoing cancel |
| Friend | Message | Remove friend in overflow menu |
| Unknown/loading/error | Disabled actions / Retry | Never offer Add friend speculatively |

All actions are keyed by account and target user ID. One in-flight social operation per target disables conflicting controls across all appearances of that person; other users remain actionable. The controller selects the correct stored request ID and API operation. On success it commits the normalized transition immediately, then reconciles with the server. On failure it preserves the last confirmed state and enables retry; a failed post-success refresh must not report that the mutation itself failed.

Accept/remove refresh conversation and Messages projections centrally. Profile updates invalidate shared identity consumers so stale list avatars/names do not persist. Notices use the existing `showAppNotice` once per operation, never during widget build. No confirmation popup is added for routine request actions.

Alternative considered: optimistic relationship transitions. Confirmed transitions keep error handling and request-ID availability simple while per-user busy state provides immediate feedback.

Implementation detail: the existing send-request client returns no request ID. A successful send therefore commits the outgoing state immediately and obtains its ID during reconciliation. If that read fails, the card keeps the confirmed outgoing state, disables cancellation until the ID is known, and exposes Retry. Contradictory incoming/outgoing snapshots similarly expose Retry without starting an unbounded automatic retry loop.

### 4. Navigation and surface policy

- Relationship cards in search, request lists, and groups use the same layout and action policy. Tapping a confirmed friend's identity or Message opens/reuses their friend conversation. Non-friend identity taps do not silently create a conversation.
- A shared conversation-opening coordinator guards repeated taps, ensures a friend conversation when needed, and uses GoRouter with mounted checks and error feedback. Existing conversation rows open their known conversation ID directly, including read-only/history entries.
- Messages uses the shared identity and centralized friend data, while its row retains snippet, timestamp, writable state, and group-specific rendering.
- Chat uses shared avatars; Profile uses the header identity variant; Moment participant presentation uses shared identity with existing Moment metadata and compact-chat controls.
- Group info remains accessible from persistent group chat. Group entities retain group icons; they are not users.

Alternative considered: introduce a profile sheet for every identity tap. This is a separate navigation/product feature and would change the recently repaired tap-to-chat behavior.

### 5. Responsive layout and accessibility

Use common spacing, avatar sizes, typography, semantics, and minimum 48 logical-pixel action targets. Keep identity on the left and actions on the right, wrapping controls within the right-hand area when needed; long names and large text must not squeeze controls off-screen. Keep all labels consistent in English with the current UI, including Accept / Cancel for incoming requests. Avatar rendering supports presets, valid network images, empty/invalid images, and fallback icons in both themes.

## Risks / Trade-offs

- [Partial refresh makes a friend briefly appear unrelated] -> Commit a single normalized transition and reject stale refresh responses.
- [Old account response affects the next session] -> Account-scoped ownership, request generation checks, and cancellation/disposal guards.
- [Refactor loses recent fixes] -> Migrate regression tests and run them before removing old implementations.
- [New shared module becomes coupled to Home] -> Move relationship ownership and adapters into Users; keep navigation/refresh integration explicit and one-directional.
- [Same identity appears from several DTOs] -> Use adapters and centralized invalidation; prefer refreshed profile data over older list snapshots.
- [Cross-device changes remain unseen] -> Reconcile on explicit refresh and mutation errors; real-time friendship subscriptions remain outside scope.

## Migration Plan

1. Capture the current behavior and inventory all user-rendering and mutation call sites.
2. Introduce shared identity, relationship state/controller, action/navigation coordination, and tests alongside the existing implementation.
3. Migrate Home search and request lists, then group members, to the shared card and controller.
4. Migrate Messages identity/friend data and Chat/Profile/Moment identity rendering without changing their conversation semantics.
5. Delete `UserActionTile`, obsolete Home-owned avatar implementation, duplicate handlers, and independent relationship providers once no callers remain.
6. Run analysis, focused regression/state tests, and manual mobile checks. No database deployment is needed. Rollback consists of reverting only this refactor's changes while retaining the earlier bug fixes.

## Open Questions

No blocking question for the proposed scope. Full user profile pages can be a later change; this change preserves current identity-to-chat behavior.

## User review: horizontal cards and immediate chat navigation

Cards use a horizontal identity/actions layout; controls wrap within the right-hand area on narrow screens. The Home shell preloads the account-scoped conversation list. Known friend IDs open directly without an ensure request or pre-navigation list refresh. Unknown IDs open a dedicated friend-chat route immediately and resolve inside that screen, with retry on failure and an account-scoped ID cache. Both chat routes use NoTransitionPage to avoid exposing the previous screen during an animated transition. Initial message fetching remains asynchronous inside chat. Router authentication observes only the authenticated boolean so equivalent auth events do not recreate navigation.

## User review: compact actions

Outgoing cancellation and incoming rejection use close IconButtons with descriptive tooltips (Cancel request / Decline request) and 48px touch targets. Accept remains a labeled button. Friends have no separate Message button: the whole card opens chat, while the overflow menu handles its own taps. Icon-only action areas leave more width for usernames. This supersedes the earlier text-button presentation.

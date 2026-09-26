## 1. Baseline and shared identity

- [x] 1.1 Inventory all identity/card renderers and relationship mutation call sites; record the existing request, avatar, notice, and navigation regression baseline without reverting current working-tree fixes.
- [x] 1.2 Add the shared Users feature structure, UserIdentity model, and adapters for search, friends, requests, members, conversations, profiles, message senders, and Moment participants.
- [x] 1.3 Move avatar presets/rendering to the shared presentation layer and provide avatar-only, compact, and header identity variants with image fallbacks.

## 2. Central relationship ownership

- [x] 2.1 Implement account-scoped relationship loading through existing API clients and normalize friends/incoming/outgoing data by user ID with request IDs retained.
- [x] 2.2 Implement explicit self/none/incoming/outgoing/friend/unknown states, initial loading/retry, refresh retention, and contradictory-record reconciliation.
- [x] 2.3 Implement send/cancel/accept/reject/remove operations with per-target locks, confirmed local transitions, server reconciliation, and a single non-blocking notice per result.
- [x] 2.4 Add stale-response revisions, disposal/account-switch guards, and central invalidation of Messages/conversation and identity projections after relevant changes.
- [x] 2.5 Test request-ID selection, all successful transitions, failures/retry, post-success refresh failure, duplicate/conflicting taps, parallel actions on different targets, stale fetches, and account switching.

## 3. Shared card and conversation actions

- [x] 3.1 Build presentational and connected user cards with a single action policy: Add friend, Cancel request, Accept / Cancel, Message, overflow Remove friend, self, and unknown/retry.
- [x] 3.2 Implement common friend-conversation opening with per-user duplicate prevention, GoRouter navigation, mounted/account checks, and recoverable error feedback.
- [x] 3.3 Verify responsive layout at 320 logical pixels and 200 percent text scale, long names, 48-pixel targets, semantics, both themes, and preserved preset/network/fallback avatars.

## 4. Migrate screens

- [x] 4.1 Replace Home search and incoming/outgoing rows with shared cards and shared relationship projections; remove screen-owned request handlers.
- [x] 4.2 Replace group member card logic with the shared system while preserving invite/leave/open-chat controls and group-chat-to-details navigation.
- [x] 4.3 Migrate Messages to shared user identity and centralized friend state; preserve conversation snippets/timestamps, group visuals, known-ID navigation, and read-only history access.
- [x] 4.4 Migrate sender avatars, profile headers, and Moment participant identities to shared rendering; retain profile editing/password settings and Moment-specific controls.
- [x] 4.5 Ensure profile name/avatar edits refresh all relevant identity projections and verify relationship changes update other mounted screens without manual reload.

## 5. Cleanup and verification

- [x] 5.1 Remove obsolete UserActionTile, Home-owned avatar implementation, independent relationship providers, and duplicate mutation/navigation handlers once callers are migrated; check imports and remaining call sites.
- [x] 5.2 Adapt and run existing request cancellation, incoming response, group navigation, and notice regression tests against the shared implementation.
- [x] 5.3 Add cross-surface tests for accepting/cancelling/removing a relationship, direct/history chat routing, and account isolation; run flutter analyze and all affected frontend tests.
- [x] 5.4 Manually verify search -> request -> group response -> Messages/chat, cancel -> resend, long-name/small-screen layout, avatar consistency, and non-blocking feedback; record any unavailable live verification explicitly.
- [x] 5.5 Verify implementation against this change's requirements and prepare the change for archive after all tasks are complete.

Verification evidence and the task 5.4 live-backend/device limitation are recorded in `verification.md`.

## 6. User review follow-up

- [x] 6.1 Place shared card actions to the right of avatar/name, retaining narrow-screen accessibility.
- [x] 6.2 Reuse account-scoped conversation IDs, remove pre-navigation reload and chat transition flash, and verify regressions.

- [x] 6.3 Reproduce and fix conversation rows being replaced by friend cards during the return-from-chat refresh; retain account-switch isolation.

- [x] 6.4 Replace cancel labels with accessible close icons; remove Message button and enable whole-friend-card chat taps.

- [x] 6.5 List existing friends below incoming/outgoing requests in Find Friends using the shared card, including an empty state.

- [x] 6.6 Show sender avatar and name on every chat message, including direct chats, Moments, and own messages; keep own avatars on the right.

- [x] 6.7 Place timestamps to the right of message text and show identity only on the first message in each consecutive sender run, preserving bubble alignment.

- [x] 6.8 Hide sender name/avatar on own messages, without reserving an empty avatar slot.

- [x] 6.9 Refine consecutive-message spacing, first-message corners, 8px rounding, and right-aligned conversation timestamps.
- [x] 6.10 Reduce Accept's visual size while retaining its touch target; verify equal standard card dimensions at 320, 390, and 600 pixels.

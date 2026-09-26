## Why

User presentation and relationship actions are split between `UserActionTile`, custom request rows, group member callbacks, message rows, and profile/chat avatars. Recent fixes exposed inconsistent pending-request buttons, navigation, avatar handling, and refresh behavior; a shared system should make each fix apply everywhere.

## What Changes

- Introduce one reusable user identity and card system with consistent avatars, names, accessible sizing, and actions derived from relationship state.
- Centralize relationship loading, request IDs, mutations, per-user busy state, error feedback, and cache synchronization in an authenticated-session-scoped Riverpod controller.
- Use the same action policy in search results, incoming/outgoing request lists, and group members: Add friend; Cancel request; Accept / Cancel; Message with Remove friend in an overflow menu; no social actions for self.
- Reuse the identity renderer in direct conversation rows, sender avatars, profile headers, and Moment participant presentation while retaining each surface's conversation-specific information and navigation.
- Preserve the current friend-only new-chat rule, historical conversation access, group details navigation, avatar presets/fallbacks, and non-blocking notices.
- Migrate callers and delete obsolete user-card widgets, duplicate action handlers, and redundant relationship providers after their replacements are verified.

## Capabilities

### New Capabilities

- `unified-user-presentation`: Shared identity/card presentation, relationship state and action policy, consistent navigation, concurrency protection, and cross-surface synchronization.

### Modified Capabilities

- `home-friends-search-and-requests`: Require common actionable request states in search and request lists, with consistent Accept / Cancel labels and immediate shared-state updates.
- `group-frontend`: Define shared user cards and full friend-request actions in the group member list.

## Impact

- Flutter: new shared `features/users` domain, data, and presentation modules; migrations in Home/Friends, Groups, Messages, Chat, Profile, and Moment participant presentation.
- Existing friend/request, profile, group, and conversation APIs are reused; no database migration, backend contract change, or new package is planned.
- Existing uncommitted bug fixes and regression tests are the migration baseline and must be preserved.
- New public profile pages, richer user data, matching rules, notification infrastructure, and block/report functionality are outside this change.

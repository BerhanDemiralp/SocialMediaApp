## Why

The product currently lacks a concrete notion of the social graph, so daily questions, matching, and games have no reliable way to understand who is connected to whom. This change introduces first‑class friendships and lightweight groups so the rest of the system can target prompts, matches, and conversations at real relationships instead of anonymous users.

## What Changes

- Add backend support for user‑to‑user friendships with mutual confirmation.
- Add friend request lifecycle: send, accept, reject/cancel.
- Expose endpoints to list my friends and pending requests.
- Introduce basic groups that users can join via invite codes.
- Allow users to see and manage the groups they belong to.
- Enable join/leave flows for groups via invite codes.
- Surface the social graph (friends and groups) through stable APIs for use by daily questions, matching, and games.

## Capabilities

### New Capabilities
- `friends-and-groups`: CRUD for friendships and basic group membership, including friend requests, groups with invite codes, and listing a user’s social graph.

### Modified Capabilities
- `<existing-name>`: <what requirement is changing>

## Impact

- **Database**: Uses existing `friendships`, `groups`, and `group_members` tables as the canonical social graph storage.
- **Backend (NestJS)**: New or updated modules/controllers/services for friendships and groups, wired into Prisma and Supabase Auth.
- **APIs**:
  - Friend requests: send/accept/reject/cancel, list pending requests.
  - Friend list: list my confirmed friends.
  - Groups: create group, join/leave via invite code, list my groups.
- **Dependents**: Daily questions, matching engine, and games can query a user’s friends and groups to build targeted experiences.
- **Security**: All endpoints must be authenticated, scoped to the current user, and respect privacy/safety constraints.


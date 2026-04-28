## Why

The backend already supports groups (create, join by invite code, leave, list my groups), but the Flutter frontend has no real group flows wired up. Users cannot see which groups they belong to, create a new group from the app, or join a group via invite code, which blocks the Groups Mode vision and any future group-based matching or conversations.

## What Changes

- Add an authenticated Group Management surface to the frontend where users can:
  - View a list of groups they belong to (name + invite code).
  - Create a new group by providing a name.
  - Join an existing group using an invite code.
  - Leave a group they are a member of.
- Wire the frontend to the existing backend groups API:
  - `GET /groups` → list current user's groups.
  - `POST /groups` → create a group.
  - `POST /groups/join` → join by invite code.
  - `POST /groups/:groupId/leave` → leave a group.
- Integrate group flows into the existing navigation and home experience so that:
  - Groups are discoverable from the main app shell (for example, via a Groups tab/section or an entry from Home/Profile).
  - Group actions reuse existing auth/session handling and API error/display patterns.
- Prepare for future group-based matching and conversations:
  - Ensure the frontend can surface basic group membership state that later matching features can depend on.

## Capabilities

### New Capabilities

- `group-frontend`: Frontend support for creating, joining, listing, and leaving groups, wired to the existing backend groups API.

### Modified Capabilities

- `friends-and-groups`: Extend the high-level friends/groups experience to explicitly cover group management flows in the mobile app (how users create/join/leave groups from the frontend).
- `home-friends-search-and-requests`: If needed, clarify how the Home/Friends surface exposes navigation into group management (for example, entry points to groups from Home or profile).

## Impact

- **Frontend / Flutter**
  - New presentation layer for group management (screens/widgets).
  - New data layer elements (API client, repository, state management) for groups, aligned with existing patterns.
  - Navigation updates so users can access group functionality from within the logged-in app.
- **Backend Integration**
  - Consumption of existing `/groups` endpoints with authenticated HTTP calls using Supabase session tokens.
  - Error handling and empty/loading state UX consistent with other networked features (friends, conversations).
- **Product & Future Work**
  - Unblocks future group-based matching and conversation flows by ensuring group membership is actually reachable and manageable from the app.

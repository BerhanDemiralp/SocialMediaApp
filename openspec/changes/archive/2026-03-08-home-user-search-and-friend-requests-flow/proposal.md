## Why

Right now there is no cohesive, product-grade flow that lets a user find friends by username, send friend requests, and manage incoming/outgoing requests from the home experience. Friend relationships are supported in the backend, but the API surface is incomplete (no search, no full request lifecycle), and the Flutter app does not yet expose a simple place to discover and add friends. This makes it hard for new users to bootstrap their graph and for existing users to keep their close friends in MOMENT.

## What Changes

- Add a **user search endpoint** that allows authenticated clients to search by username (with simple prefix/substring matching and rate limiting) while respecting basic safety constraints.
- Complete the **friend request HTTP API** on the backend so the Flutter app can:
  - Send friend requests.
  - Accept or reject incoming requests.
  - Cancel outgoing requests.
  - List incoming and outgoing pending requests.
- Extend the Flutter app with a **Home / Friends surface** that:
  - Exposes a search UI for usernames.
  - Allows sending friend requests directly from search results.
  - Shows incoming and outgoing requests as simple, actionable lists.
  - Provides clear empty / loading / error states that fit the cozy, low-pressure tone.
- Wire the Home UI to the existing friend graph and conversations model so that accepted friendships ultimately flow into the daily matching and conversations experiences.

## Capabilities

### New Capabilities
- `home-friends-search-and-requests`: End-to-end UX on the Home screen for searching by username, sending friend requests, and managing incoming/outgoing requests in a simple, low-friction flow.

### Modified Capabilities
- `backend-api`: Add/clarify REST endpoints for user search and the friend-request lifecycle (send, accept, reject, cancel, list incoming/outgoing).
- `friend-graph`: Extend requirements for how friend requests transition into accepted friendships and how search interacts with existing graph rules (e.g., duplicates, blocking).

## Impact

- **Backend (NestJS + Prisma)**
  - New authenticated GET endpoint for searching users by username.
  - Additional friend-request endpoints or refinements on the existing friends controller to support full lifecycle and listing.
  - Potential indexes or query tuning on the `users` table to support username search at current scale.

- **Flutter app**
  - New repositories and DTOs for user search and friend-request operations.
  - New or extended Home/friends UI to show:
    - Search bar and results.
    - Incoming and outgoing friend-request lists with actions.
  - Wiring to existing auth/session and navigation so this flow is accessible from the main shell.

- **Specs & future changes**
  - Backend specs for `backend-api` and `friend-graph` updated with search + request lifecycle requirements.
  - Provides a foundation for future changes like friend suggestions, improved search ranking, or richer friend-management UX, without altering the core conversations model.


## Context

The backend already supports friend relationships via a `friendships` table and a friends module, but lacks a complete, documented API surface for searching users by username and managing the full friend-request lifecycle (send, accept, reject, cancel, list). On the frontend, the Flutter app has authentication, shell, and chat foundations, but there is no cohesive Home/Friends experience that lets users discover friends and manage requests.

This design adds:
- A username-based search endpoint on the NestJS backend.
- A set of friend-request endpoints that expose the existing friendship model in a mobile-friendly way.
- Flutter repositories and Home UI surfaces to search by username and manage incoming/outgoing friend requests.

It builds on:
- Existing backend friends and users modules.
- The unified conversations backend foundation (conversations model and APIs).
- The Flutter app’s existing auth/session handling, navigation, and design primitives.

## Goals / Non-Goals

**Goals:**
- Allow an authenticated user to search for other users by username from the Home/Friends surface.
- Allow sending friend requests from search results, with clear feedback on success and failure.
- Allow managing incoming and outgoing friend requests (accept, reject, cancel) from simple lists.
- Reuse the existing `friends` / `friendships` domain model and respect safety constraints (no duplicate friendships, no self-requests).

**Non-Goals:**
- Building a full people-discovery system (recommendations, ranking, mutuals).
- Adding public user directories or phone-contact importing.
- Implementing advanced rate limiting, abuse detection, or search relevance beyond simple filters.
- Changing the conversations model or matching logic; this change only prepares the friend graph so daily pairing and conversations work better.

## Decisions

1. **Username Search Endpoint**
   - Add `GET /api/users/search?query=<string>&limit=<N>`:
     - Authenticated via existing `AuthGuard`.
     - Simple case-insensitive `ILIKE` search on `users.username`, scoped to a sensible `limit` (e.g., 20).
     - Excludes the requesting user and (optionally) users already blocked or otherwise unsafe.
   - Rationale: Minimal backend surface that aligns with current schema and scales for MVP; avoids premature complexity in search ranking.

2. **Friend-Request REST API**
   - Extend the friends module with explicit endpoints:
     - `POST /api/friends/requests` – send friend request (body: `targetUserId` or username).
     - `GET /api/friends/requests/incoming` – list pending incoming requests.
     - `GET /api/friends/requests/outgoing` – list pending outgoing requests.
     - `PATCH /api/friends/requests/:id/accept` – accept request.
     - `PATCH /api/friends/requests/:id/reject` – reject request.
     - `PATCH /api/friends/requests/:id/cancel` – cancel outgoing request.
   - Reuse and slightly extend existing service/repository logic so that:
     - Duplicate pending/accepted friendships are prevented.
     - Only the requester can cancel, only the addressee can accept/reject.
   - Rationale: Makes the friend lifecycle explicit and self-contained for the mobile client.

3. **Flutter Repositories and DTOs**
   - Add Flutter data-layer components:
     - `UserSearchRepository` / `UserSearchApiClient` for `/users/search`.
     - `FriendRequestsRepository` for the friends endpoints above.
   - Reuse existing HTTP client + Supabase auth token injection.
   - Rationale: Keeps API details isolated and testable, and matches existing Clean Architecture patterns.

4. **Home/Friends UI Composition**
   - Add a Home/Friends tab or sub-screen that:
     - Shows a search field + results list with “Add friend” actions.
     - Shows incoming requests (with accept/reject buttons).
     - Shows outgoing requests (with cancel buttons).
   - State handled via Riverpod:
     - `userSearchProvider` for search term and results.
     - `incomingRequestsProvider` / `outgoingRequestsProvider` for request lists.
   - Rationale: Centralizes friend graph management in one simple surface instead of scattering it.

5. **Error and Empty-State UX**
   - Use shared loading/empty/error components:
     - Empty results: “No users found for ‘query’”.
     - Empty incoming: “No pending requests – you’re all caught up.”
     - Empty outgoing: “You haven’t sent any requests yet.”
   - Map backend errors (e.g., “user not found”, “already friends”) to friendly messages.
   - Rationale: Keeps the experience cozy and low-pressure.

## Risks / Trade-offs

- **Search performance on usernames**
  - Risk: `ILIKE` queries on usernames may become slow at scale.
  - Mitigation: Add an index on `LOWER(username)` if necessary; for MVP-size user counts this is unlikely to be an issue.

- **Friend-request abuse (spam)**
  - Risk: Users could send many requests to strangers.
  - Mitigation: Initially rely on simple rate limiting and the small scale of the app; consider per-user caps and block/report integration in future changes.

- **Complexity in Home UI**
  - Risk: Overloading the Home screen with too many controls could hurt usability.
  - Mitigation: Keep layout simple: search at top, incoming section, outgoing section; avoid advanced filters or deep navigation at this stage.

- **Backend contract evolution**
  - Risk: Future changes to friend graph semantics (e.g., mutual friends, groups) may require adjusting these endpoints.
  - Mitigation: Keep friend-request payloads and responses small and versionable; document semantics in specs and this design.


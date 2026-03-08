## 1. Backend user search and friend-request APIs

- [x] 1.1 Add `GET /users/search` endpoint to the users module with query + limit parameters and basic validation.
- [x] 1.2 Implement Prisma query and any needed index to support case-insensitive username search, excluding the current user.
- [x] 1.3 Extend friends controller/service with `POST /friends/requests` to create pending friend requests, enforcing no duplicates and no self-requests.
- [x] 1.4 Implement `GET /friends/requests/incoming` and `GET /friends/requests/outgoing` endpoints to list pending requests for the authenticated user.
- [x] 1.5 Implement `PATCH /friends/requests/:id/accept`, `:id/reject`, and `:id/cancel` endpoints with correct authorization checks (only addressee can accept/reject, only requester can cancel).
- [x] 1.6 Add or update backend tests (unit/integration) covering search behavior and the friend-request lifecycle endpoints.

## 2. Flutter data layer (search and friend requests)

- [x] 2.1 Add API client and repository classes for user search (e.g., `UserSearchApiClient` / `UserSearchRepository`) that call `/users/search`.
- [x] 2.2 Add repository methods and DTOs for friend requests (send, list incoming/outgoing, accept, reject, cancel) wired to the new backend endpoints.
- [x] 2.3 Integrate repositories into Riverpod providers (or equivalent) for search results and incoming/outgoing request lists.

## 3. Flutter Home/Friends UI

- [x] 3.1 Implement a Home/Friends screen or tab that surfaces a username search field and results list.
- [x] 3.2 Wire “Add friend” actions from search results to the send-request repository method, updating UI state on success/failure.
- [x] 3.3 Implement incoming requests list with accept/reject buttons and optimistic UI updates when actions succeed.
- [x] 3.4 Implement outgoing requests list with cancel buttons and optimistic UI updates when actions succeed.
- [x] 3.5 Add appropriate loading, empty, and error states for search, incoming requests, and outgoing requests, reusing shared components.

## 4. Integration, safety, and polish

- [x] 4.1 Ensure friend-request flows respect existing friend graph rules (no duplicates, no self-requests, honor blocked users once available).
- [x] 4.2 Verify that accepted friendships are reflected in any existing “friends list” or daily pairing logic as expected.
- [x] 4.3 Add basic analytics/telemetry events for key actions (search, send request, accept/reject/cancel).
- [x] 4.4 Update API and mobile documentation (e.g., backend README, Flutter API docs) to describe new endpoints and Home/Friends flows.


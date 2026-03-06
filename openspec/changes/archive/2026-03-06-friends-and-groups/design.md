## Context

The backend currently has database tables for `friendships`, `groups`, and `group_members`, but there is no cohesive API layer that exposes them as a first‑class social graph. Other features (daily questions, matching, games) will need a reliable way to query a user’s friends and groups. This change introduces dedicated NestJS modules for friendships and groups, backed by Prisma models, and protected by Supabase Auth.

## Goals / Non-Goals

**Goals:**
- Provide authenticated REST endpoints to manage friend requests and confirmed friendships.
- Provide endpoints to create groups, join/leave via invite codes, and list a user’s groups.
- Keep the design simple and synchronous (no background jobs) for MVP.
- Reuse existing PostgreSQL tables and Prisma models where possible.

**Non-Goals:**
- Advanced social features (blocking, reporting, muting, recommendations).
- Public group discovery or search.
- Complex matching algorithms or graph analytics.
- Real-time presence or notifications wiring (handled by separate systems).

## Decisions

- **NestJS modules:** Create `FriendsModule` and `GroupsModule`, each with controller, service, and repository layers following existing project patterns.
- **Authentication:** Use existing Supabase Auth guard to inject the current user ID into controllers. All endpoints require an authenticated user.
- **Prisma integration:** Add Prisma models/mappers for `friendships`, `groups`, and `group_members` if not already defined. Encapsulate DB access in repository classes to keep services focused on business rules.
- **Friendship model:** Represent each friendship as a row in `friendships` with fields for requester, addressee, status (e.g., `PENDING`, `ACCEPTED`, `REJECTED`), and timestamps. Service enforces that users cannot befriend themselves and prevents duplicate pending requests.
- **Group model:** Represent each group in `groups` with owner, name, optional description, and an immutable invite code. Membership is stored in `group_members` with role (e.g., `OWNER`, `MEMBER`) and timestamps.
- **API shape:** Use clear, resource‑oriented endpoints such as `/friends/requests`, `/friends`, `/groups`, `/groups/join`, and `/groups/:groupId/leave`. Request/response DTOs are validated with class‑validator or Zod according to existing conventions.
- **Error handling:** Reuse global NestJS exception filters. Services throw domain‑specific exceptions (e.g., `ForbiddenException` when joining a group the user is already in) that map cleanly to HTTP status codes.

## Risks / Trade-offs

- **Race conditions on friend requests:** Two users could send requests to each other simultaneously. Mitigation: enforce a unique constraint on `(requester_id, addressee_id)` at the DB level and normalize to a single pending request in the service.
- **Invite code leakage:** Simple invite codes could be guessed. Mitigation: use high‑entropy codes (e.g., UUID‑based or securely random tokens) and rate‑limit join attempts at the API gateway.
- **Growing group membership lists:** Large groups could lead to heavy queries when listing members. Mitigation: for MVP, accept this cost; later introduce pagination and indexed queries if needed.
- **Coupling to existing schemas:** Relying on current table structures may limit future evolution. Mitigation: keep controllers/services decoupled from concrete Prisma shapes via repository interfaces to ease refactors.


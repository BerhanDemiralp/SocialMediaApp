## Context

The current backend already provides:

- Supabase-based authentication and JWT verification.
- A Prisma schema with a `messages` table linked to `matches` and `users`.
- A NestJS WebSocket gateway (`EventsGateway`) with a `sendMessage` event that broadcasts ephemeral messages to `match:{matchId}` rooms.
- A REST API with authenticated endpoints (`/users/me`) and guards wired through `AuthGuard`.

However, messages sent via Socket.io are not persisted to the database and there is no HTTP API for loading message history for a match. This limits the ability for the product to:

- Show past conversations when a user opens a chat.
- Use message activity as part of the “Moment” success condition.

The `message-v1` change introduces persistence and read APIs for 1:1 match chats only (no group chats yet).

## Goals / Non-Goals

**Goals:**

- Persist messages sent via the existing Socket.io gateway into the `messages` table.
- Emit `newMessage` events with the stored database record (including stable `id` and timestamps).
- Provide an authenticated HTTP endpoint to fetch message history for a 1:1 match.
- Enforce that only participants in a match can send or read messages for that match.

**Non-Goals:**

- Group chat semantics or group-scoped message history.
- Read/unread tracking, delivery receipts, or typing state persistence.
- Message editing or deletion.
- Media attachments or rich content.
- Complex pagination or search; v1 can use a simple `limit` and chronological ordering.

## Decisions

1. **Use existing `messages` table and Prisma for persistence**

   - Reuse the `messages` model defined in `schema.prisma`:
     - `id`, `match_id`, `sender_id`, `content`, `created_at`, and relation fields.
   - No schema changes for v1; we focus on wiring implementation to what already exists.
   - Rationale: keeps the change small and aligned with the initial database design.

2. **Persist messages inside the WebSocket gateway using Prisma**

   - Extend `EventsGateway`’s `sendMessage` handler to:
     - Inject a message-writing service (or Prisma directly) via NestJS DI.
     - Validate that the socket’s authenticated `client.user.id` belongs to the match (`matches.user_a_id` or `user_b_id`).
     - Create a `messages` record via Prisma and then emit `newMessage` with the saved record.
   - Rationale: the gateway already has the correct context (socket identity, match room) and is the natural entry point for message persistence.

3. **Expose message history via a dedicated REST endpoint**

   - Add a controller (e.g., `MatchesMessagesController`) under the existing backend module structure.
   - Route: `GET /matches/:matchId/messages`
     - Protected by HTTP auth guard.
     - Validates that the caller’s user ID is part of the match (`user_a_id` or `user_b_id`).
     - Queries `messages` by `match_id`, ordered by `created_at`, with a simple `limit` parameter (default, e.g., 50).
   - Rationale: history is best accessed over HTTP where clients can easily paginate and cache; WebSockets remain focused on real-time updates.

4. **Keep access control local and explicit**

   - For both WebSocket and HTTP paths, we will:
     - Fetch the `match` record by `match_id`.
     - Check that `user.id` from the auth context matches either `user_a_id` or `user_b_id`.
   - If the user is not a participant:
     - WebSocket: throw a gateway exception to prevent broadcasting and DB write.
     - HTTP: respond with `403 Forbidden` (or `404 Not Found` if we prefer not to leak match existence).
   - Rationale: simple, local checks per endpoint; can later be extracted into shared utilities or guards if reused by other match-related APIs.

5. **Simple, forward-only history pagination**

   - For v1, history will be:
     - Ordered by `created_at` descending or ascending (to be chosen per API ergonomics).
     - Limited by a `?limit=` query param; no complex cursor protocol yet.
   - Rationale: keeps the surface area small while still allowing clients to avoid loading unbounded histories.

## Risks / Trade-offs

- **Risk:** Messages are only scoped to 1:1 matches in v1.  
  → *Mitigation:* Clearly document this in the specs; design the `messages` capability so group chat can be layered on later without breaking the 1:1 contract.

- **Risk:** Simple pagination may not scale for very large histories.  
  → *Mitigation:* Start with a single `limit` parameter; if needed, add cursor-based pagination in a follow-up `messages-v2` change.

- **Risk:** Access control logic duplicated between WebSocket and HTTP paths.  
  → *Mitigation:* Keep the validation logic small and well-contained; consider extracting a shared helper or guard when more match-related endpoints are introduced.

- **Risk:** Message persistence is tightly coupled to the gateway implementation.  
  → *Mitigation:* Use a separate service/repository layer for message operations so that future non-WebSocket entry points (e.g., system messages, admin tools) can reuse the same persistence logic.

## Migration Plan

1. Implement message persistence and history behind the existing NestJS modules without changing external contracts used by other features.
2. Deploy to a dev environment with sample data and validate:
   - WebSocket `sendMessage` produces `messages` rows in the database.
   - `GET /matches/:matchId/messages` returns expected results and enforces access control.
3. Coordinate with the Flutter client to:
   - Start sending chat messages through the gateway knowing they are stored.
   - Use the new history endpoint to load messages when opening a conversation.
4. Monitor logs and database growth; adjust limits and indexing if needed.

Rollback is straightforward: revert the gateway and controller changes so messages become ephemeral again; no schema migrations are introduced in this change.

## Open Questions

- Should history responses use a standard response envelope (e.g., `{ success, data, error }`) or return raw arrays for simplicity?  
- What is the default `limit` for `GET /matches/:matchId/messages`, and should the client be able to request older messages via a cursor in v1 or defer this to a later change?  
- Should unauthorized access to a match’s messages return `403 Forbidden` (clear error) or `404 Not Found` (avoid leaking match existence) for this product’s threat model?


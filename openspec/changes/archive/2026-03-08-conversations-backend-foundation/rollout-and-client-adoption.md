## Rollout Plan – `conversations-backend-foundation`

This document captures the recommended steps to roll out the unified conversations
backend in staging/production and coordinate client adoption.

### 1. Migrations (staging and prod)

1. Ensure the backend image uses the updated Prisma schema (`backend/prisma/schema.prisma`).
2. In **staging**, run:
   - `cd backend`
   - `npx prisma migrate dev --name conversations-backend-foundation`
   - `npx prisma generate`
3. Run the backfill script:
   - `cd backend`
   - `node scripts/backfill-conversations.js`
4. Sanity checks:
   - Verify `conversations` and `conversation_participants` tables are populated.
   - Verify `messages.conversation_id` is non-null for existing messages.
   - Spot-check a few matches and confirm they each have an associated conversation.

### 2. Staging verification & rollback plan (Task 6.3)

In staging:

1. Exercise flows (friends + groups) to create new matches:
   - Confirm that new matches create or reuse conversations.
   - Confirm new messages are written with both `match_id` and `conversation_id`.
2. Validate new HTTP endpoints:
   - `GET /api/conversations` returns the expected inbox items.
   - `GET /api/conversations/:id/messages` returns correct history and respects access control.
3. Validate Socket.io behavior:
   - `joinMatch` returns `conversationId` and joins `conversation:<id>` internally.
   - New messages emit to `conversation:<id>` and legacy `match:<id>` rooms.

Rollback plan:

1. Before applying the migration in production, take a DB snapshot/backup.
2. If an issue is found post-deploy:
   - Temporarily disable the new conversations endpoints in the API gateway/router (if needed).
   - Roll the DB back to the pre-migration snapshot.
   - Redeploy the previous backend build.

### 3. Flutter client adoption (Task 6.4)

Phased approach:

1. **Phase 1 – Backend-only (current state)**
   - Backend emits to both `conversation:<id>` and `match:<id>` channels.
   - Existing Flutter client continues to:
     - Call `GET /matches/:matchId/messages`.
     - Use `joinMatch` / `sendMessage` / `typing` with `matchId`.
   - Conversations API is available but not yet used by the Flutter app.

2. **Phase 2 – Conversations-aware client**
   - Update Flutter to:
     - Introduce a conversations list feature calling `GET /api/conversations`.
     - Use the returned `conversationId` when opening chats.
     - Use `GET /api/conversations/:id/messages` for history instead of `/matches/:matchId/messages`.
   - Optionally update `ChatSocketClient` to:
     - Record `conversationId` from the `joinMatch` ack and/or use a dedicated `joinConversation` flow later.

3. **Phase 3 – Remove legacy match-based usage**
   - After the Flutter app is fully using:
     - `/api/conversations` + `/api/conversations/:id/messages`
     - `conversation:<id>` Socket.io channels
   - Remove:
     - Any remaining `/matches/:matchId/messages` dependencies in the client.
     - Legacy `match:<id>` channel emissions on the backend (in a follow-up change).


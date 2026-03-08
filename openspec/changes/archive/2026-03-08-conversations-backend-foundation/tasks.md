## 1. Conversations domain and schema

- [x] 1.1 Add `conversations` and `conversation_participants` tables to the Prisma schema (including type enum and timestamps).
- [x] 1.2 Add optional linkage from `conversations` to existing friend and group match entities (e.g., friend pairing and group match identifiers).
- [x] 1.3 Run database migrations to create the new tables and verify schema in a local environment.

## 2. Message model integration

- [x] 2.1 Add `conversation_id` to the messages schema and update Prisma models accordingly.
- [x] 2.2 Implement migration script to backfill `conversation_id` for existing friend chats and group match chats by creating conversations and linking messages.
- [x] 2.3 Update messaging repositories/services to use `conversation_id` as the primary foreign key for reads and writes.

## 3. Backend API endpoints

- [x] 3.1 Create a `ConversationsModule` in NestJS with controller and service.
- [x] 3.2 Implement `GET /conversations` endpoint to return a paginated list of conversations for the authenticated user, including metadata (type, participants summary, last message snippet/timestamp).
- [x] 3.3 Implement `GET /conversations/:id/messages` endpoint with cursor-based pagination scoped to a single conversation and participant access control.
- [x] 3.4 Update API validation (e.g., Zod or DTOs) and OpenAPI/swagger docs to include the new endpoints.

## 4. Socket.io real-time integration

- [x] 4.1 Update the Socket.io gateway to use `conversation:<id>` rooms and events for chat messages.
- [x] 4.2 Ensure that message creation emits real-time events to the appropriate `conversation:<id>` channel for all participants.
- [x] 4.3 (Optional) Maintain temporary compatibility with any existing `match:<id>` channels if needed, and document deprecation.

## 5. Friend and group flows wiring

- [x] 5.1 Update friend daily pairing logic to create or reuse a `conversation` for paired friends.
- [x] 5.2 Update group daily pairing logic to create or reuse a `conversation` for group matches, including temporary and permanent transitions.
- [x] 5.3 Ensure that all entry points that open chats (e.g., from daily questions or group screens) resolve to a `conversation_id` used by the new APIs and Socket.io channels.

## 6. Testing and rollout

- [x] 6.1 Add unit/integration tests for the conversations listing and message pagination endpoints.
- [x] 6.2 Add tests around Socket.io conversation channels to confirm correct event delivery and access control.
- [x] 6.3 Verify migration against a realistic dataset in staging and document a rollback plan.
- [x] 6.4 Coordinate with the Flutter app to adopt the new APIs and `conversation:<id>` channels, and plan removal of any legacy `match:<id>` usage.

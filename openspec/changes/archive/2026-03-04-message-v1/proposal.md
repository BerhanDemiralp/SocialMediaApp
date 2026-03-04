## Why

MOMENT already supports authenticated users, matches, and a real-time Socket.io gateway, but messages sent over the socket are not yet persisted or retrievable as history. This makes conversations ephemeral and prevents the app from showing past chats or reflecting message activity in the product’s core “Moment” flows.

## What Changes

- Add a first version of 1:1 match messaging:
  - Persist Socket.io `sendMessage` events into the `messages` table.
  - Emit `newMessage` with the stored DB record (real message ID and timestamps).
- Add an HTTP API for message history:
  - `GET /matches/:matchId/messages` to retrieve messages for a specific 1:1 match.
- Enforce access control on messaging:
  - Only users who are participants in a match (user_a or user_b) can send or read messages for that match.
- Keep the scope limited to plain text messages for 1:1 matches; no group chats or rich media in this change.

## Capabilities

### New Capabilities

- `messages`: Define how 1:1 match messages are stored, sent, and retrieved, including WebSocket events and HTTP history endpoints.

### Modified Capabilities

- `backend-api`: Extend the existing backend API capability to include a match message history endpoint and clarify access control around per-match message retrieval.

## Impact

- **Backend / NestJS**
  - Extend the existing Socket.io gateway to:
    - Validate that the sending user is part of the match.
    - Persist messages to the `messages` table via Prisma.
    - Emit `newMessage` with the stored record.
  - Add a new controller or route group for match message history under `/matches/:matchId/messages`.
- **Database / Prisma**
  - Reuse the existing `messages` table in `schema.prisma`; no schema changes expected for the first version.
- **Security / Access Control**
  - Enforce that only match participants can send or read messages tied to that match.
- **Clients**
  - Flutter app can:
    - Use the existing Socket.io connection to send messages that are now persisted.
    - Call the new history endpoint to load messages when opening a chat.


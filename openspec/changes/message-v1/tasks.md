## 1. WebSocket Message Persistence

- [ ] 1.1 Inject a message persistence service (or Prisma access) into `EventsGateway` to allow writing to the `messages` table.
- [ ] 1.2 In the `sendMessage` handler, validate that the authenticated socket user is a participant of the referenced match (user_a or user_b) before proceeding.
- [ ] 1.3 Persist valid messages to the `messages` table, then emit `newMessage` with the stored record (including DB `id` and `created_at`).
- [ ] 1.4 Return an appropriate WebSocket error and skip persistence when the user is not a participant in the match.

## 2. HTTP Message History API

- [ ] 2.1 Add a controller/route for `GET /matches/:matchId/messages` that uses the existing HTTP auth guard.
- [ ] 2.2 Implement access control so only match participants can retrieve messages for that match.
- [ ] 2.3 Query `messages` by `match_id`, ordered by `created_at`, and support a `limit` query parameter.

## 3. Tests and Verification

- [ ] 3.1 Add unit tests for the WebSocket `sendMessage` flow (success path and unauthorized match).
- [ ] 3.2 Add unit or integration tests for the `GET /matches/:matchId/messages` endpoint (authorized vs unauthorized callers).
- [ ] 3.3 Manually verify message persistence and history using the existing Socket.io test script and HTTP calls, including checking the `messages` table via Prisma or DB tools.


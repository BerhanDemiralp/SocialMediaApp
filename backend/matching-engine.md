# Matching Engine (Scheduled Pair Matching)

The matching engine is responsible for the “Moment” daily pairing ritual.

- Runs once per day at a configured app time (e.g., 17:00).
- Creates matches between users based on accepted friendships and active group memberships.
- Each match is active for 1 hour (`scheduled_at` → `expires_at`).
- After 1 hour:
  - A match is **successful** if total messages in that window ≥ 10 and each user sent ≥ 1 message.
  - Otherwise, the match is **expired**.
- Chats for expired matches remain visible in Messages.
- Friends matches are always permanent chats; group matches become permanent only if both users opt in, otherwise they remain read‑only history.

Key endpoints:

- `POST /api/matching-engine/run` – ops endpoint to trigger matching + evaluation.
- `GET /api/matching-engine/me/current` – get the current active Moment for the authenticated user.
- `GET /api/matching-engine/me/history` – list past matches for the authenticated user (paginated).
- `POST /api/matching-engine/:matchId/opt-in` – record opt-in for group matches.


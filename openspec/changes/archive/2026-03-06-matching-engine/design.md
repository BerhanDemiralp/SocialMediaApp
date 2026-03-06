## Context

MOMENT already has users, friendships, groups, messages, and a `matches` table, but the creation and lifecycle of “Moment” matches is not centralized. This design adds a dedicated matching engine that:

- Runs daily at a configured app time (e.g., 17:00).
- Creates matches based on friends and group memberships.
- Keeps matches active for 1 hour, during which conversation activity determines success.
- Expires matches after the window while keeping chats accessible.

The engine must support both Friends Daily Pairing and Group Daily Pairing with slightly different chat semantics.

## Goals / Non-Goals

**Goals:**
- Run a deterministic daily matching process at a fixed time.
- Enforce “one active match per user” and “one match per pair per day”.
- Track an explicit 1‑hour active window per match (`scheduled_at` → `expires_at`).
- Evaluate success based on messages within that window:
  - total messages ≥ 10 (combined),
  - each user sends ≥ 1 message.
- Support friends vs group match types with appropriate chat permanence rules.

**Non-Goals:**
- Implement advanced matchmaking algorithms (e.g., scoring, ML).
- Handle push notifications; those can be added later using the same match data.
- Change core friendship or group membership workflows beyond what’s needed for matching.

## Decisions

- **Module structure**
  - Create `MatchingEngineModule` with:
    - `MatchingEngineService` – core matching + evaluation logic.
    - `MatchingEngineRepository` – queries for users, friendships, groups, matches, and messages.
    - `MatchingEngineController` – ops endpoints (trigger run) and user endpoints (list matches, mark outcomes if needed).

- **Match schedule and window**
  - Store `scheduled_at` as the daily Moment time in UTC.
  - Compute `expires_at = scheduled_at + 1 hour`.
  - Treat matches as “active” when `status = 'active'` and `now` is between `scheduled_at` and `expires_at`.

- **Success evaluation**
  - After the 1‑hour window, evaluate each active match:
    - Count messages in the match’s chat with `created_at` between `scheduled_at` and `expires_at`.
    - Derive:
      - `totalMessages` = count of all messages in that window.
      - `messagesByUser` = number of messages per participant.
    - If `totalMessages >= 10` and both users have `messagesByUser >= 1`, mark status `successful`; otherwise mark `expired`.
  - Implement evaluation as:
    - Either part of the same job that runs after the window, or
    - A follow‑up job/endpoint that can be triggered shortly after expiry.

- **Friends vs groups behavior**
  - **Friends Daily Pairing**:
    - Source candidates from accepted friendships only.
    - Create a match with `match_type = 'friends'`.
    - The chat for a successful or expired friends match remains permanent and writable.
  - **Group Daily Pairing**:
    - Source candidates from active group memberships.
    - Create a match with `match_type = 'groups'`.
    - The chat starts as temporary; add an `opt_in` or equivalent flag for each participant:
      - If both opt in, promote chat to permanent writable after the window.
      - Otherwise, leave chat as read‑only history.

- **Time-based visibility**
  - “Current Moment” UI uses an endpoint that returns only matches where:
    - `status = 'active'` and `scheduled_at <= now < expires_at`.
  - Historical match list endpoints return matches with `status != 'active'` (and possibly completed active matches) regardless of time.

## Risks / Trade-offs

- **Clock skew & timing issues:** If job execution slips slightly past the scheduled time, some matches might be created or evaluated a few minutes late. This is acceptable for MVP; we can mitigate by using windowed queries and UTC times.
- **Fairness over time:** Simple random selection may repeatedly pick the same partners. This is a future improvement area; MVP will only guarantee constraints, not fairness.
- **Cross-module coupling:** Success evaluation depends on messages; tight coupling to the messages model must be kept simple and clearly documented so future refactors are easier.


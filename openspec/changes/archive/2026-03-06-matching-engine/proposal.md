## Why

MOMENT needs a concrete “Moment” matching system that turns the social graph into a daily ritual. Right now there is no engine that, at a fixed time, pairs users, enforces a 1‑hour active window, evaluates success based on conversation activity, and then cleanly expires matches while leaving chats accessible. This change makes scheduled pair matching a first‑class, well‑defined behavior instead of ad‑hoc logic.

## What Changes

- Introduce a scheduled pair matching engine that:
  - Runs once per day at a predefined app time (e.g., 5:00 PM).
  - Creates daily matches for users and marks them as active for exactly 1 hour from the scheduled time.
  - Enforces a success condition during that 1‑hour window:
    - total messages in the match chat ≥ 10 (combined), and
    - each user sends at least 1 message.
  - Automatically expires matches that fail the success condition after 1 hour, while keeping chats visible in Messages.
- Implement **two matching types**:
  - **Friends Daily Pairing** – one matched friend per day, chat is permanent and writable.
  - **Group Daily Pairing** – random group member pairing, with temporary chat that becomes permanent only if both users opt‑in; otherwise read‑only after the window.
- Add time‑based visibility rules so matches only appear as “active” during the 1‑hour window; outside that window, users can see past matches only in Messages/history, not as active Moments.
- Expose backend endpoints to:
  - Trigger the daily matching run (cron/ops entry point).
  - List my current active match (if any) and my past matches.
  - Mark match outcomes (successful/expired) where manual overrides are needed.

## Capabilities

### New Capabilities

- `matching-engine`:
  - Define the daily schedule, pairing logic, 1‑hour active window, and how matches transition between `active`, `successful`, and `expired` states.
- `matches-listing`:
  - Provide APIs to fetch a user’s current active match (within the 1‑hour window) and their historical matches, respecting the time‑based visibility rules.
- `match-outcomes`:
  - Define how and when matches become `successful` or `expired` based on message counts and participation, and how manual overrides work when needed.

### Modified Capabilities

- `friends-and-groups`:
  - Clarify that accepted friendships and active group memberships are used as the pool for scheduled pair matching.
  - Specify friends‑only behavior (one matched friend per day; permanent writable chat) and groups behavior (temporary chat, opt‑in to permanence, read‑only otherwise).

## Impact

- **Backend / APIs**
  - New NestJS module for the matching engine (controllers, services, repositories or reuse of existing ones).
  - New endpoints for triggering matching, listing matches, and marking outcomes.
  - Integration with the existing messages system to count messages during the 1‑hour window.
- **Database**
  - Confirm and, if needed, refine the `matches` table so it can represent:
    - match type (`friends`, `groups`),
    - `scheduled_at` and `expires_at` timestamps,
    - `status` (`active`, `successful`, `expired`),
    - any flags required for opt‑in state in group matches.
- **Scheduling / Ops**
  - Introduce a cron or job configuration (external or internal) to hit the matching engine at the configured daily time.
  - Ensure idempotent runs for a given day (no duplicate daily matches for the same users).
- **Client Integration**
  - Allow the frontend to show the current Moment only within the 1‑hour window and list previous matches elsewhere in the app.
  - Provide enough metadata for the UI to distinguish friends vs group matches, success vs expired, and temporary vs permanent chats.


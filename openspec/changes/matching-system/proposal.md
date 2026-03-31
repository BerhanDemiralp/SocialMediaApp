## Why

MOMENT currently has conversation and friends/group infrastructure but no actual system that schedules "Moment" pairings between users. Without scheduled pair matching, the core product promise of a once-a-day, time-boxed conversation ritual is missing, and there is no consistent trigger that nudges users into chats at the same time.

## What Changes

- Introduce a daily scheduled pair matching system ("Moment") that:
  - Runs once per day at a predefined app time (for example, 5:00 PM app time).
  - Pairs eligible users into matches and notifies both participants when their Moment starts.
  - Sends at most one reminder notification if users stay inactive during the active window.
- Define an active window model for matches:
  - Each match is considered active only for a 1-hour period after its scheduled start time.
  - Outside that window, the match is no longer treated as active in the "current Moment" view.
- Introduce explicit success vs. expiration semantics for matches:
  - A match is successful if, during the 1-hour window, there are at least 10 total messages in the associated chat and each participant sends at least 1 message.
  - If these criteria are not met by the end of the window, the match is marked as expired.
  - Regardless of outcome, the chat remains accessible in Messages after the window.
- Keep matching chats behaviorally identical to normal conversations:
  - Matching always creates or reuses a standard conversation using the existing unified conversations model.
  - There is no separate "special match chat" type; once created, these conversations behave like any other friend or group chat in messaging surfaces.
- Add two matching modes that only influence who gets paired, not how chat works:
  - Friends Daily Pairing:
    - Once per day, pair a user with one existing friend (if available).
    - The underlying conversation is just a normal friend conversation that remains permanent and writable, even after the 1-hour window ends.
  - Group Daily Pairing:
    - Pair a user with a random member from one of their groups.
    - The underlying conversation is a standard conversation between those users; any opt-in/out behavior is stored as match or conversation metadata but does not change basic chat mechanics.
- Enforce time-based visibility rules at the match level, not at the chat level:
  - Matches only appear as "active Moments" during their active 1-hour window.
  - Users cannot initiate new Moment matches outside the scheduled time.
  - Past matches remain visible via Messages and match history but are clearly shown as non-active Moments, even though their conversations continue to behave like normal chats.

## Capabilities

### New Capabilities

- `matching-system`: Defines the scheduled pair matching engine for MOMENT, including daily schedule, active period, success/expiration rules, and match-level visibility (without introducing a separate chat type).
- `moment-matching-types`: Specifies how Friends Daily Pairing and Group Daily Pairing behave in terms of pairing logic and metadata, while reusing the existing unified conversations model for all chats.

### Modified Capabilities

- *(None yet.)* This proposal introduces a dedicated matching system. Follow-up changes may extend existing backend API and conversations specs to surface current Moment and history views, but those requirement changes will be captured in separate delta specs.

## Impact

- **Backend / Database**
  - (Re)introduce or adapt persistence for matches and their status/metrics (scheduled_at, expires_at, status, mode, links to conversations and participants).
  - Add a matching engine component responsible for the daily run, success evaluation, and updating match status.
  - Extend backend APIs to expose current active Moment and match history; group pairing opt-in/out, if needed, is modeled as metadata rather than a separate chat type.
- **Real-time & Notifications**
  - Hook the matching system into real-time and notification infrastructure so that:
    - Users are notified when a Moment starts.
    - A single reminder can be delivered during the 1-hour window if users are inactive.
- **Conversations & Chat**
  - Ensure matches are consistently linked to standard conversations so that:
    - Chats created by matching show up in existing Messaging surfaces exactly like other conversations.
    - Successful vs. expired matches are reflected only in metadata or Moment views, without changing how sending/reading messages works.
- **Frontend / Flutter**
  - Add or extend UI surfaces for:
    - Showing the current active Moment (or indicating that there is none).
    - Displaying match metadata (for example, successful vs. expired) alongside otherwise normal chat threads.
    - Surfacing past Moments in a way that fits the existing Messages experience.


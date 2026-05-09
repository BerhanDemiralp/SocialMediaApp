## Context

The proposal defines Scheduled Pair Matching ("Moment") as a daily ritual: users are paired at a predefined time, notified, given a 1-hour active window, and then marked successful or expired based on message activity. Friend pairings become permanent writable chats automatically. Group pairings start temporary and become permanent writable only when both participants opt in; otherwise the history remains accessible but read-only.

The current backend already has modules for auth, friends, groups, conversations, messages through conversation APIs, events, Prisma, and Supabase. `AppModule` does not currently register a matching lifecycle module. The current Prisma schema stores users, friendships, groups, group members, conversations, conversation participants, and conversation-scoped messages, but it does not store daily Moment lifecycle state such as scheduled time, expiration, success, reminder delivery, or group opt-in.

The design should therefore add Moment lifecycle as a new product capability while reusing the existing conversation model for chat history and real-time messaging.

## Goals / Non-Goals

**Goals:**

- Create daily Moment pairings at a configured app time.
- Allow each user to have up to two daily active Moments: one friend Moment and one group Moment.
- Support friend daily pairing from accepted friendships.
- Prevent the same friend pair from being matched again until 1 week has passed.
- Support group daily pairing from group members who are not friends.
- Notify both participants when a Moment starts and send one inactivity reminder.
- Keep each Moment active for 1 hour from `scheduled_at`.
- Mark a Moment successful only when the 1-hour window has at least 10 combined messages and each participant sends at least one message.
- Expire Moments that do not meet the success condition while keeping their chat visible in Messages.
- Keep friend Moment conversations permanent and writable automatically.
- Keep group Moment conversations temporary until mutual opt-in, then make them permanent writable; otherwise make them read-only history.
- Expose active pairings for Home and lifecycle/history state for Messages.

**Non-Goals:**

- Adaptive match times.
- Algorithmic compatibility scoring.
- Public group discovery.
- More than one friend Moment and one group Moment for the same user on the same day.
- Media-rich messaging changes.
- Dating-style ranking, swiping, or popularity mechanics.

## Decisions

### Add a dedicated Moment lifecycle module

Add a backend module, for example `MatchingEngineModule` or `MomentsModule`, that owns scheduled pair creation, current active match lookup, expiration evaluation, reminder decisions, and group opt-in.

Rationale: Moment behavior crosses friends, groups, conversations, messages, notifications, and Home. Keeping lifecycle rules in one module prevents friend/group/chat services from each owning part of the state machine.

Alternative considered: implement matching inside `ConversationsModule`. Conversations are the durable chat container, but they do not represent daily scheduling, reminders, success evaluation, or opt-in state.

### Store Moment records separately from conversations

Add a Moment match table that links two participants to one conversation and stores lifecycle fields:

- match type: friend or group
- optional group id for group pairings
- participant ids
- conversation id
- scheduled_at and expires_at
- status: active, successful, expired
- reminder state
- per-participant group opt-in state
- created_at and updated_at

Rationale: a Moment is a time-boxed event, while a conversation is long-lived history. Separate records allow repeated friend Moments to reuse the same direct conversation without losing per-day lifecycle history.

Alternative considered: put Moment fields directly on conversations. That makes permanent friend conversations carry temporary daily state and does not handle repeated daily pairings cleanly.

### Reuse conversation-scoped messaging

Moment chats should use existing `conversations`, `conversation_participants`, and `messages` records. Friend Moments find or create a `friend` conversation between the users. Group Moments create a `group_pair` conversation for the matched users and group context.

Rationale: the app already treats conversations as the canonical chat surface. Reusing it keeps message history, pagination, and real-time delivery consistent across normal chats and Moment chats.

Alternative considered: create separate match-scoped messages. That would duplicate chat behavior and make Messages need two history models.

### Make scheduling idempotent and retry-safe

The daily pairing run should be safe to retry. It should calculate the schedule window, allow at most one active friend Moment and one active group Moment per user for that scheduled day, and avoid duplicate pairs for the same scheduled day. Database constraints and service-level checks should both protect this rule.

Rationale: schedulers, deployments, and manual operations can repeat a run. Duplicate active pairings would break the Home experience and the daily one-per-type matching rule.

Alternative considered: rely on the scheduler to run exactly once. That is brittle and makes recovery harder.

### Pair users once per type per day

Each user can have two active Moments in one day: one friend Moment and one group Moment. The friend Moment is selected from accepted friends. The group Moment is selected from eligible group members who are not already friends.

Rationale: friend maintenance and group discovery serve different product purposes, so allowing both rituals in the same day supports the proposal without forcing the system to choose one social mode.

Alternative considered: keep a single active Moment across all types. That would simplify scheduling, but it would make friend maintenance and group discovery compete with each other.

### Apply a 1-week friend rematch cooldown

Friend candidate selection should exclude any friend pair that has already been matched in the last 7 days. After 1 week has passed, the pair becomes eligible again.

Rationale: this prevents the same friendship from being repeatedly selected while still allowing recurring friend Moments often enough to maintain relationships.

Alternative considered: never repeat friend matches. That would fail for users with small friend lists and would eventually exhaust eligible pairs.

### Keep MVP candidate selection simple

Friend pairing selects from accepted friendships that are outside the 1-week rematch cooldown. Group pairing selects from shared group members who are not friends and do not already have a group Moment for the scheduled day. The first implementation can randomize eligible candidates without scoring.

Rationale: the MVP explicitly avoids algorithmic matching. Random eligible pairing supports low-pressure discovery while keeping behavior explainable.

Alternative considered: rank by activity, mutual interests, or past behavior. That adds product and moderation complexity outside this change.

### Use backend write authorization for temporary and read-only states

The backend must be authoritative for whether a participant can send a message. Friend Moment conversations remain writable. Group Moment conversations are writable during the active window; after the window, they are writable only if both participants opted in. If not, messages remain readable but new sends are rejected.

Rationale: frontend read-only UI can improve UX, but only backend validation can reliably enforce the group discovery safety rule.

Alternative considered: handle read-only state only in Flutter. That would be easy to bypass and would create inconsistent behavior across clients.

### Evaluate success from persisted messages

Expiration evaluation should count persisted, non-deleted messages in the linked conversation between `scheduled_at` and `expires_at`. The status becomes successful only if total messages are at least 10 and both participants contributed at least one message.

Rationale: persisted messages are the source of truth and survive socket retries, reconnects, and app restarts.

Alternative considered: maintain counters on the Moment row during each send. Counters can be added later for optimization, but they need reconciliation logic.

### Surface Moment state separately from generic conversation lists

Home should call a Moment-focused endpoint for active pairings. Since a user can have both a friend Moment and a group Moment on the same day, the response should support returning both active Moment cards. Messages can continue to list conversations, but conversation responses should include enough state to render group pair conversations as writable or read-only.

Rationale: Home needs active ritual state, schedule, expiration, type, and participant details for one or two daily pairings. Messages needs durable chat state. Separate response shapes keep both surfaces clear.

Alternative considered: make Home infer active Moment state from the conversation list. That couples Home to chat history and makes scheduling state harder to present accurately.

## Risks / Trade-offs

- Duplicate active matches -> mitigate with database constraints and transactional checks before creating Moment rows.
- Race conditions during pairing -> process eligible users in a deterministic order and re-check active match state inside the transaction.
- Friend pools can be exhausted by the 1-week cooldown -> skip the friend Moment for that user on that day rather than violating cooldown rules.
- Two daily Moments can crowd Home -> render friend and group Moments as distinct compact cards with clear type labels and shared expiration timing.
- Expiration scans become slow -> index Moment status/expires_at and messages by conversation_id/created_at.
- Time zone confusion -> store timestamps in UTC and define one configured app ritual time for MVP.
- Reminder timing is ambiguous -> store reminder_sent_at and make the reminder rule explicit in specs before implementation.
- Push notification delivery can fail -> persist Moment state so Home remains the source of truth even when notification delivery is unreliable.
- Group read-only state can drift -> enforce write permission in backend message send paths, with frontend state treated as presentation only.

## Migration Plan

1. Add Prisma enums or constrained values for Moment type and status.
2. Add a Moment match table with participant, group, conversation, schedule, expiration, reminder, and opt-in fields.
3. Add indexes for active participant lookup by match type, scheduled day uniqueness by participant/type, friend rematch cooldown lookup, expiration scans, and match history.
4. Generate and validate Prisma client changes.
5. Implement the Moment lifecycle module and register it in `AppModule`.
6. Add authenticated APIs for current active Moment, match history, and group opt-in.
7. Add scheduler or ops-triggered entrypoint for daily pairing, reminder checks, and expiration evaluation.
8. Update conversation/message write authorization for group pair read-only behavior.
9. Add Flutter Home support for up to two active pairings and Flutter Messages support for writable/read-only state.

Rollback strategy: disable the scheduler or ops trigger first, hide the Home active Moment UI, and leave existing conversations/messages intact. Moment lifecycle rows can remain as historical records until a cleanup migration is needed.

## Open Questions

- What exact daily time and time zone should be used for MVP?
- When exactly should the inactivity reminder be sent during the 1-hour window?
- What counts as inactive for reminder delivery: no messages from either user, or one participant has not sent a message?
- Does a successful group Moment still require mutual opt-in for permanence, or does success imply permanence?
- Should group pair eligibility require an explicit user availability setting?

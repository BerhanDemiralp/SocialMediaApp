## 1. Shared Infrastructure

- [x] 1.1 Add Moment match type/status/opt-in enums or constrained values to the Prisma schema.
- [x] 1.2 Add the Moment match lifecycle table with participant ids, optional group id, conversation id, scheduled_at, expires_at, status, reminder state, opt-in fields, created_at, and updated_at.
- [x] 1.3 Add database indexes and constraints for participant/type/day uniqueness, active participant lookup, expiration scans, match history, and 7-day friend rematch lookup.
- [x] 1.4 Generate and validate the Prisma client after schema changes.
- [x] 1.5 Create the backend Moment lifecycle module structure and register it in `AppModule`.
- [x] 1.6 Add repository methods for creating matches, finding active matches by participant/type, listing history, finding expired active matches, checking recent friend pairings, and updating status/reminder/opt-in state.
- [x] 1.7 Add shared Moment DTOs/serializers that return match id, match type, participant summary, conversation id, scheduled_at, expires_at, status, and writable state.
- [x] 1.8 Add an injectable notification abstraction for match-start and reminder events without coupling lifecycle logic directly to FCM/APNS implementation details.
- [x] 1.9 Add tests for Moment lifecycle persistence, uniqueness rules, status updates, and repository lookup behavior.

## 2. Scheduling And Lifecycle

- [x] 2.1 Implement configured daily schedule window calculation with UTC persisted timestamps and 1-hour expiration.
- [x] 2.2 Implement an idempotent Moment run service that can be safely retried for the same scheduled window.
- [x] 2.3 Enforce the daily limit of one friend Moment and one group Moment per user.
- [x] 2.4 Implement match-start notification dispatch for both participants when a Moment is created.
- [x] 2.5 Implement inactivity reminder evaluation with persisted reminder_sent state so only one reminder can be sent per Moment.
- [x] 2.6 Implement expiration evaluation that counts non-deleted messages in the linked conversation between scheduled_at and expires_at.
- [x] 2.7 Mark Moments successful only when message count is at least 10 and both participants sent at least one message.
- [x] 2.8 Mark Moments expired when the success condition is not met and keep linked conversations visible in Messages.
- [x] 2.9 Add tests for idempotent runs, per-type daily limits, reminder behavior, success evaluation, and expiration behavior.

## 3. API Surface

- [x] 3.1 Add an authenticated current Moment endpoint that returns zero, one, or two active Moments for the current user.
- [x] 3.2 Add a paginated authenticated Moment history endpoint scoped to the current user.
- [x] 3.3 Add a protected operational endpoint or job entrypoint for triggering due pairing, reminder, and expiration work.
- [x] 3.4 Add API authorization checks so users can only see Moment records where they are participants.
- [x] 3.5 Add controller/service tests for current Moment, history, operational run authorization, and retry-safe run behavior.

## 4. Friend Matching

- [x] 4.1 Implement accepted-friend candidate retrieval for users who do not already have a friend Moment for the scheduled day.
- [x] 4.2 Exclude friend pairs matched in a friend Moment during the previous 7 days.
- [x] 4.3 Allow friend pairs to become eligible again after the 7-day cooldown has passed.
- [x] 4.4 Implement friend pairing selection for one friend Moment per eligible user per day.
- [x] 4.5 Create or reuse the permanent writable `friend` conversation when a friend Moment is created.
- [x] 4.6 Persist friend Moment records linked to the reused or newly created friend conversation.
- [x] 4.7 Add friend matching tests for accepted friendship eligibility, same-day duplicate prevention, 7-day cooldown exclusion, cooldown re-eligibility, and conversation reuse.

## 5. Group Matching

- [x] 5.1 Implement shared-group candidate retrieval for users who do not already have a group Moment for the scheduled day.
- [x] 5.2 Exclude accepted friends from group Moment candidate pairs even when they share a group.
- [x] 5.3 Implement group pairing selection for one group Moment per eligible user per day.
- [x] 5.4 Create a temporary `group_pair` conversation when a group Moment is created.
- [x] 5.5 Persist group Moment records linked to the shared group and temporary group-pair conversation.
- [x] 5.6 Add a group Moment opt-in endpoint that records participant opt-in state and rejects non-participants.
- [x] 5.7 Make group-pair conversations permanently writable only after both participants opt in.
- [x] 5.8 Add group matching tests for non-friend eligibility, friend exclusion, same-day duplicate prevention, temporary conversation creation, opt-in authorization, and mutual opt-in permanence.

## 6. Messaging Integration

- [x] 6.1 Update message send authorization to detect conversations linked to active or expired Moment records.
- [x] 6.2 Keep friend Moment conversations writable after the active window.
- [x] 6.3 Keep active group Moment conversations writable during the 1-hour window.
- [x] 6.4 Reject new messages in expired group Moment conversations when both participants have not opted in.
- [x] 6.5 Include writable/read-only state in conversation or message history responses for Moment-linked conversations.
- [x] 6.6 Add messaging tests for friend Moment writes, active group Moment writes, read-only expired group Moment rejection, and expired Moment history access.

## 7. Flutter Integration

- [x] 7.1 Add Flutter data models and API client methods for current Moment, Moment history, and group Moment opt-in.
- [x] 7.2 Add repository/controller state for up to two active Home pairings: one friend Moment and one group Moment.
- [x] 7.3 Update Home to render active friend and group Moment cards with type, participant summary, expiration timing, and open-chat action.
- [x] 7.4 Update chat or Messages state to render read-only group Moment conversations after expiration without mutual opt-in.
- [x] 7.5 Add UI handling for group Moment opt-in and permanent writable transition after both users opt in.
- [x] 7.6 Add Flutter tests for Home active pairings, chat writable/read-only state, and opt-in state transitions.

## 8. End-To-End Verification

- [x] 8.1 Add backend integration tests covering a full daily run with one friend Moment and one group Moment for an eligible user.
- [x] 8.2 Add backend integration tests covering retrying the same run without duplicate same-type Moment creation.
- [x] 8.3 Add backend integration tests covering friend rematch cooldown and re-eligibility after 7 days.
- [x] 8.4 Add backend integration tests covering group match expiration with and without mutual opt-in.
- [x] 8.5 Run Prisma validation and backend test suite.
- [ ] 8.6 Run Flutter analyze and relevant Flutter tests.
- [ ] 8.7 Manually verify Home shows active pairings and Messages preserves expired conversation history.

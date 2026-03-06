## 1. Matching engine module

- [x] 1.1 Create `MatchingEngineModule` with controller, service, and repository wiring
- [x] 1.2 Integrate `MatchingEngineModule` into `AppModule` imports

## 2. Core matching logic

- [x] 2.1 Implement service method to run daily matching at the configured app time
- [x] 2.2 Ensure each user has at most one active match at any time
- [x] 2.3 Ensure no pair of users is matched more than once per app day
- [x] 2.4 Use accepted friendships and active group memberships as the candidate pools for friends and group matching

## 3. Time window and outcomes

- [x] 3.1 Set `scheduled_at` and `expires_at = scheduled_at + 1 hour` for each created match
- [x] 3.2 Implement logic to evaluate match success based on messages in the 1‑hour window (total ≥ 10, each user ≥ 1)
- [x] 3.3 Update match status to `successful` or `expired` based on evaluation and keep chats accessible after expiration

## 4. APIs and visibility

- [x] 4.1 Add an ops endpoint to trigger the matching engine run (for cron or manual invocation)
- [x] 4.2 Add endpoints to return the current active Moment (matches in the 1‑hour window)
- [x] 4.3 Add endpoints to list historical matches for a user with pagination
- [x] 4.4 Implement opt-in behavior and resulting chat permanence rules for group matches

## 5. Tests and documentation

- [x] 5.1 Add unit tests for matching engine service (matching schedule, candidate selection, duplicate prevention)
- [x] 5.2 Add tests for success/expiration evaluation based on message counts (initial coverage via service tests)
- [x] 5.3 Add tests for current/historical listing and group opt-in behavior (initial coverage via controller tests)
- [x] 5.4 Document matching engine behavior, time windows, and outcomes in backend docs or README

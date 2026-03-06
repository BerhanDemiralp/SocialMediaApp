## 1. Backend module & schema

- [x] 1.1 Create `DailyQuestionsModule` with controller, service, and repository skeletons
- [x] 1.2 Add Prisma models and migrations for `daily_questions` and `user_answers`
- [x] 1.3 Add database indexes and unique constraints (e.g., unique active_date per question, (question_id, user_id))

## 2. Admin APIs for daily questions

- [x] 2.1 Implement admin endpoint to create a daily question with validation for active date uniqueness
- [x] 2.2 Implement admin endpoint to list existing and upcoming daily questions with pagination
- [x] 2.3 Wire admin endpoints to authorization (admin role or allowlist) and add request/response validation

## 3. User APIs for answering

- [x] 3.1 Implement endpoint to fetch today’s daily question for the current app day
- [x] 3.2 Implement endpoint for users to submit or overwrite an answer for today’s question (upsert behavior)
- [x] 3.3 Implement endpoint to list a user’s historical daily-question answers with pagination
- [x] 3.4 Add Zod schemas and error handling for all user-facing daily-question endpoints

## 4. Friends’ answers feed

- [x] 4.1 Add repository/query to fetch answers for a question filtered by the requester’s confirmed friends
- [x] 4.2 Implement endpoint to return today’s friends’ answers in a card-friendly shape (user identity, snippet, timestamp)
- [x] 4.3 Ensure non-friend answers are excluded from the friends’ answers response

## 5. Integration, testing, and ops

- [x] 5.1 Add unit and/or integration tests for daily questions admin and user endpoints
- [x] 5.2 Add tests covering overwrite behavior and uniqueness constraints for daily questions and user answers
- [x] 5.3 Document daily-questions module usage and any configuration (e.g., app timezone) in backend docs or README

## Why

MOMENT needs a simple, reliable “question of the day” ritual to give the app a daily heartbeat and a clear reason to open it. Right now there’s no structured way to deliver a shared prompt, collect answers, and surface friends’ responses, which limits both engagement and opportunities for meaningful conversation.

## What Changes

- Add backend support for managing daily questions (`daily_questions` table + service).
- Add admin-ish endpoints to:
  - Create and schedule daily questions.
  - List existing and upcoming questions.
- Add user-facing endpoints to:
  - Get today’s active question for the current user.
  - Submit an answer to today’s question (writes to `user_answers`).
  - List my past answers (paginated).
- Add simple “friends’ answers” listing endpoint (stubbed for now, assuming existing friendship graph), returning:
  - Only friends who have answered today’s question.
  - Minimal payload suitable for cards in the client.
- Define basic validation and constraints (one active question per day, per timezone strategy TBD; answer length limits, idempotent submits).

## Capabilities

### New Capabilities

- `daily-question-admin`:
  - Manage creation, scheduling, and lifecycle of daily questions, including constraints such as uniqueness per day and visibility rules.
- `daily-question-answering`:
  - Allow authenticated users to fetch today’s question, submit an answer exactly once (or with well-defined overwrite behavior), and view their own historical answers.
- `daily-question-friends-feed`:
  - Expose an API to list friends’ answers for the current day’s question, suitable for rendering cards, without exposing non-friend data.

### Modified Capabilities

- `friend-graph`:
  - Clarify that the friend relationship can be used as a filter for which answers appear in the daily-questions friends feed (read-only usage; no changes to how friendships are created).
  
## Impact

- **Backend / APIs**
  - New NestJS module(s) for daily questions and answers (controllers, services, repositories).
  - New REST endpoints (and/or GraphQL operations if applicable) for admin and user daily-question flows.
  - Input validation schemas (Zod) for create-question and answer-submission payloads.
- **Database**
  - New `daily_questions` table (id, question text, active date(s), metadata).
  - New `user_answers` table (id, user_id, question_id, answer text, timestamps, possibly visibility flags).
  - Indexes tuned for “today’s question” lookup and listing friends’ answers.
- **Auth & Permissions**
  - Admin-only access for question creation endpoints.
  - Authenticated user access for fetching today’s question, submitting answers, and listing answers.
- **Future Work (out of scope here but enabled by this)**
  - Push notifications when a new daily question goes live.
  - Integration with matching / chat flows triggered from friends’ answer cards.


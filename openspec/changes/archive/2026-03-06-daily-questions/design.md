## Context

The daily-questions feature introduces a core product ritual that touches backend APIs, database schema, and the friend graph, but is still fairly self-contained. Today there is no structured way to create a daily global prompt, ensure a single active question per day, collect user answers, or expose friends’ answers in a way the client can easily consume.

The implementation will live entirely in the existing NestJS backend as a new module, using PostgreSQL + Prisma for persistence and Supabase Auth user IDs for ownership. It should not introduce any breaking changes for existing modules and should be safe to deploy alongside the current production backend.

## Goals / Non-Goals

**Goals:**
- Provide APIs for creating and scheduling daily questions.
- Ensure there is at most one active question per day (per configured “day” definition).
- Allow users to fetch today’s question, submit an answer, and list their own historical answers.
- Provide a minimal “friends’ answers” listing API suitable for card-style UI, using the existing friend graph.

**Non-Goals:**
- Implement push notifications or reminders for daily questions.
- Build rich media answers (text-only for now).
- Implement sophisticated time zone handling beyond a simple “app day” definition.
- Implement any matching or chat flows; replies from answer cards remain out of scope for this design.

## Decisions

- **New NestJS module:** Create a `DailyQuestionsModule` with separate controller(s), service(s), and repository layer. This keeps concerns isolated and makes it easier to evolve without touching unrelated modules.
- **Database schema:** Introduce `daily_questions` and `user_answers` tables:
  - `daily_questions`: `id`, `question_text`, `active_date` (or `active_at`), `created_by`, `created_at`, `updated_at`, and optional fields like `tags` or `visibility`. A unique index on `active_date` guarantees at most one question per app day.
  - `user_answers`: `id`, `user_id`, `question_id`, `answer_text`, `created_at`, `updated_at`, plus soft-delete or visibility flags if needed. Index on `(question_id, user_id)` to enforce one active answer per user per question.
- **Answer overwrite behavior:** Allow users to resubmit answers; the latest answer overwrites the previous one for a given `(question_id, user_id)` pair. This is implemented via an upsert in Prisma.
- **Admin endpoints:** Expose admin-only HTTP endpoints to create and list daily questions. Authorization will rely on an existing “admin” role or a configurable list of admin user IDs.
- **User endpoints:** Expose user endpoints to get today’s question, submit an answer, and list own answers. These endpoints require authenticated users via Supabase Auth.
- **Friends’ answers feed:** Implement a query that fetches answers for a given question ID, filtered by the current user’s friends (using the existing friend graph table or friendship service), returning a small payload (user, answer snippet, timestamp).
- **App day definition:** For the first version, define “today” using a single canonical timezone (e.g., UTC or a configured app timezone) rather than per-user local time. This keeps the data model simple and avoids partial-overlap questions.

## Risks / Trade-offs

- **Time zone simplification:** Using a single app-level timezone means “today’s” question may not align perfectly with local midnight for all users. This simplifies implementation now but may require a migration later if per-user local days are needed.
- **Admin surface area:** Admin endpoints increase the surface area for misconfiguration (e.g., creating multiple questions with conflicting active dates before validation). Strong validation and DB uniqueness constraints will mitigate this.
- **Friend graph dependency:** The friends’ answers feed depends on an existing, reliable friend graph. If that data is incomplete or inconsistent, users may see fewer answers than expected.
- **Future extensibility:** The initial schema is text-focused. If we later support rich media answers, we may need to add related tables or storage links, which could complicate queries.


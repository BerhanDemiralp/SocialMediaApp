## Conversations API (Unified Inbox)

This document describes the unified conversations endpoints implemented by the
`ConversationsModule` in the NestJS backend.

All routes are prefixed with `/api` by the global prefix configured in `main.ts`.

### `GET /api/conversations`

- **Auth:** required (`AuthGuard`).
- **Description:** Returns a paginated list of conversations for the authenticated user.
- **Query params** (validated via DTO + global `ValidationPipe`):
  - `limit?: number` – optional page size (default `20`, must be `>= 1`).
  - `cursor?: string` – optional cursor (the `id` of the last conversation from the previous page).
- **Response shape:**
  - `items: Array<{ id, type, title | null, participants: Array<{ id, username, avatar_url | null }>, lastMessage: { id, content, created_at } | null }>`
  - `nextCursor: string | null`

### `GET /api/conversations/:id/messages`

- **Auth:** required (`AuthGuard`).
- **Access control:** caller must be a participant in the conversation; otherwise a `403` is returned.
- **Description:** Returns paginated messages for a specific conversation, ordered by `created_at` descending.
- **Query params** (validated via DTO + global `ValidationPipe`):
  - `limit?: number` – optional page size (default `50`, must be `>= 1`).
  - `cursor?: string` – optional cursor (the `id` of the last message from the previous page).
- **Response shape:**
  - `items: Array<Prisma.messages>` – messages for that conversation.
  - `nextCursor: string | null`

These endpoints are backed by `ConversationsService` (`backend/src/conversations/conversations.service.ts`)
and use the `conversations`, `conversation_participants`, and `messages` Prisma models.


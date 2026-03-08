## Context

Today, friend chats and group match chats are modeled separately, with message flows scoped to matches and ad-hoc concepts in the backend. This makes it harder to build a unified inbox, evolve messaging behavior consistently, and introduce new conversation types. The Flutter client also has to know whether a chat is a friend chat or group match chat in order to wire up the correct APIs and Socket.io channels (e.g., `match:<id>`), which complicates the UI layer.

This change introduces a unified conversations domain in the NestJS backend that represents any 1:1 or small-group chat as a `conversation`, regardless of whether it originated from a friend pairing or a group match. Messages become scoped to `conversation_id`, and real-time events are keyed off `conversation:<id>` channels. The design assumes the existing tech stack: NestJS modules/controllers/services, Prisma/PostgreSQL, and Socket.io gateways.

## Goals / Non-Goals

**Goals:**
- Provide a unified conversations data model that can represent friend chats and group match chats.
- Expose backend APIs to list a user's conversations (for inbox views) with metadata such as last message, unread counts (if available), and conversation context (friend vs group).
- Expose backend APIs to fetch paginated messages for a given conversation in a consistent way.
- Migrate real-time events to `conversation:<id>` channels while keeping the initial migration minimal and safe.
- Keep the design extensible for future conversation types (e.g., mini-game chats) without needing another schema rewrite.

**Non-Goals:**
- Overhauling the entire matching engine or daily question flows.
- Redesigning the Flutter chat UI; this change focuses on backend foundation and API contracts.
- Implementing advanced messaging features such as reactions, rich media, or read receipts.
- Defining the full notifications strategy; we only ensure the APIs support what notifications will need.

## Decisions

1. **Core Conversation Entity**
   - Introduce a `conversations` table with fields like:
     - `id` (UUID, primary key)
     - `type` (enum: `friend`, `group_pair`, potentially `group_room`, `system`, etc.)
     - `title`/`display_name` (nullable; used mainly for group-derived conversations)
     - `created_at`, `updated_at`
   - Represent who participates via a `conversation_participants` join table:
     - `conversation_id` (FK to `conversations`)
     - `user_id` (FK to `users`)
     - role/metadata fields (e.g., is_muted, joined_at)
   - Rationale: This keeps the `conversation` concept generic and lets friend and group match flows attach metadata without diverging schemas.

2. **Linking to Existing Domain Objects**
   - Add optional linkages from conversations to their origin entities:
     - For friend chats: `friend_pair_id` references existing friend pairing or a simple composite of user IDs.
     - For group match chats: `group_match_id` references the match that produced the conversation.
   - These links can be modeled via optional columns on `conversations` (e.g., `friend_match_id`, `group_match_id`) or via a small `conversation_origins` table.
   - Rationale: Keeps matching logic localized while exposing a simple unified conversation model to the messaging layer.

3. **Messages Scoped by Conversation**
   - Update the `messages` schema to include `conversation_id` as the primary foreign key instead of (or in addition to) `match_id` fields.
   - For migration, we can backfill `conversation_id` for existing messages by creating conversations for each existing friend and group match and assigning messages accordingly.
   - Rationale: All message queries (history, pagination, counts) become conversation-centric and do not need to know about the original match type.

4. **APIs for Listing Conversations**
   - Add an authenticated endpoint such as `GET /conversations` that:
     - Identifies the current user via auth.
     - Joins `conversations` with `conversation_participants` and `messages` to return:
       - `conversation_id`, `type`, `title`
       - participants summary (e.g., counterpart user in friend chats, group name for group matches)
       - last message snippet and timestamp
       - optional unread count
     - Supports pagination (e.g., `cursor` + `limit` or `page` + `pageSize`).
   - Rationale: The Flutter client can render a unified inbox without needing separate friend vs group calls.

5. **APIs for Paginated Messages**
   - Add endpoint such as `GET /conversations/:id/messages` that:
     - Verifies that the current user is a participant in the conversation.
     - Returns messages ordered by timestamp, with a cursor-based pagination scheme.
     - Optionally supports a `before`/`after` cursor for infinite scroll.
   - Rationale: A single API surface can serve all conversation types.

6. **Socket.io Channel Naming**
   - Standardize all real-time chat events on `conversation:<id>` rooms.
   - On message send/receive, the gateway emits events like `message:new` to `conversation:<id>`.
   - The client joins/leaves `conversation:<id>` rooms when opening/closing chats.
   - For backward compatibility, we can optionally keep emitting to legacy `match:<id>` rooms for a short transition window but mark them as deprecated.

7. **NestJS Modularization**
   - Introduce a `ConversationsModule` that owns:
     - `ConversationsController` for HTTP endpoints.
     - `ConversationsService` for domain logic (creating conversations, listing, validating participant access).
     - Integration with existing `MessagesService` and matching modules.
   - Rationale: Keeps the new domain boundary clear and makes future extensions (e.g., archiving, muting, notification hooks) easier.

## Risks / Trade-offs

- **Migration Complexity**: Backfilling `conversation_id` for existing matches and messages introduces migration risk. Mitigation: write idempotent migration scripts, deploy behind a feature flag, and validate with staging data before production.
- **Temporary Duplication of Fields**: During rollout we may have both `match_id` and `conversation_id` fields in the messages schema. Mitigation: keep the implementation paths well-labeled, and plan a follow-up cleanup once all consumers use conversations.
- **Performance of Conversation List Queries**: Joining conversations, participants, and messages to produce an inbox view may be heavier than existing endpoints. Mitigation: add targeted indexes (e.g., on `conversation_participants.user_id`, message timestamps) and consider pre-computed last message via denormalized columns if needed.
- **Coupling to Existing Match Logic**: Linking conversations to legacy match objects can leak matching concerns into the conversations layer. Mitigation: keep match-related logic in the matching modules and expose only the minimal fields needed for conversations.
- **Client Transition Cost**: Flutter clients must update to the new APIs and Socket.io channels. Mitigation: design the conversation list and messages endpoints to be additive, keep legacy endpoints running during transition, and document a clear migration path.

- **Open-Ended Expansion**: The unified model might be used for future features like mini-game conversations or group rooms, which could stress the initial design. Mitigation: keep the schema flexible (e.g., `type` enum, optional metadata) and revisit with dedicated specs when those features are prioritized.

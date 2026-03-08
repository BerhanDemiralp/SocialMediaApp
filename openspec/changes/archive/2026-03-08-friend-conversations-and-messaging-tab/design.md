## Context

We already have:

- A unified conversations backend (`ConversationType.friend` and `conversations`/`conversation_participants`).
- Backend and frontend flows for:
  - Daily friend/group Moments (matching-engine + conversations).
  - Creating/reusing conversations in the Socket.io gateway when sending messages for matches.
  - Home/Friends search and friend-request flows.

What is missing is:

- A clear backend contract for:
  - Creating or reusing a direct friend conversation independently of a specific daily match window.
  - Listing friend conversations in a way tailored to a Messaging tab (subset of `/conversations`).
- A Messaging tab in the Flutter app that:
  - Lists friend conversations.
  - Opens `ChatScreen` using `conversationId` as the primary identifier.

This change stitches together the friend graph, conversations, and chat UX into a cohesive “friend conversations and messaging tab” experience.

## Goals / Non-Goals

**Goals:**

- Provide a backend endpoint to create or reuse a direct `friend` conversation between two confirmed friends.
- Provide an endpoint (or reuse `/conversations` with filters) to list friend conversations for the authenticated user with metadata needed for a Messaging tab.
- Implement a Messaging tab in Flutter that:
  - Shows friend conversations.
  - Navigates to `ChatScreen(conversationId, ...)` on tap.

**Non-Goals:**

- Changing the core conversations schema (only behavior and endpoints).
- Implementing unread counts, pinning, or advanced inbox features.
- Changing the daily matching logic beyond ensuring it cooperates with friend conversations.

## Decisions

1. **Conversation creation/reuse endpoint**
   - Add a backend method on the conversations service to:
     - Given two user ids that are confirmed friends, either:
       - Find an existing `ConversationType.friend` conversation where both are participants, or
       - Create a new friend conversation with both as participants.
   - Expose this via:
     - Either a dedicated endpoint (e.g., `POST /conversations/friends`) or internal use only (for now), since the Home/Friends and Messaging flows can often reuse existing conversations created by Moments/gateway.
   - Rationale: Keeps conversation creation rules in one place and avoids duplicating logic across entry points.

2. **Friend conversations listing**
   - Reuse the existing `/conversations` endpoint but add support for type filtering:
     - `GET /conversations?type=friend` for the Messaging tab, returning only friend conversations.
   - Alternatively, expose a small helper in the frontend that filters conversations client-side by `type`, if the API changes are undesirable.
   - Rationale: Reduces the need for a new endpoint and leverages the generic conversations listing behavior.

3. **Flutter messaging tab data flow**
   - Add a repository (or reuse the existing conversations repository once introduced) to:
     - Call `/conversations?type=friend` (or `/conversations` and filter).
     - Return a list of objects with `conversationId`, `title/participant display`, last message snippet/time.
   - The Messaging tab uses this repository to drive the friend conversation list.
   - Rationale: Aligns with Clean Architecture and keeps the Messaging tab loosely coupled to backend details.

4. **Chat navigation by conversationId**
   - Extend `ChatScreen` routing so that:
     - It can be opened with `conversationId` as the primary identifier (either as a new route or by mapping from conversation to match where needed).
   - For the initial step, the Messaging tab can:
     - Use a new route like `/chat/conversation/:conversationId`.
   - Rationale: Future-proofs chat navigation for non-match-based conversations.

5. **Keep friend graph semantics unchanged**
   - Friend conversations must always be between confirmed friends according to existing friend graph rules.
   - The conversation creation/reuse logic checks friendships without modifying them.
   - Rationale: Keeps responsibilities separate: friend graph controls who is a friend; conversations reflect chats between them.

## Risks / Trade-offs

- **Duplicated conversations for the same friends**
  - Risk: If creation logic is not centralized, multiple friend conversations could be created for the same pair.
  - Mitigation: Use a single helper (service method) that always attempts to find an existing friend conversation before creating a new one.

- **Front/back mismatch about conversation type**
  - Risk: Messaging tab might rely on `type=friend` while some conversations are mis-typed.
  - Mitigation: Ensure all friend flows (Moments, Home, any future endpoints) stamp `ConversationType.friend` correctly; tests can assert this.

- **Routing complexity in Flutter**
  - Risk: Introducing `conversationId`-centric chat routing alongside existing `matchId` routes could cause confusion.
  - Mitigation: Add a dedicated conversation-based route and gradually migrate call sites; keep existing `matchId` routes working for legacy flows.

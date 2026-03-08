## Why

The current backend treats friend chats and group match chats as separate concepts, which makes it harder to build a cohesive conversations experience and evolve features across both modes. We need a unified conversations model that can represent any chat context so that listing conversations, loading messages, and handling real-time events work consistently for both friends and group matches.

## What Changes

- Introduce a unified conversations domain model that represents both friend chats and group match chats with a shared schema.
- Add backend APIs to list a user's conversations across friends and group matches, including metadata needed for the inbox view.
- Add backend APIs to fetch paginated messages for a given conversation using a consistent querying interface.
- Align real-time messaging so that Socket.io events use `conversation:<id>` channels instead of `match:<id>` channels for both friends and group conversations.
- Update persistence and any relevant services to map existing friend and group match data into the unified conversations model.
- Prepare the system for future conversation types (e.g., mini-game conversations) by keeping the model extensible.

## Capabilities

### New Capabilities
- `conversations-backend-foundation`: Unified conversations domain model plus APIs for listing conversations and fetching messages across friend and group contexts.

### Modified Capabilities
- `messages`: Conversation-scoped pagination and real-time semantics updated to work with unified `conversation_id` instead of separate match identifiers.
- `friends-and-groups`: Friend and group match flows updated to create and link into unified conversations rather than separate chat constructs.
- `backend-api`: HTTP and Socket.io APIs updated to expose conversation-centric endpoints and events.

## Impact

- **Database schema**: New or updated tables/columns to represent unified conversations and to associate existing friend matches and group matches with `conversation_id`.
- **Backend services (NestJS)**: New module(s) or services for the conversations domain, plus changes to messaging and matching services to use conversations as the primary unit.
- **Backend API surface**: New REST endpoints (or GraphQL operations) to list conversations and fetch paginated messages; updates to any existing message-related endpoints that assumed match-scoped chats.
- **Real-time messaging**: Socket.io gateways updated to emit and subscribe on `conversation:<id>` channels; clients must adapt to the new channel naming convention.
- **Existing specs**: `messages`, `friends-and-groups`, and `backend-api` specs must be updated to reflect the unified conversations model and APIs.
- **Clients (Flutter app)**: The messages inbox and chat screens will eventually be updated to consume the new APIs and Socket.io channels, though this change focuses on establishing the backend foundation.

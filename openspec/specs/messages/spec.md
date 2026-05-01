## ADDED Requirements

### Requirement: 1:1 Match Message Persistence

The system SHALL persist all chat messages sent by users for 1:1 matches into the `messages` table.

#### Scenario: Successful message send and persistence
- **WHEN** an authenticated user connected via Socket.io emits `sendMessage` with a `matchId` and non-empty `content`
- **AND** that user is a participant of the match (user_a or user_b)
- **THEN** the system creates a new record in the `messages` table with `match_id`, `sender_id`, `content`, and `created_at`
- **AND** the system emits a `newMessage` event to the `match:{matchId}` room containing the stored message (including its database `id` and `created_at`)

#### Scenario: Unauthorized message send
- **WHEN** an authenticated user connected via Socket.io emits `sendMessage` with a `matchId`
- **AND** that user is not a participant in the referenced match
- **THEN** the system SHALL NOT create any record in the `messages` table
- **AND** the system returns a WebSocket error to the sender indicating that they are not allowed to send messages for this match

### Requirement: 1:1 Match Message History API

The system SHALL provide an authenticated HTTP endpoint to retrieve message history for a 1:1 match.

#### Scenario: Fetch own match message history
- **WHEN** an authenticated user sends `GET /matches/{matchId}/messages`
- **AND** that user is a participant of the match
- **THEN** the system returns a 200 OK response
- **AND** the response body contains an array of messages for that match ordered by `created_at`

#### Scenario: Limit number of returned messages
- **WHEN** an authenticated user sends `GET /matches/{matchId}/messages?limit={N}`
- **AND** `N` is a positive integer
- **AND** the user is a participant of the match
- **THEN** the system returns at most `N` messages for that match in the response body

#### Scenario: Forbidden access to another user’s match
- **WHEN** an authenticated user sends `GET /matches/{matchId}/messages`
- **AND** that user is not a participant of the match
- **THEN** the system returns an error response (403 Forbidden or 404 Not Found, as defined by backend-api) and SHALL NOT expose any messages for that match

---

## MODIFIED Requirements

### Requirement: Message association
Messages SHALL be associated primarily with a `conversation_id` that identifies the chat context, regardless of whether the conversation originated from a friend pairing or a group match.

#### Scenario: Message stored for friend conversation
- **WHEN** a user sends a message in a friend conversation
- **THEN** the system SHALL persist the message with the corresponding `conversation_id`
- **AND** the message SHALL be retrievable via message history APIs scoped to that `conversation_id`.

#### Scenario: Message stored for group match conversation
- **WHEN** a user sends a message in a group match conversation
- **THEN** the system SHALL persist the message with the corresponding `conversation_id`
- **AND** the message SHALL be retrievable via message history APIs scoped to that `conversation_id`.

### Requirement: Message pagination
The system SHALL support paginated retrieval of messages for a given `conversation_id` using a deterministic cursor or offset scheme.

#### Scenario: Paginated message history
- **WHEN** a client requests messages for a `conversation_id` with a pagination parameter (e.g., cursor and limit)
- **THEN** the system SHALL return messages ordered by timestamp within that conversation
- **AND** SHALL include pagination metadata so the client can request older or newer messages.

### Requirement: Conversation-based real-time delivery
The system SHALL deliver new message events over real-time channels keyed by `conversation:<id>` so that all participants in a conversation receive updates consistently.

#### Scenario: Real-time event for new message
- **WHEN** a new message is created in a conversation
- **THEN** the backend SHALL emit a real-time event to the `conversation:<id>` channel for that `conversation_id`
- **AND** all connected participants subscribed to that channel SHALL receive the event.

### Requirement: Group chat message persistence
The system SHALL persist messages sent in persistent group chat conversations using the existing conversation-scoped message model.

#### Scenario: Group member sends message
- **WHEN** an authenticated current group member sends a non-empty message in a group chat conversation
- **THEN** the system SHALL persist the message with the group chat `conversation_id`, sender identifier, content, and timestamp
- **AND** the message SHALL be included in message history for that group chat conversation

#### Scenario: Former member cannot send message
- **WHEN** a user who is no longer a member of the group attempts to send a message in the group chat conversation
- **THEN** the system SHALL reject the message
- **AND** SHALL NOT create a message record

### Requirement: Group chat real-time delivery
The system SHALL deliver group chat messages through the canonical `conversation:<id>` real-time channel only to authorized current group members.

#### Scenario: Group message broadcast
- **WHEN** a current group member sends a group chat message successfully
- **THEN** the backend SHALL emit the new message event to the group chat `conversation:<id>` channel
- **AND** connected current group members subscribed to that channel SHALL receive the event

#### Scenario: Deleted group chat emits no events
- **WHEN** a group has been deleted or its group chat conversation has been deactivated
- **THEN** the backend SHALL NOT accept new messages for that conversation
- **AND** SHALL NOT broadcast new group chat message events for it

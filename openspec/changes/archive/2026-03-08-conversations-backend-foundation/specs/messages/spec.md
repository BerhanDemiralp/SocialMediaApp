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

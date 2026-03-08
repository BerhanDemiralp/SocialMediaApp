## MODIFIED Requirements

### Requirement: List user conversations
The backend API SHALL expose an endpoint that returns a unified list of conversations for the authenticated user, including friend and group match conversations.

#### Scenario: Fetch conversations list
- **WHEN** an authenticated client calls the conversations listing endpoint
- **THEN** the system SHALL return a paginated list of conversations where the user is a participant
- **AND** each item SHALL include `conversation_id`, conversation type, participant summary, last message snippet, and last message timestamp.

### Requirement: Fetch conversation messages
The backend API SHALL expose an endpoint to fetch paginated messages for a given `conversation_id`.

#### Scenario: Fetch paginated messages for conversation
- **WHEN** an authenticated client calls the messages endpoint for a specific `conversation_id` with pagination parameters
- **THEN** the system SHALL return messages scoped to that `conversation_id` only
- **AND** SHALL include pagination metadata so the client can request additional pages.

### Requirement: Real-time conversation channels
The backend API and real-time layer SHALL use `conversation:<id>` as the canonical channel naming scheme for chat-related events.

#### Scenario: Subscribe to conversation channel
- **WHEN** a client subscribes to `conversation:<id>` via Socket.io
- **THEN** the backend SHALL deliver new message events and relevant conversation updates for that `conversation_id` on that channel
- **AND** SHALL NOT require the client to know the underlying match identifier.

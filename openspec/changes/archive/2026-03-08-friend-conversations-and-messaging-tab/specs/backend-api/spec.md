## ADDED Requirements

### Requirement: List friend conversations for authenticated user
The backend API SHALL provide an endpoint for listing the authenticated user’s direct friend conversations, suitable for powering the Messaging tab.

#### Scenario: List friend conversations with metadata
- **WHEN** the client calls the friend conversations listing endpoint as an authenticated user
- **THEN** the API returns only conversations where the user is a participant and the conversation type is `friend`
- **AND** each conversation item includes `id`, conversation type, the other participant’s user identifier, display name, and avatar URL (if available)
- **AND** each conversation item includes the last message text (or a suitable preview) and the last message timestamp
- **AND** results are ordered with the most recently active conversation first
- **AND** the endpoint supports pagination so the client can load additional conversations as needed

### Requirement: Create or reuse direct friend conversation
The backend API SHALL provide an endpoint that creates or reuses a direct `friend` conversation between two friends on demand.

#### Scenario: Reuse existing friend conversation
- **WHEN** the client calls the create-or-reuse friend conversation endpoint with a friend user identifier
- **AND** a `friend`-type conversation already exists between the authenticated user and that friend
- **THEN** the API responds with the existing conversation record instead of creating a new one
- **AND** the response includes the existing `conversation_id` that can be used to open ChatScreen

#### Scenario: Create new friend conversation when none exists
- **WHEN** the client calls the create-or-reuse friend conversation endpoint with a friend user identifier
- **AND** no `friend`-type conversation exists between the two users
- **THEN** the API creates a new `friend`-type conversation using the unified conversations model
- **AND** the new conversation is linked to both users as participants
- **AND** the API responds with the new conversation record including its `conversation_id`


## ADDED Requirements

### Requirement: Messaging tab lists friend conversations
The system SHALL provide a Messaging tab that lists all direct friend conversations for the authenticated user, using the unified conversations model.

#### Scenario: Open Messaging tab and see friend conversations
- **WHEN** the authenticated user opens the Messaging tab
- **THEN** the app loads the list of `friend`-type conversations for that user
- **AND** each row shows the friend’s display name and avatar (where available)
- **AND** each row shows the last message snippet and its sent time
- **AND** conversations are ordered with the most recently active conversation first

#### Scenario: Empty state when user has no friend conversations
- **WHEN** the authenticated user opens the Messaging tab
- **AND** the user has no `friend`-type conversations
- **THEN** the app shows an empty state message explaining that there are no conversations yet
- **AND** the empty state points the user to ways to start conversations (for example via Home/Friends or Moments)

### Requirement: Messaging tab opens ChatScreen by conversation ID
The system SHALL allow users to open an existing friend conversation from the Messaging tab using the unified `conversation_id`.

#### Scenario: Tap conversation opens ChatScreen
- **WHEN** the user taps a row in the Messaging tab list
- **THEN** the app navigates to `ChatScreen(conversationId)`
- **AND** the `conversationId` passed to the screen is the same `conversation_id` from the conversation list item
- **AND** the chat history for that conversation is loaded and displayed


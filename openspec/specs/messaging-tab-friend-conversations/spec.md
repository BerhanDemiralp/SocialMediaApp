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

### Requirement: Messaging tab lists group chat conversations
The system SHALL show persistent group chat conversations in the Messaging tab for authenticated users who are current members of those groups.

#### Scenario: Open Messaging tab and see group chats
- **WHEN** the authenticated user opens the Messaging tab
- **AND** the user is a current member of one or more groups with persistent group chats
- **THEN** the app SHALL display those group chat conversations in the conversation list
- **AND** each group chat row SHALL show the group name, a group visual identifier, last message snippet, and last message time

#### Scenario: Group chat removed after leave
- **WHEN** the authenticated user leaves a group successfully
- **THEN** the app SHALL remove that group's chat conversation from the Messaging tab
- **AND** tapping stale local data for that group chat SHALL NOT open the chat

### Requirement: Group chats have distinct chat presentation
The system SHALL visually distinguish group chat conversations from direct friend conversations in the Messaging tab and chat screen.

#### Scenario: Group row has distinct presentation
- **WHEN** a group chat conversation appears in the Messaging tab
- **THEN** the row SHALL use group-specific presentation that differs from friend chat rows
- **AND** the row SHALL remain consistent with the app's Material Design 3 visual language

#### Scenario: Open group chat screen
- **WHEN** the user taps a group chat row
- **THEN** the app SHALL navigate to `ChatScreen(conversationId)` for that group chat
- **AND** the chat screen SHALL show group-specific header or context treatment instead of friend-only participant presentation

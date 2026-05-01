## ADDED Requirements

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

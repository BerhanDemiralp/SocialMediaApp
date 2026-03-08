## MODIFIED Requirements

### Requirement: Friend pairings create conversations
When a daily friend pairing results in a chat, the system SHALL create or reuse a `conversation` representing that friend chat instead of using a separate match-scoped chat entity.

#### Scenario: New friend conversation
- **WHEN** two friends are paired for a daily moment and no existing conversation exists between them
- **THEN** the system SHALL create a new `conversation` of type `friend`
- **AND** link both users as participants.

#### Scenario: Reuse existing friend conversation
- **WHEN** two friends are paired for a daily moment and an existing `conversation` already represents their chat
- **THEN** the system SHALL reuse that existing `conversation` for messages and real-time events
- **AND** SHALL NOT create a duplicate conversation.

### Requirement: Group matches create conversations
When a group daily pairing leads to a chat, the system SHALL create or reuse a `conversation` that captures the match context and participants.

#### Scenario: Temporary group match conversation
- **WHEN** a group daily pairing is created and a temporary chat is opened for the active window
- **THEN** the system SHALL create a `conversation` of an appropriate group-related type
- **AND** associate the matched users as participants.

#### Scenario: Group match converted to permanent conversation
- **WHEN** both participants in a group match opt into continuing the chat after the temporary window
- **THEN** the system SHALL keep using the same `conversation` identifier for the permanent chat
- **AND** SHALL preserve the full message history within that conversation.

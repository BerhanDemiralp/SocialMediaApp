## ADDED Requirements

### Requirement: Moment conversation write permissions
The system SHALL enforce Moment-specific writable and read-only states when users send messages in conversations linked to Moment matches.

#### Scenario: Friend Moment conversation remains writable
- **WHEN** a participant sends a message in a conversation linked to a friend Moment
- **THEN** the system SHALL allow the message if the user is authorized for that conversation
- **AND** the conversation SHALL remain writable after the Moment active window ends

#### Scenario: Active group Moment conversation is writable
- **WHEN** a participant sends a message in a conversation linked to an active group Moment
- **THEN** the system SHALL allow the message if the user is authorized for that conversation

#### Scenario: Non-opted-in group Moment conversation is read-only
- **WHEN** a participant sends a message in a conversation linked to an expired group Moment
- **AND** both participants have not opted in to continue the conversation
- **THEN** the system SHALL reject the message
- **AND** the system SHALL NOT create a message record

### Requirement: Expired Moment history remains accessible
The system SHALL keep Moment conversation history accessible from Messages after the active window ends.

#### Scenario: Fetch expired Moment messages
- **WHEN** an authenticated participant opens a conversation linked to an expired Moment
- **THEN** the system SHALL return the message history for that conversation
- **AND** the response SHALL indicate whether the conversation is writable or read-only

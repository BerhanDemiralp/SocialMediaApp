## ADDED Requirements

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

## Purpose

This capability describes the unified conversations domain that represents all 1:1
and small-group chats (including friend pairings and group matches) as `conversations`
with stable identifiers used across APIs, persistence, and real-time channels.

## ADDED Requirements

### Requirement: Unified conversation entity
The system SHALL represent all 1:1 and small-group chats (including friend pairings and group matches) as `conversations` with a stable `conversation_id` used across HTTP APIs, database records, and real-time channels.

#### Scenario: Friend chat conversation
- **WHEN** two friends are paired for a daily moment and a chat is created
- **THEN** the system SHALL create a `conversation` record of type `friend` with a unique `conversation_id`
- **AND** both users SHALL be registered as participants in that conversation.

#### Scenario: Group match conversation
- **WHEN** two group members are matched and a chat is created
- **THEN** the system SHALL create a `conversation` record of type `group_pair` (or equivalent)
- **AND** both matched users SHALL be registered as participants in that conversation.

### Requirement: Conversation extensibility
The system SHALL allow additional conversation types (e.g., mini-game follow-up chats) to be added without requiring a different message model or separate message tables.

#### Scenario: New conversation type added
- **WHEN** a new conversation type is introduced in the backend
- **THEN** it SHALL be represented using the same `conversations` and `conversation_participants` structures
- **AND** existing message APIs and Socket.io channels SHALL work without schema changes.

### Requirement: Conversation-scoped access control
The system SHALL restrict access to conversation data so that only participants in a given conversation can list or read its messages.

#### Scenario: Non-participant access denied
- **WHEN** a user attempts to list or read messages for a `conversation_id` they are not a participant in
- **THEN** the backend SHALL reject the request with an appropriate authorization error
- **AND** no conversation metadata or message content SHALL be returned.


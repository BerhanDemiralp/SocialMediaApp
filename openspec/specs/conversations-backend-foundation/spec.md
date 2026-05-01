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

### Requirement: Persistent group chat conversation
The system SHALL represent each group with exactly one persistent group chat conversation using the unified conversations model.

#### Scenario: Group creation creates group conversation
- **WHEN** an authenticated user creates a group successfully
- **THEN** the system SHALL create a `group`-type conversation associated with that group
- **AND** the creator SHALL be able to access that conversation as a current group member

#### Scenario: Existing group has one group conversation
- **WHEN** the system loads or backfills an existing group
- **THEN** the system SHALL ensure the group has exactly one associated persistent group chat conversation
- **AND** SHALL NOT create duplicate group chat conversations for the same group

### Requirement: Group chat membership authorization
The system SHALL authorize group chat access based on active membership in the group associated with the conversation.

#### Scenario: Current member opens group chat
- **WHEN** a current group member requests the group's chat conversation
- **THEN** the backend SHALL allow access to the conversation metadata and messages according to normal conversation permissions

#### Scenario: Non-member cannot open group chat
- **WHEN** a user who is not an active member of the group requests the group's chat conversation
- **THEN** the backend SHALL reject the request with an authorization error
- **AND** SHALL NOT expose conversation metadata or message content

#### Scenario: Former member cannot subscribe to group chat
- **WHEN** a user who has left the group attempts to join the `conversation:<id>` real-time channel for the group chat
- **THEN** the backend SHALL reject the subscription
- **AND** the user SHALL NOT receive future group chat events

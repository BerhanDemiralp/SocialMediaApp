## ADDED Requirements

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

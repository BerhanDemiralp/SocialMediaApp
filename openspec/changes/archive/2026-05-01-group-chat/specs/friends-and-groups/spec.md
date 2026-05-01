## ADDED Requirements

### Requirement: Groups own persistent chats
The system SHALL create and manage a persistent group chat conversation as part of each group's lifecycle.

#### Scenario: Create group with chat
- **WHEN** a user creates a group with a valid name
- **THEN** the system SHALL create the group record, add the creator as a member, and create the group's persistent chat conversation
- **AND** the group response SHALL include or make discoverable the group chat `conversation_id`

#### Scenario: Join group grants chat access
- **WHEN** a user joins a group using a valid invite code
- **THEN** the system SHALL grant the user access to the group's persistent chat conversation
- **AND** the group chat SHALL appear in the user's conversation list

### Requirement: Group deletion removes persistent chat
The system SHALL remove or deactivate a group's persistent chat conversation when the group is deleted.

#### Scenario: Delete group removes chat for everyone
- **WHEN** a group is deleted successfully
- **THEN** the system SHALL remove or deactivate the associated persistent group chat conversation
- **AND** the group chat SHALL no longer be accessible to any former group member

#### Scenario: Delete group removes chat messages
- **WHEN** a group is deleted successfully
- **THEN** the system SHALL delete, soft-delete, or hide the associated group chat messages according to database conventions
- **AND** message history APIs SHALL NOT return those messages

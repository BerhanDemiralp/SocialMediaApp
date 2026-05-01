## ADDED Requirements

### Requirement: Conversation list includes group chats
The backend API SHALL include persistent group chat conversations in the authenticated user's unified conversation list when the user is a current member of the associated group.

#### Scenario: List conversations includes group chat
- **WHEN** an authenticated current group member calls the conversations listing endpoint
- **THEN** the response SHALL include the group's persistent chat conversation
- **AND** the conversation item SHALL include `conversation_id`, conversation type `group`, group identifier, group name, last message preview, and last message timestamp

#### Scenario: Former member list excludes group chat
- **WHEN** a user who has left a group calls the conversations listing endpoint
- **THEN** the response SHALL NOT include that group's persistent chat conversation

### Requirement: Group lifecycle updates group chat access
The backend API SHALL update group chat visibility and access when group membership or group lifecycle changes.

#### Scenario: Leave group removes chat access
- **WHEN** a current member successfully leaves a group
- **THEN** the backend SHALL remove that user's access to the group's persistent chat conversation
- **AND** subsequent conversation list responses for that user SHALL exclude the group chat

#### Scenario: Delete group removes group chat
- **WHEN** a group is deleted successfully
- **THEN** the backend SHALL delete, soft-delete, or deactivate the associated group chat conversation and its messages according to database conventions
- **AND** subsequent conversation list and message history requests SHALL NOT expose that group chat to any user

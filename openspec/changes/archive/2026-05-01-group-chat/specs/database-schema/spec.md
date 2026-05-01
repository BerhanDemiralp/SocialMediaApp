## ADDED Requirements

### Requirement: Group chat conversation association
The database schema SHALL support associating each group with exactly one persistent group chat conversation.

#### Scenario: Group record has conversation association
- **WHEN** a group has a persistent chat
- **THEN** the database SHALL be able to associate that group with one `group`-type conversation
- **AND** the association SHALL prevent duplicate persistent group chat conversations for the same group

#### Scenario: Conversation identifies group chat type
- **WHEN** a conversation represents a persistent group chat
- **THEN** the conversation record SHALL identify its type as `group` or an equivalent group-chat-specific value
- **AND** SHALL retain the stable `conversation_id` used by messages and real-time channels

### Requirement: Group chat cleanup data integrity
The database schema SHALL preserve data integrity when group chat access is removed by member leave or group deletion.

#### Scenario: Member leave removes participant access
- **WHEN** a member leaves a group
- **THEN** database records SHALL be updated so that user no longer has active participant access to the group's persistent chat conversation

#### Scenario: Group deletion cleans chat data
- **WHEN** a group is deleted
- **THEN** database records SHALL delete, soft-delete, or deactivate the associated group chat conversation and messages consistently
- **AND** SHALL avoid orphaned active chat records for the deleted group

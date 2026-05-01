## ADDED Requirements

### Requirement: Users Table
The system SHALL store user records in a users table with required fields.

#### Scenario: User record structure
- **WHEN** a new user registers
- **THEN** a record is created with: id (UUID), username (unique), email, avatar_url, created_at, updated_at

#### Scenario: Username uniqueness
- **WHEN** a user attempts to register with an existing username
- **THEN** registration fails with uniqueness constraint error

---

### Requirement: Friendships Table
The system SHALL store friend relationships between users.

#### Scenario: Friendship record structure
- **WHEN** user A sends friend request to user B
- **THEN** a record is created with: id, requester_id, addressee_id, status (pending/accepted/rejected), created_at

#### Scenario: Mutual confirmation required
- **WHEN** user B accepts user A's friend request
- **THEN** friendship status changes to accepted
- **AND** friendship is bidirectional (user B can now see user A as friend)

---

### Requirement: Groups Table
The system SHALL store group information for group conversations.

#### Scenario: Group record structure
- **WHEN** a new group is created
- **THEN** a record is created with: id, name, invite_code (unique), created_by, created_at, updated_at

#### Scenario: Group membership
- **WHEN** user joins a group via invite code
- **THEN** a group_member record is created linking user to group

---

### Requirement: Messages Table
The system SHALL store chat messages between matched users.

#### Scenario: Message record structure
- **WHEN** user sends a message
- **THEN** a record is created with: id, match_id, sender_id, content, created_at

#### Scenario: Message retrieval by match
- **WHEN** user requests messages for a match
- **THEN** messages are returned ordered by created_at ascending

---

### Requirement: Matches Table
The system SHALL store daily match/pairing information.

#### Scenario: Match record structure
- **WHEN** daily matching occurs
- **THEN** a record is created with: id, user_a_id, user_b_id, match_type (friends/groups), status (active/expired/successful), scheduled_at, expires_at

#### Scenario: Match status tracking
- **WHEN** match expires (1 hour window passes)
- **THEN** match status is updated to expired
- **AND** messages remain accessible in read-only mode for group matches

---

### Requirement: Daily Questions Table
The system SHALL store daily questions for users to answer.

#### Scenario: Daily question record structure
- **WHEN** admin creates a daily question
- **THEN** a record is created with: id, question_text, question_date, created_at

#### Scenario: Daily question retrieval
- **WHEN** user requests today's question
- **THEN** the question for the current date is returned

---

### Requirement: User Answers Table
The system SHALL store user answers to daily questions.

#### Scenario: Answer record structure
- **WHEN** user submits answer to daily question
- **THEN** a record is created with: id, user_id, question_id, answer_text, created_at

---

### Requirement: Games Table
The system SHALL store mini-game definitions and user game results.

#### Scenario: Game result storage
- **WHEN** user completes a mini-game
- **THEN** a record is created with: id, user_id, game_type, result_data, created_at

#### Scenario: Game history retrieval
- **WHEN** user requests their game history
- **THEN** all past game results are returned ordered by created_at descending

---

## Conventions

All database schema follows conventions from `openspec/config.yaml`:
- Table and column naming: snake_case
- IDs: UUID v4 for user-facing IDs, auto-increment bigint for internal relations
- Timestamps: created_at (default now), updated_at (on every update)
- Soft deletes: Use deleted_at column instead of hard deletes

---

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

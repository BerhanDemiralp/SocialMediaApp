## ADDED Requirements

### Requirement: Manage friend requests
The system SHALL allow an authenticated user to manage friend relationships through an explicit request workflow, including sending, accepting, rejecting, and canceling friend requests.

#### Scenario: Send a friend request
- **WHEN** a user submits a friend request to a valid, different user
- **THEN** the system SHALL create a pending friendship record between the requester and addressee

#### Scenario: Accept a friend request
- **WHEN** the addressee accepts a pending friend request
- **THEN** the system SHALL mark the friendship as accepted and both users SHALL appear in each other’s friend lists

#### Scenario: Reject a friend request
- **WHEN** the addressee rejects a pending friend request
- **THEN** the system SHALL mark the friendship as rejected or remove the pending request so that the users are not considered friends

#### Scenario: Cancel an outgoing friend request
- **WHEN** the requester cancels a pending friend request they previously sent
- **THEN** the system SHALL remove or mark the request as canceled and it SHALL no longer be actionable by the addressee

### Requirement: List my friends and requests
The system SHALL allow an authenticated user to view their confirmed friends and pending friend requests.

#### Scenario: List confirmed friends
- **WHEN** a user requests their friend list
- **THEN** the system SHALL return all users who have an accepted friendship relationship with the requester

#### Scenario: List incoming friend requests
- **WHEN** a user requests their incoming friend requests
- **THEN** the system SHALL return all pending friendship requests where the requester is another user and the addressee is the current user

#### Scenario: List outgoing friend requests
- **WHEN** a user requests their outgoing friend requests
- **THEN** the system SHALL return all pending friendship requests where the requester is the current user

### Requirement: Create and manage groups
The system SHALL allow an authenticated user to create groups and manage basic group attributes needed for membership and matching.

#### Scenario: Create a group
- **WHEN** a user creates a new group with a valid name
- **THEN** the system SHALL create a group record, generate an invite code, and add the creator as the group owner and member

#### Scenario: List my groups
- **WHEN** a user requests the list of groups they belong to
- **THEN** the system SHALL return all groups where the user is recorded as a member

### Requirement: Join and leave groups via invite code
The system SHALL allow users to join a group using a valid invite code and to leave groups they are members of.

#### Scenario: Join group with valid invite code
- **WHEN** a user submits a valid invite code for an existing group
- **THEN** the system SHALL add the user to the group_members table for that group if they are not already a member

#### Scenario: Join group with invalid invite code
- **WHEN** a user submits an invalid or expired invite code
- **THEN** the system SHALL reject the request and SHALL NOT change group membership

#### Scenario: Leave group
- **WHEN** a member requests to leave a group
- **THEN** the system SHALL remove the user’s membership record from that group unless they are the last owner and additional rules apply

---

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


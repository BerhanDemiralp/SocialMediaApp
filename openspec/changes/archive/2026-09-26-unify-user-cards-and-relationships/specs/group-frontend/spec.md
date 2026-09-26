## ADDED Requirements

### Requirement: Group members use shared user cards
The group member list SHALL render each member with the shared identity and relationship card system, including Add friend, close-icon cancellation, Accept / close-icon rejection, and card-tap chat access as applicable to the current relationship.

#### Scenario: Respond to incoming request within a group
- **WHEN** a group member has sent the current user a pending request
- **THEN** their card SHALL offer Accept and a close-icon rejection action
- **AND** accepting SHALL establish friendship while cancelling SHALL reject the incoming request
- **AND** successful changes SHALL update Home's request lists and other cards for that user

#### Scenario: Cancel an outgoing group member request
- **WHEN** the current user has a pending outgoing request to a group member
- **THEN** their card SHALL offer close-icon cancellation
- **AND** successful cancellation SHALL restore Add friend

#### Scenario: Open a friend's conversation
- **WHEN** the current user taps a confirmed friend's card in the group
- **THEN** the common conversation-opening flow SHALL open or reuse their direct friend conversation
- **AND** the user SHALL be able to navigate back to group details

#### Scenario: Current user's member card
- **WHEN** the current user appears in the group member list
- **THEN** their identity SHALL be marked as self and SHALL NOT expose social actions

#### Scenario: Group navigation remains available
- **WHEN** shared user cards replace the member list implementation
- **THEN** group invite, leave, and open-chat actions SHALL remain available
- **AND** the persistent group chat header SHALL still provide access to group information

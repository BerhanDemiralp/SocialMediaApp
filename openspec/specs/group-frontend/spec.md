## Purpose

Define the authenticated frontend experience for viewing and managing group memberships.

## Requirements

### Requirement: Group management surface in frontend
The mobile app SHALL provide an authenticated Group Management surface where users can view and manage their group memberships.

#### Scenario: View list of my groups
- **WHEN** an authenticated user opens the Group Management screen
- **THEN** the app SHALL call the backend `GET /groups` endpoint
- **AND** the app SHALL display a list of groups returned for the current user, including at least each group's name and invite code.

#### Scenario: No groups shows empty state
- **WHEN** an authenticated user opens the Group Management screen
- **AND** the backend returns an empty list from `GET /groups`
- **THEN** the app SHALL show an empty state explaining that the user is not in any groups yet
- **AND** the empty state SHALL provide clear actions to create or join a group.

### Requirement: Create group from frontend
The mobile app SHALL allow an authenticated user to create a new group by specifying a group name.

#### Scenario: Successful group creation
- **WHEN** an authenticated user enters a valid group name and submits the create-group form
- **THEN** the app SHALL send a `POST /groups` request with the group name in the request body
- **AND** on a successful response, the app SHALL add the new group to the displayed list
- **AND** SHALL show the group's invite code so the user can share it.

#### Scenario: Group creation error handling
- **WHEN** the `POST /groups` request fails (for example due to validation or network error)
- **THEN** the app SHALL display a non-blocking error message
- **AND** SHALL allow the user to retry or adjust the name without crashing or leaving the screen in an inconsistent state.

### Requirement: Join group by invite code
The mobile app SHALL allow an authenticated user to join an existing group using an invite code.

#### Scenario: Successful join by invite code
- **WHEN** an authenticated user enters a valid invite code and submits the join-group form
- **THEN** the app SHALL send a `POST /groups/join` request with the invite code in the request body
- **AND** on a successful response, the app SHALL add the joined group to the displayed list.

#### Scenario: Invalid invite code shows error
- **WHEN** an authenticated user enters an invalid or expired invite code and submits the join-group form
- **THEN** the app SHALL handle the error response from `POST /groups/join`
- **AND** SHALL display an error message indicating that the invite code is invalid
- **AND** SHALL allow the user to try again with a different code.

### Requirement: Leave group from frontend
The mobile app SHALL allow an authenticated user to leave a group they are currently a member of.

#### Scenario: Leave group successfully
- **WHEN** an authenticated user triggers the leave action for a group in the list
- **THEN** the app SHALL send a `POST /groups/{groupId}/leave` request for that group
- **AND** on a successful response, the app SHALL remove the group from the displayed list.

#### Scenario: Leave group error handling
- **WHEN** the `POST /groups/{groupId}/leave` request fails (for example, membership not found or network error)
- **THEN** the app SHALL display an error message
- **AND** SHALL keep the group in the list until a successful leave operation completes.

### Requirement: Navigation entry point to group management
The mobile app SHALL provide at least one clear navigation entry point to the Group Management surface for authenticated users.

#### Scenario: Access groups from within the app
- **WHEN** an authenticated user is signed in and on a main app surface (for example Home or Profile)
- **THEN** the app SHALL expose an entry point (such as a "My Groups" item or button)
- **AND** tapping that entry point SHALL navigate to the Group Management screen.

### Requirement: Group chat access from group surfaces
The mobile app SHALL let current group members open the persistent group chat for a group from appropriate group surfaces.

#### Scenario: Open group chat from group details
- **WHEN** an authenticated user views a group they currently belong to
- **THEN** the app SHALL provide an action to open that group's chat
- **AND** activating the action SHALL navigate to the chat screen using the group's persistent `conversation_id`

### Requirement: Leave group clears frontend group chat state
The mobile app SHALL remove local access to a group's chat when the authenticated user leaves that group.

#### Scenario: Leave group removes cached chat entry
- **WHEN** the user leaves a group successfully from the Group Management surface
- **THEN** the app SHALL remove the group from the displayed groups list
- **AND** SHALL remove that group's chat conversation from local conversation state
- **AND** SHALL prevent navigation to that group chat from stale UI state

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

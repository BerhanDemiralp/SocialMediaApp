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

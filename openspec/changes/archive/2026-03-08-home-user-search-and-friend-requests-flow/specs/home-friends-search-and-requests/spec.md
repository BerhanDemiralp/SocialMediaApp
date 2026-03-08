## ADDED Requirements

### Requirement: Home friends search surface
The mobile app SHALL provide a Home/Friends surface where an authenticated user can search for other users by username and view results with enough information to send friend requests.

#### Scenario: Search by username
- **WHEN** an authenticated user enters a non-empty search query in the Home search field
- **THEN** the app SHALL call the backend user search endpoint with the query and a reasonable limit
- **AND** the app SHALL display a list of matching users (excluding the current user) with username and avatar.

#### Scenario: Empty results
- **WHEN** an authenticated user searches for a username that has no matches
- **THEN** the app SHALL show an empty state indicating that no users were found
- **AND** SHALL NOT show stale results from previous searches.

### Requirement: Send friend request from search result
The Home/Friends UI SHALL allow sending a friend request directly from a search result row.

#### Scenario: Send friend request
- **WHEN** an authenticated user taps the “Add friend” action on a search result
- **THEN** the app SHALL call the friend request API with the target user identifier
- **AND** on success, the UI SHALL reflect that a request is pending (e.g., button state or label updated).

#### Scenario: Prevent duplicate requests
- **WHEN** the user attempts to send a friend request to a user who already has a pending or accepted friendship
- **THEN** the app SHALL show a non-blocking error message
- **AND** SHALL NOT create a duplicate request.

### Requirement: Manage incoming and outgoing friend requests from Home
The Home/Friends surface SHALL show both incoming and outgoing friend requests in simple lists with appropriate actions.

#### Scenario: View incoming requests
- **WHEN** an authenticated user opens the Home/Friends surface
- **THEN** the app SHALL fetch and display a list of pending incoming friend requests (if any), each with accept/reject actions.

#### Scenario: Accept or reject incoming request
- **WHEN** the user taps “Accept” on a pending incoming request
- **THEN** the app SHALL call the accept API
- **AND** on success, the request SHALL be removed from the incoming list and the user SHALL be treated as a confirmed friend.
- **WHEN** the user taps “Reject” on a pending incoming request
- **THEN** the app SHALL call the reject API
- **AND** on success, the request SHALL be removed from the incoming list.

#### Scenario: View outgoing requests
- **WHEN** an authenticated user opens the Home/Friends surface
- **THEN** the app SHALL fetch and display a list of pending outgoing friend requests (if any), each with a cancel action.

#### Scenario: Cancel outgoing request
- **WHEN** the user taps “Cancel” on a pending outgoing request
- **THEN** the app SHALL call the cancel API
- **AND** on success, the request SHALL be removed from the outgoing list.


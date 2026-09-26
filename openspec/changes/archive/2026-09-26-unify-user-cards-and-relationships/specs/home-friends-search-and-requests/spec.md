## MODIFIED Requirements

### Requirement: Manage incoming and outgoing friend requests from Home
The Home/Friends surface SHALL show incoming and outgoing friend requests in lists using the shared user-card and relationship-action system. Search results for the same users SHALL expose the same relationship actions.

#### Scenario: View incoming requests
- **WHEN** an authenticated user opens the Home/Friends surface
- **THEN** the app SHALL fetch and display pending incoming friend requests, if any
- **AND** each request SHALL offer Accept and a close-icon rejection action actions using the shared card

#### Scenario: Accept or reject incoming request
- **WHEN** the user taps Accept on a pending incoming request
- **THEN** the app SHALL call the accept API using the request ID
- **AND** on success the request SHALL be removed from the incoming list and the user SHALL be treated as a confirmed friend across all surfaces
- **WHEN** the user taps the close icon on a pending incoming request
- **THEN** the app SHALL call the reject API using the request ID
- **AND** on success the request SHALL be removed from the incoming list and other cards for the person SHALL allow Add friend

#### Scenario: View outgoing requests
- **WHEN** an authenticated user opens the Home/Friends surface
- **THEN** the app SHALL fetch and display pending outgoing requests, if any, each with a close-icon cancellation action

#### Scenario: Cancel outgoing request
- **WHEN** the user taps close-icon cancellation on a pending outgoing request
- **THEN** the app SHALL call the cancel API using the request ID
- **AND** on success the request SHALL be removed from the outgoing list
- **AND** all cards for that person SHALL permit a new friend request

#### Scenario: Search and request lists stay consistent
- **WHEN** the same person appears in search and a request list
- **THEN** both cards SHALL use the same relationship state and pending-operation lock
- **AND** an action completed in either location SHALL update both

## ADDED Requirements

### Requirement: Existing friends on Find Friends
The Find Friends page SHALL display a Friends section below incoming and outgoing requests using the shared user cards and central relationship state.

#### Scenario: Friends change
- **WHEN** a friend request is accepted or a friendship is removed
- **THEN** the Friends section SHALL update without manually reloading the page
- **AND** an empty friend list SHALL display an empty-state message

## ADDED Requirements

### Requirement: Current Moment API
The backend API SHALL expose an authenticated endpoint that returns the authenticated user's active Moment pairings for Home.

#### Scenario: Fetch active Moments
- **WHEN** an authenticated client requests the current Moment endpoint
- **THEN** the API SHALL return zero, one, or two active Moments for the user
- **AND** each item SHALL include the Moment identifier, match type, participant summary, linked conversation identifier, scheduled timestamp, expiration timestamp, and status

#### Scenario: Active Moments distinguish type
- **WHEN** the response includes both a friend Moment and a group Moment
- **THEN** each item SHALL identify whether it is a friend Moment or group Moment

### Requirement: Moment history API
The backend API SHALL expose an authenticated endpoint for paginated Moment history.

#### Scenario: Fetch Moment history
- **WHEN** an authenticated client requests Moment history
- **THEN** the API SHALL return only Moment records where the authenticated user is a participant
- **AND** the response SHALL support pagination

### Requirement: Group Moment opt-in API
The backend API SHALL expose an authenticated endpoint for a participant to opt in to continuing a group Moment conversation.

#### Scenario: Participant opts in
- **WHEN** an authenticated participant sends an opt-in request for their group Moment
- **THEN** the API SHALL record that participant's opt-in state
- **AND** the API SHALL return the updated Moment state

#### Scenario: Non-participant cannot opt in
- **WHEN** an authenticated user who is not a participant sends an opt-in request for a group Moment
- **THEN** the API SHALL reject the request
- **AND** the API SHALL NOT change opt-in state

### Requirement: Moment run API
The backend API SHALL expose a protected operational entrypoint for triggering Moment pairing and lifecycle evaluation.

#### Scenario: Trigger Moment run
- **WHEN** an authorized operational caller triggers the Moment run endpoint
- **THEN** the API SHALL run due pairing, reminder, and expiration work for the configured schedule
- **AND** the operation SHALL be safe to retry without creating duplicate same-type daily Moments

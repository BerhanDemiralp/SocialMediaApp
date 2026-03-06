## ADDED Requirements

### Requirement: List current active Moment
The system SHALL allow an authenticated user to retrieve their current active match during the 1‑hour window.

#### Scenario: Active Moment visible
- **WHEN** a signed-in user requests their current Moment
- **AND** the user has a match with status `active`
- **AND** the current time is between the match `scheduled_at` and `expires_at`
- **THEN** the system SHALL return that match with partner identity and timing metadata

### Requirement: Hide matches outside active window from current view
The system SHALL NOT include matches outside their 1‑hour window in the “current Moment” view.

#### Scenario: No active Moment outside window
- **WHEN** the current time is not between any match `scheduled_at` and `expires_at` for the user
- **THEN** the system SHALL indicate that there is no active Moment match

### Requirement: List historical matches
The system SHALL allow an authenticated user to retrieve past matches regardless of active window.

#### Scenario: Historical matches
- **WHEN** a signed-in user requests their match history with pagination parameters
- **THEN** the system SHALL return a paginated list of matches with statuses such as `successful` and `expired`, ordered by most recent first


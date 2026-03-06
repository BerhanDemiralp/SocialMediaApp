## Purpose

Define how the system schedules and creates daily “Moment” matches between users.

## ADDED Requirements

### Requirement: Daily scheduled matching
The system SHALL run the matching engine once per day at a predefined app time to create daily matches.

#### Scenario: Daily matching run
- **WHEN** the scheduled daily matching time is reached
- **THEN** the system SHALL evaluate eligible users and create new matches according to matching rules

### Requirement: Single active match per user
The system SHALL ensure that each user has at most one active match at any given time.

#### Scenario: Skip user with existing active match
- **WHEN** the matching engine runs
- **AND** a user already has an active match
- **THEN** the system SHALL NOT create a new match for that user

### Requirement: One match per pair per day
The system SHALL prevent creating more than one match between the same two users for the same app day.

#### Scenario: Skip duplicate pair
- **WHEN** a match already exists between user A and user B for the current app day
- **THEN** the matching engine SHALL NOT create another match between the same pair for that day

### Requirement: 1‑hour active window
Each match SHALL be active only for 1 hour from its scheduled time.

#### Scenario: Set active and expiry timestamps
- **WHEN** a match is created by the matching engine
- **THEN** the system SHALL set `scheduled_at` to the daily matching time
- **AND** set `expires_at = scheduled_at + 1 hour`
- **AND** set the match status to `active`


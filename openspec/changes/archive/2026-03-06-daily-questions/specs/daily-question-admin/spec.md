## ADDED Requirements

### Requirement: Create daily question
The system SHALL allow an authorized admin to create a new daily question with question text and an active date.

#### Scenario: Successful creation
- **WHEN** an authenticated admin submits a valid create-daily-question request
- **THEN** the system SHALL persist a new daily question record with the provided text and active date
- **AND** enforce uniqueness of the active date at the database level

### Requirement: List daily questions
The system SHALL allow an authorized admin to list existing daily questions with basic metadata.

#### Scenario: List upcoming questions
- **WHEN** an authenticated admin requests the list of daily questions
- **THEN** the system SHALL return a paginated list including at least id, question text snippet, active date, and created_at

### Requirement: Single active question per day
The system SHALL ensure that there is at most one daily question active for any given app day.

#### Scenario: Reject conflicting active date
- **WHEN** an authenticated admin attempts to create a daily question with an active date that already has a question
- **THEN** the system SHALL reject the request with a validation error indicating the date conflict


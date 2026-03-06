## ADDED Requirements

### Requirement: Fetch today question
The system SHALL allow an authenticated user to fetch the daily question for the current app day.

#### Scenario: Today question exists
- **WHEN** a signed-in user requests today’s daily question
- **THEN** the system SHALL return the question text and identifier for the question whose active date matches the current app day

### Requirement: Submit answer
The system SHALL allow an authenticated user to submit an answer to today’s daily question.

#### Scenario: First answer
- **WHEN** a signed-in user submits an answer to today’s question
- **THEN** the system SHALL create a user answer record linked to the user and the question

#### Scenario: Overwrite answer
- **WHEN** a signed-in user submits another answer for the same question
- **THEN** the system SHALL overwrite the existing answer for that user and question with the latest content

### Requirement: List my answers
The system SHALL allow an authenticated user to list their historical daily-question answers.

#### Scenario: Paginated answer history
- **WHEN** a signed-in user requests their daily-question answer history with a page size
- **THEN** the system SHALL return a paginated list ordered by most recent answer first, including question reference, answer text snippet, and timestamps


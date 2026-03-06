## ADDED Requirements

### Requirement: List friends answers for today
The system SHALL allow an authenticated user to retrieve friends’ answers to today’s daily question.

#### Scenario: Friends have answered
- **WHEN** a signed-in user requests friends’ answers for today’s question
- **THEN** the system SHALL return a list of answers only from users who are in a confirmed friendship relationship with the requester
- **AND** each item SHALL include friend identity metadata, answer text snippet, and timestamp

#### Scenario: No friends have answered
- **WHEN** a signed-in user requests friends’ answers for today’s question and none of their friends have answered
- **THEN** the system SHALL return an empty list with a successful response code

### Requirement: Exclude non-friends
The system SHALL NOT expose answers from users who are not in the requester’s friend graph.

#### Scenario: Non-friend answers excluded
- **WHEN** there exist answers to today’s question from users who are not friends with the requester
- **THEN** the system SHALL NOT include those answers in the friends’ answers response


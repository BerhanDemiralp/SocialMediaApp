## Purpose

Define how matches become successful or expired and how chats behave afterward.

## ADDED Requirements

### Requirement: Automatic success evaluation
The system SHALL automatically evaluate each active match after its 1‑hour window to determine whether it is successful or expired.

#### Scenario: Successful match by message activity
- **WHEN** the 1‑hour window for a match ends
- **AND** the total number of messages in the match between `scheduled_at` and `expires_at` is at least 10
- **AND** each participant has sent at least 1 message in that window
- **THEN** the system SHALL update the match status to `successful`

#### Scenario: Expired match by insufficient activity
- **WHEN** the 1‑hour window for a match ends
- **AND** the success criteria are not met
- **THEN** the system SHALL update the match status to `expired`

### Requirement: Chats remain accessible after expiration
The system SHALL keep chats from expired matches accessible in the user’s Messages.

#### Scenario: Access expired match chat
- **WHEN** a match has status `expired`
- **THEN** users SHALL still be able to open and read the associated chat in Messages


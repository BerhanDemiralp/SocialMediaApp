## ADDED Requirements

### Requirement: Friends daily pairing constraints
The system SHALL create at most one friends-based daily match per user per day using only accepted friendships.

#### Scenario: Friends matching pool
- **WHEN** the matching engine selects candidates for Friends Daily Pairing
- **THEN** it SHALL consider only friendships with status `accepted`

### Requirement: Group daily pairing constraints
The system SHALL create group-based daily matches using only active group memberships.

#### Scenario: Group matching pool
- **WHEN** the matching engine selects candidates for Group Daily Pairing
- **THEN** it SHALL include only users with active membership in the group

### Requirement: Group match opt-in behavior
For Group Daily Pairing, the system SHALL use an opt-in mechanism to decide if the chat becomes permanent after the 1‑hour window.

#### Scenario: Group match promoted to permanent
- **WHEN** a group-based match completes its 1‑hour window
- **AND** both users have indicated that they want to continue the conversation
- **THEN** the system SHALL keep the chat permanent and writable

#### Scenario: Group match becomes read-only
- **WHEN** a group-based match completes its 1‑hour window
- **AND** at least one user does not opt in
- **THEN** the system SHALL keep the chat as read-only history


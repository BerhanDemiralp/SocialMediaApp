## ADDED Requirements

### Requirement: Friend graph usable for filtering
The system’s friendship model SHALL support querying the set of confirmed friends for a given user for read-only filtering.

#### Scenario: Retrieve friends for filtering
- **WHEN** a backend component requests the list of confirmed friends for a given user id
- **THEN** the system SHALL return identifiers for all users who have an established mutual friendship with that user.

#### Scenario: Friends list used for matching and Home flows
- **WHEN** the system prepares daily friend pairings or renders the Home/Friends view
- **THEN** it SHALL use the confirmed friends list as the source of truth for which users can be shown as friends or candidates for daily pairing.

### Requirement: No behavior change to friendship lifecycle
The daily-questions feature and Home search/friend-request flows SHALL NOT modify how friendships are created, updated, or removed.

#### Scenario: Friendship flows unaffected
- **WHEN** users add, confirm, or remove friendships through existing flows
- **THEN** the behavior and API contracts for those flows SHALL remain unchanged despite the introduction of daily-questions and Home search/friend-request flows.


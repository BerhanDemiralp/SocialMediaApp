## ADDED Requirements

### Requirement: Moment match lifecycle storage
The database schema SHALL store daily Moment match lifecycle records.

#### Scenario: Moment match record structure
- **WHEN** a Moment match is created
- **THEN** the database SHALL store an identifier, match type, participant identifiers, linked conversation identifier, scheduled timestamp, expiration timestamp, status, created timestamp, and updated timestamp

#### Scenario: Group Moment records reference group
- **WHEN** a group Moment match is created
- **THEN** the database SHALL store the group identifier associated with the match

### Requirement: Moment status and reminder tracking
The database schema SHALL support tracking Moment lifecycle status and reminder delivery state.

#### Scenario: Status supports lifecycle
- **WHEN** a Moment is active, successful, or expired
- **THEN** the database SHALL be able to represent that status

#### Scenario: Reminder sent state
- **WHEN** a reminder is sent for a Moment
- **THEN** the database SHALL store reminder state so another reminder is not sent for the same Moment

### Requirement: Moment opt-in persistence
The database schema SHALL store per-participant opt-in state for group Moment continuation.

#### Scenario: Store participant opt-in
- **WHEN** a participant opts in to continue a group Moment conversation
- **THEN** the database SHALL persist that participant's opt-in state for the Moment

#### Scenario: Determine mutual opt-in
- **WHEN** the system evaluates a group Moment conversation after the active window
- **THEN** the database SHALL provide enough state to determine whether both participants opted in

### Requirement: Moment uniqueness and lookup indexes
The database schema SHALL support efficient and consistent lookup for daily Moment creation, expiration, history, and friend rematch cooldowns.

#### Scenario: Prevent duplicate same-type daily Moments
- **WHEN** the system creates Moment matches for a scheduled day
- **THEN** database constraints or indexes SHALL support preventing duplicate match records for the same participant and match type on that scheduled day

#### Scenario: Find recent friend pairings
- **WHEN** the system evaluates friend Moment candidates
- **THEN** database indexes SHALL support checking whether a pair was matched in the previous 7 days

#### Scenario: Find expired active Moments
- **WHEN** the system evaluates Moment expiration
- **THEN** database indexes SHALL support finding active Moment records whose expiration timestamp has passed

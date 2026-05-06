## ADDED Requirements

### Requirement: Friend Moment eligibility
The system SHALL provide eligibility rules for selecting friend Moment candidates from accepted friendships.

#### Scenario: Accepted friends are eligible
- **WHEN** two users have an accepted friendship
- **AND** neither user already has a friend Moment for the scheduled day
- **AND** the pair has not been matched in a friend Moment during the last 7 days
- **THEN** the system SHALL consider the pair eligible for friend Moment selection

#### Scenario: Recent friend pair excluded
- **WHEN** two users have already been matched in a friend Moment during the last 7 days
- **THEN** the system SHALL exclude that pair from friend Moment selection

### Requirement: Group Moment eligibility
The system SHALL provide eligibility rules for selecting group Moment candidates from group membership.

#### Scenario: Non-friend group members are eligible
- **WHEN** two users are members of the same group
- **AND** they are not accepted friends
- **AND** neither user already has a group Moment for the scheduled day
- **THEN** the system SHALL consider the pair eligible for group Moment selection

#### Scenario: Friends in same group excluded
- **WHEN** two users are accepted friends
- **AND** they are members of the same group
- **THEN** the system SHALL exclude that pair from group Moment selection

### Requirement: Group Moment opt-in state
The system SHALL track each participant's opt-in decision for continuing a group Moment conversation.

#### Scenario: Participant opts in
- **WHEN** a participant opts in to continue a group Moment conversation
- **THEN** the system SHALL record that participant's opt-in decision for the Moment

#### Scenario: Both participants opted in
- **WHEN** both group Moment participants have opted in
- **THEN** the system SHALL treat the linked group-pair conversation as permanent and writable

## ADDED Requirements

### Requirement: Daily Moment schedule
The system SHALL create daily Moment pairings at a configured predefined time.

#### Scenario: Daily scheduled run creates pairings
- **WHEN** the configured daily Moment time is reached
- **THEN** the system SHALL run the Moment pairing process for that scheduled window
- **AND** created Moment records SHALL have `scheduled_at` set to the scheduled time
- **AND** created Moment records SHALL have `expires_at` set to 1 hour after `scheduled_at`

#### Scenario: Retry does not duplicate daily pairings
- **WHEN** the daily Moment pairing process is run more than once for the same scheduled window
- **THEN** the system SHALL NOT create duplicate Moment records for the same participant, match type, and scheduled day

### Requirement: Daily match limits by type
The system SHALL allow each user to have at most one friend Moment and at most one group Moment for a scheduled day.

#### Scenario: User receives friend and group Moments
- **WHEN** a user is eligible for both friend and group pairing on the same scheduled day
- **THEN** the system SHALL allow one friend Moment for that user
- **AND** the system SHALL allow one group Moment for that user

#### Scenario: Duplicate same-type Moment blocked
- **WHEN** a user already has a friend Moment for a scheduled day
- **THEN** the system SHALL NOT create another friend Moment for that user on that scheduled day
- **AND** the same rule SHALL apply independently to group Moments

### Requirement: Friend daily pairing
The system SHALL create daily friend Moments from accepted friend relationships.

#### Scenario: Friend Moment creates or reuses permanent chat
- **WHEN** two accepted friends are paired for a friend Moment
- **THEN** the system SHALL create or reuse a permanent writable friend conversation for those users
- **AND** the friend Moment SHALL reference that conversation

#### Scenario: Friend rematch cooldown
- **WHEN** two friends were matched in a friend Moment less than 7 days ago
- **THEN** the system SHALL exclude that pair from friend Moment candidate selection

#### Scenario: Friend pair becomes eligible after cooldown
- **WHEN** two friends were last matched in a friend Moment at least 7 days ago
- **THEN** the system SHALL allow that pair to be selected again if both users are otherwise eligible

### Requirement: Group daily pairing
The system SHALL create daily group Moments from eligible group members who are not friends.

#### Scenario: Group Moment creates temporary chat
- **WHEN** two non-friend users from a shared group are paired for a group Moment
- **THEN** the system SHALL create a temporary group-pair conversation for those users
- **AND** the group Moment SHALL reference the shared group and conversation

#### Scenario: Friends excluded from group pairing
- **WHEN** two users are accepted friends
- **AND** they are members of the same group
- **THEN** the system SHALL NOT pair them together for a group Moment

### Requirement: Moment notifications and reminders
The system SHALL notify both participants when a Moment starts and SHALL send one inactivity reminder when the reminder condition is met.

#### Scenario: Match start notification
- **WHEN** a Moment is created
- **THEN** the system SHALL enqueue or send a notification to both participants

#### Scenario: Single inactivity reminder
- **WHEN** a Moment is active
- **AND** the configured inactivity reminder condition is met
- **AND** no reminder has already been sent for that Moment
- **THEN** the system SHALL enqueue or send one reminder to the inactive participant or participants
- **AND** the system SHALL record that the reminder was sent

### Requirement: Moment success and expiration
The system SHALL evaluate each Moment at the end of its 1-hour active window.

#### Scenario: Successful Moment
- **WHEN** a Moment reaches `expires_at`
- **AND** at least 10 total messages were sent in the linked conversation between `scheduled_at` and `expires_at`
- **AND** each participant sent at least one message in that window
- **THEN** the system SHALL mark the Moment as successful

#### Scenario: Expired Moment
- **WHEN** a Moment reaches `expires_at`
- **AND** the success condition is not met
- **THEN** the system SHALL mark the Moment as expired
- **AND** the linked chat history SHALL remain accessible from Messages

### Requirement: Group Moment permanence by mutual opt-in
The system SHALL make group Moment conversations permanently writable only when both participants opt in.

#### Scenario: Mutual opt-in keeps group chat writable
- **WHEN** both participants opt in to continue a group Moment conversation
- **THEN** the system SHALL keep the linked conversation writable for both participants after the active window

#### Scenario: Missing opt-in makes group chat read-only
- **WHEN** a group Moment active window ends
- **AND** both participants have not opted in to continue
- **THEN** the system SHALL keep the linked conversation visible in Messages
- **AND** the system SHALL prevent new messages in that conversation

### Requirement: Home active Moment visibility
The system SHALL expose active Moment pairings for display on the Home page.

#### Scenario: Home shows active Moments
- **WHEN** an authenticated user has an active friend Moment or group Moment
- **THEN** the system SHALL return the active Moment data needed for Home display
- **AND** the response SHALL distinguish friend Moments from group Moments
- **AND** the response SHALL include expiration timing and participant summary information

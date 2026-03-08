## ADDED Requirements

### Requirement: Moment schedule visibility
The app SHALL clearly communicate the daily Moment schedule and whether a Moment is upcoming, active, or over.

#### Scenario: Upcoming Moment
- **WHEN** a user opens the app before the next scheduled Moment window
- **THEN** the app SHALL show the scheduled time of the next Moment and optionally a countdown or time indicator

#### Scenario: Active Moment window
- **WHEN** a user opens the app during an active Moment window
- **THEN** the app SHALL indicate that the Moment is active and provide a clear action to view or join their current match

### Requirement: Match presentation for friends and groups
The app SHALL present the user’s active Moment match differently for friends mode and groups mode while respecting their semantics.

#### Scenario: Friends mode match
- **WHEN** a user is matched with a friend in friends mode during a Moment
- **THEN** the app SHALL show the friend’s identity, open a writable chat, and treat the chat as permanent after the Moment succeeds

#### Scenario: Groups mode match
- **WHEN** a user is matched with a group member in groups mode during a Moment
- **THEN** the app SHALL show the partner’s basic profile, indicate the temporary nature of the chat, and explain that the chat becomes permanent only with mutual opt-in after the window

### Requirement: Moment completion feedback
The app SHALL provide clear feedback when a Moment succeeds or ends without success.

#### Scenario: Successful Moment
- **WHEN** a Moment chat reaches the success condition defined by the backend (e.g., 10+ total messages with each user sending at least one)
- **THEN** the app SHALL inform the user that the Moment was successful and ensure the chat remains accessible in the Messages section

#### Scenario: Expired Moment without success
- **WHEN** a Moment window expires without meeting the success condition
- **THEN** the app SHALL indicate that the Moment has ended and adjust the chat state according to product rules (e.g., read-only or archived) while keeping past messages accessible if required


## ADDED Requirements

### Requirement: Core chat interaction
The app SHALL provide a message list and message composer that allow users to send and receive text messages within a chat.

#### Scenario: Sending a message
- **WHEN** a user types a valid message and taps send
- **THEN** the app SHALL display the message in the list, attempt delivery to the backend, and show a clear status (e.g., sending, sent, failed)

#### Scenario: Receiving a message in an open chat
- **WHEN** a new message arrives for an open chat while the user is viewing it
- **THEN** the app SHALL append the message to the list without requiring manual refresh and maintain the user’s scroll position appropriately

### Requirement: Temporary vs permanent chats
The app SHALL distinguish between temporary and permanent chats and reflect their states in the UI.

#### Scenario: Temporary chat in groups mode
- **WHEN** a user opens a temporary chat created from a groups-mode Moment
- **THEN** the app SHALL indicate that the chat is temporary, show the remaining active window or expiration state, and explain what happens after the window closes

#### Scenario: Permanent chat after success
- **WHEN** a temporary chat meets the success condition and becomes permanent
- **THEN** the app SHALL update the chat’s state so it appears alongside other permanent chats in the Messages section without temporary labels

### Requirement: Safety and moderation entry points
The app SHALL provide clear entry points to block or report another user from within a chat.

#### Scenario: Blocking a user from chat
- **WHEN** a user chooses to block another user from a chat
- **THEN** the app SHALL confirm the action, prevent future messages from that user, and reflect the block state in the UI according to product rules

#### Scenario: Reporting a user from chat
- **WHEN** a user chooses to report another user from a chat
- **THEN** the app SHALL collect a minimal required reason, confirm submission, and avoid leaving the chat in an ambiguous state (e.g., clearly indicate if the conversation is closed)


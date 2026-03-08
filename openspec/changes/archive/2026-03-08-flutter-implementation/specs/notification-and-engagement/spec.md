## ADDED Requirements

### Requirement: Daily question reminder notification
The app SHALL send a daily reminder notification to help the user answer the daily question, respecting platform best practices and user notification settings.

#### Scenario: Reminder when notifications are enabled
- **WHEN** it is time for the daily question reminder and the user has notifications enabled for the app
- **THEN** the app SHALL show a notification that deep links into the daily question screen

#### Scenario: No reminder when notifications are disabled
- **WHEN** the user has disabled notifications for the app at the OS or in-app level
- **THEN** the app SHALL NOT attempt to show the daily question reminder notification

### Requirement: Match and message notifications
The app SHALL notify users about new Moment matches and new messages in a way that reinforces the habit loop without creating a high-pressure environment.

#### Scenario: New Moment match notification
- **WHEN** the backend creates a new Moment match for the user
- **THEN** the app SHALL show a notification that clearly indicates the match and deep links into the corresponding chat or Moment view

#### Scenario: New message notification
- **WHEN** a new message arrives for a chat while the user is not actively viewing that chat
- **THEN** the app SHALL show a notification (if permitted) that deep links into the chat, and avoid sending redundant notifications when multiple messages arrive in quick succession

### Requirement: No engagement via infinite feeds or streak pressure
The engagement system SHALL avoid infinite feeds and high-pressure streak mechanics that conflict with MOMENT’s cozy, low-pressure positioning.

#### Scenario: No infinite feed engagement surfaces
- **WHEN** the app presents engagement surfaces related to notifications (e.g., inbox, activity list)
- **THEN** the app SHALL avoid infinite scrolling lists designed purely for engagement and instead focus on actionable items (questions, matches, conversations)

#### Scenario: Soft streak-style reinforcement
- **WHEN** the app reinforces consistency (e.g., by showing a gentle streak indicator)
- **THEN** the app SHALL present it in a low-pressure, reversible way without harsh penalties, loss aversion messaging, or public streak metrics


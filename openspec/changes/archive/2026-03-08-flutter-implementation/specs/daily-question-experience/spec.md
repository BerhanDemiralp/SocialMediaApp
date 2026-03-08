## ADDED Requirements

### Requirement: Daily question availability
The app SHALL display the current daily question to the user once per day and clearly indicate whether the user has answered it.

#### Scenario: User has not answered today’s question
- **WHEN** a user opens the app on a day when they have not yet answered the daily question
- **THEN** the app SHALL prominently display the daily question and allow the user to answer it

#### Scenario: User has already answered today’s question
- **WHEN** a user opens the app after answering the daily question for that day
- **THEN** the app SHALL indicate that the question is complete and hide or disable the answer input

### Requirement: Unlocking friends’ answers
The app SHALL require the user to answer the daily question before revealing friends’ answers.

#### Scenario: Viewing friends’ answers before answering
- **WHEN** a user attempts to view friends’ answers before submitting their own answer
- **THEN** the app SHALL prevent access to friends’ answers and explain that they must answer first

#### Scenario: Viewing friends’ answers after answering
- **WHEN** a user submits their answer to the daily question
- **THEN** the app SHALL reveal friends’ answers as cards for that day

### Requirement: Answer cards and entry into chat
The app SHALL present each friend’s answer as a card with a clear action to start or continue a conversation.

#### Scenario: Opening chat from an answer card
- **WHEN** a user taps the reply or chat action on a friend’s answer card
- **THEN** the app SHALL open or focus the corresponding chat with that friend, carrying over context about the question where appropriate

#### Scenario: Empty state when no friends answered
- **WHEN** a user has answered the daily question but none of their friends have answered yet
- **THEN** the app SHALL show a friendly empty state that reinforces the habit (e.g., “We’ll show your friends’ answers here once they respond”) instead of a blank list


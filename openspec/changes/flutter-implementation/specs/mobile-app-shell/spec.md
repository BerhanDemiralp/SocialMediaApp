## ADDED Requirements

### Requirement: App launches into appropriate entry screen
The Flutter app SHALL route users to the correct entry screen based on their authentication state and any pending deep link or notification intent.

#### Scenario: Unauthenticated user opens the app
- **WHEN** a user opens the app and has no valid auth session
- **THEN** the app SHALL show the onboarding/auth flow before any main content

#### Scenario: Authenticated user opens the app
- **WHEN** a user opens the app with a valid auth session
- **THEN** the app SHALL navigate directly to the main shell (e.g., Home tab) without showing the auth flow

#### Scenario: User opens the app from a notification
- **WHEN** a user taps a supported push notification (e.g., new message, active Moment)
- **THEN** the app SHALL route to the relevant screen (e.g., chat, Moment) after establishing or restoring the auth session

### Requirement: App shell structure and navigation
The app shell SHALL provide a consistent navigation structure with clearly labeled entry points for Home, Messages, and Profile/Settings while respecting the cozy, non‑feed UX constraints.

#### Scenario: Navigating between main sections
- **WHEN** a user taps a main navigation item (e.g., Home, Messages, Profile)
- **THEN** the app SHALL switch to the selected section and preserve reasonable in-section state (e.g., scroll position, selected chat)

#### Scenario: No infinite scrolling feeds
- **WHEN** a user browses any main section
- **THEN** the app SHALL avoid infinite scroll/feed patterns and instead present focused surfaces for questions, matches, and chats

### Requirement: Error and loading handling
The app shell SHALL present clear loading and error states without blocking the user unnecessarily or leaking technical details.

#### Scenario: Transient network failure
- **WHEN** a network request used to load initial data fails transiently
- **THEN** the app SHALL show a non-technical error message, allow the user to retry, and avoid leaving the UI in a broken state

#### Scenario: Irrecoverable app error
- **WHEN** an unexpected irrecoverable error occurs during app startup
- **THEN** the app SHALL show a friendly fallback screen with an option to restart the app or contact support, without exposing stack traces or internal identifiers


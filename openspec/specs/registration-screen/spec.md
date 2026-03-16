## Purpose

The registration capability defines how a new user creates an account in MOMENT using email, username, and password, and how that flow interacts with validation, backend behavior, and analytics.

## Requirements

### Requirement: User can register with email, username, and password
The system SHALL provide a dedicated registration screen that allows a new user to create an account using email, username, and password, and enter the authenticated Home experience upon success.

#### Scenario: Successful registration
- **WHEN** a user opens the registration screen, fills in a valid email, a username, and a valid password, and taps the register button
- **THEN** the system SHALL create a new account using the provided credentials (without requiring the username to be globally unique), persist an authenticated session, and navigate the user to the Home shell

#### Scenario: Registration screen entry from login
- **WHEN** an unauthenticated user is on the login/auth gate screen and taps the “Create account” or equivalent CTA
- **THEN** the system SHALL navigate to the registration screen without losing the ability to return to the login screen

### Requirement: Client-side validation on registration fields
The registration screen SHALL validate input locally before sending a registration request to the backend, preventing obviously invalid submissions.

#### Scenario: Disabled submit for invalid form
- **WHEN** the email is empty or clearly malformed, OR the username is empty, OR the password does not meet the minimum length
- **THEN** the registration submit button SHALL be disabled, and the user SHALL see inline validation hints indicating what needs to be fixed

#### Scenario: Inline error messages for invalid fields
- **WHEN** a user focuses and then leaves a registration field (email, username, password) with invalid input
- **THEN** the screen SHALL display an inline error message near the field describing the problem in user-friendly language

### Requirement: Server-side errors are mapped to user-friendly messages
The registration flow SHALL interpret backend error responses and show clear messages to the user, with field-level errors when possible.

#### Scenario: Email already in use
- **WHEN** the backend rejects a registration attempt because the email is already associated with an existing account
- **THEN** the registration screen SHALL show a specific error message indicating that the email is already in use, associated to the email field where possible

#### Scenario: Generic server or network error
- **WHEN** the registration request fails due to an unexpected server error or network problem
- **THEN** the registration screen SHALL display a non-blocking banner or SnackBar with a generic error message and SHALL allow the user to retry after correcting any issues

### Requirement: Registration does not break existing login flow
The introduction of the registration screen SHALL NOT change the behavior of the existing login flow for returning users.

#### Scenario: Login remains unchanged
- **WHEN** a returning user opens the app and navigates to the login screen
- **THEN** the login behavior (form, validation, navigation to Home shell) SHALL remain consistent with the previous implementation, aside from the ability to navigate to the registration screen

### Requirement: Analytics for registration funnel
The system SHALL emit analytics events that capture key steps in the registration funnel to enable monitoring and optimization.

#### Scenario: Registration started
- **WHEN** a user navigates to the registration screen
- **THEN** the app SHALL emit a `registration_started` event including at least an anonymous user/session identifier

#### Scenario: Registration submitted and outcome
- **WHEN** a user taps the submit button on the registration screen
- **THEN** the app SHALL emit a `registration_submitted` event, followed by either `registration_succeeded` on success or `registration_failed` with an error type on failure


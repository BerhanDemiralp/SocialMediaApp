## 1. Flutter UI & Navigation

- [x] 1.1 Add a `/auth/register` route to `app_router.dart` that renders a new `RegistrationScreen` widget.
- [x] 1.2 Implement `RegistrationScreen` in the auth presentation layer with email, username, and password fields plus a submit button.
- [x] 1.3 Add navigation from the existing login/auth gate screen to the registration screen (e.g., “Create account” CTA) and back.
- [x] 1.4 Ensure that successful registration navigates to the authenticated Home shell and that the back stack behaves correctly.

## 2. Registration State & Validation

- [x] 2.1 Introduce a Riverpod registration controller/provider to manage form state (values, loading, error messages).
- [x] 2.2 Implement client-side validation rules for email, username, and password, and keep the submit button disabled when the form is invalid or a request is in-flight.
- [x] 2.3 Wire inline validation messages for each field (email, username, password) that update as the user focuses/blurs and edits.
- [x] 2.4 Handle generic error states (e.g., network/server errors) with a non-blocking banner or SnackBar and allow the user to retry.

## 3. Backend Integration

- [x] 3.1 Add or update an auth API client method in Flutter that calls the existing NestJS/Supabase registration endpoint with email, username, and password.
- [x] 3.2 Ensure the backend returns a consistent payload (session token + basic user profile) and that the client saves the session via Supabase Flutter.
- [x] 3.3 Map backend/Supabase auth errors (e.g., email already in use, weak password, generic failure) to user-friendly error messages on the registration screen.
- [x] 3.4 Verify that the new registration flow does not break or alter the existing login endpoint behavior.

## 4. Analytics & Observability

- [x] 4.1 Emit a `registration_started` analytics event when the registration screen is shown.
- [x] 4.2 Emit a `registration_submitted` event when the user taps the submit button.
- [x] 4.3 Emit `registration_succeeded` on successful account creation and `registration_failed` with an appropriate failure type (validation/server/network) when registration fails.
- [x] 4.4 Confirm analytics events appear correctly in the configured analytics sink (locally or staging, as available).

## 5. Testing

- [x] 5.1 Add widget tests for the registration screen to cover disabled submit on invalid form and inline validation messaging.
- [x] 5.2 Add a widget or integration test that simulates a successful registration and verifies navigation to the Home shell.
- [x] 5.3 Add a widget test that simulates backend error responses (e.g., email already in use, generic error) and checks that the correct user-facing error messages are shown.
- [x] 5.4 Manually QA the registration flow on at least one platform (e.g., Edge/web or Android emulator), including navigation back to login and behavior for existing accounts.

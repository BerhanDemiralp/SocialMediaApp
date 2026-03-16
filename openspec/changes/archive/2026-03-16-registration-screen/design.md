## Context

The MOMENT app already has an authentication flow backed by Supabase Auth and a NestJS auth module, but it lacks a dedicated, coherent registration experience. New users can technically create accounts, yet there is no single registration screen that:

- Explains what MOMENT is and why to sign up.
- Collects the core fields (email, username, password) with consistent validation.
- Maps backend/auth errors to clear, user-friendly messages.
- Drops the user into the authenticated Home shell on success.

This design introduces a registration screen in the Flutter app that uses existing backend and Supabase capabilities without adding new tables or major backend surface area. It also keeps the auth flow consistent with the current routing and state management patterns.

## Goals / Non-Goals

**Goals:**

- Provide a single, well-structured registration screen in Flutter that:
  - Collects email, username, and password.
  - Validates fields locally before making a network request.
  - Shows clear errors for both client- and server-side validation issues.
  - Navigates to the Home shell after successful registration.
- Reuse the existing NestJS auth module and Supabase Auth for user creation.
- Keep the login flow intact and make it easy to switch between login and registration.
- Add analytics hooks around registration (start, submit, success, failure).
- Keep the implementation testable with widget tests for form behavior and error handling.

**Non-Goals:**

- Changing the underlying Supabase project, auth configuration, or `users` table schema.
- Implementing social sign-in providers (Google/Apple/etc.).
- Implementing extended profile completion (avatar, groups, friends) after registration.
- Introducing a multi-step onboarding wizard beyond this single registration screen.
- Redesigning the entire auth UX; the focus is only the registration entry point and immediate flow.

## Decisions

1. **UI placement and navigation**
   - Add a dedicated `RegistrationScreen` under the existing auth feature module (e.g., `lib/features/auth/presentation/registration_screen.dart`).
   - Reuse the existing routing mechanism (`GoRouter` + `appRouterProvider`) and add a route like `/auth/register`.
   - From the login/auth gate screen, add a “Create account” button that navigates to `/auth/register`, and from the registration screen provide a “Already have an account? Log in” action back to `/auth`.
   - Rationale: Keeps all auth-related navigation centralized, consistent with current router usage, and avoids fragmenting auth flows.

2. **State management and architecture**
   - Use the existing Riverpod-based pattern: introduce a `registrationControllerProvider` or reuse a shared auth controller dedicated to registration.
   - The controller will hold form state (loading, error message) and coordinate calls to an `AuthRepository`/API client.
   - Rationale: Aligns with existing app architecture (Clean Architecture + Riverpod) and keeps business logic out of widgets, making it easy to test.

3. **Backend integration**
   - Use the existing NestJS auth module’s `register` endpoint (or add a thin wrapper if needed) that ultimately calls `AuthService.register` and Supabase’s `auth.signUp`.
   - The Flutter registration API client will POST email, password, and username; the backend remains responsible for:
     - Creating the Supabase auth user.
     - Creating the corresponding row in `users` (if not already auto-synced).
     - Returning a session token and minimal user profile payload.
   - Rationale: Avoids duplicating auth logic in a new endpoint and keeps all registration logic in one place on the backend.

4. **Validation strategy**
   - Client-side:
     - Email: basic format check (contains `@`, non-empty).
     - Username: non-empty, minimal length, maybe a simple character set check (letters, numbers, underscores).
     - Password: minimal length requirement (e.g., 8 characters), non-empty.
     - Disable submit button while fields are invalid or a request is in-flight.
   - Server-side:
     - Treat HTTP error status + JSON payload from the backend as source of truth for detailed errors:
       - Email already registered.
       - Username already taken.
       - Weak password or other Supabase constraints.
       - Generic fallback (“Something went wrong. Please try again.”).
   - Rationale: Client-side checks provide instant feedback; server-side validation enforces real rules and prevents false positives.

5. **Error mapping and UX**
   - Map backend error codes/messages to specific field-level errors when possible (e.g., “Email already in use” under the email field).
   - For unexpected errors (network issues, unknown server error), show a non-blocking banner/SnackBar plus a generic message.
   - Ensure that error state does not stick forever: pressing “Submit” again after correction should clear the error banner and revalidate.
   - Rationale: Gives users actionable feedback while avoiding confusing or persistent error states.

6. **Analytics**
   - Emit analytics events through the existing analytics provider:
     - `registration_started` when the user lands on the registration screen.
     - `registration_submitted` when the user taps the submit button.
     - `registration_succeeded` when the backend call succeeds.
     - `registration_failed` with error type (validation/server/network) when it fails.
   - Rationale: Provides a simple funnel to measure where users drop off and whether validation issues are common.

7. **Tests**
   - Add widget tests for the registration screen:
     - Ensuring the submit button is disabled until required fields are filled.
     - Verifying that invalid input triggers local validation errors.
     - Verifying that a simulated backend error (e.g., username taken) is surfaced to the user.
   - Optionally, add a happy-path integration test that stubs the network client and confirms navigation to the Home shell on success.
   - Rationale: Registration is a critical entry point; regressions should be caught automatically.

## Risks / Trade-offs

- **Risk: Validation rules drift between client and server**
  - *Mitigation:* Keep client-side validation intentionally simple and treat server responses as authoritative; when in doubt, show server error messages. Document core backend constraints (e.g., minimum password length) and mirror them in the client where reasonable.

- **Risk: Error mapping becomes brittle if backend error shapes change**
  - *Mitigation:* Centralize error parsing in the auth API client, and fall back to a generic error message if the shape doesn’t match. Avoid relying on low-level Supabase error strings; prefer stable codes or high-level messages from the NestJS layer.

- **Risk: Inconsistent navigation if registration route is not integrated cleanly**
  - *Mitigation:* Define routes in a single place (`app_router.dart`) and ensure that both login and registration flows share the same auth gate logic (redirects based on authentication state). Test navigation paths in widget tests.

- **Risk: Registration flow stalls if Supabase or backend is unavailable**
  - *Mitigation:* Show clear network error messages and allow users to retry. Emit `registration_failed` analytics with a failure type to monitor reliability issues.

- **Risk: Future onboarding steps (profile completion, groups, friends) change the first-time experience**
  - *Mitigation:* Keep the registration screen focused only on account creation and immediate entry into the existing Home shell. Design the flow so additional onboarding steps can be layered after registration without breaking the current path.


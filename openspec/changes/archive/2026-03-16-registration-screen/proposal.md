## Why

New users currently have no dedicated, guided way to create an account inside the MOMENT app. Account creation flows are handled through low‑friction auth screens, but there is no focused registration experience that clearly explains the value, validates input, and connects to our existing Supabase / backend auth stack. This increases drop‑off at first launch and makes onboarding inconsistent across platforms.

## What Changes

- Add a dedicated Flutter registration screen that:
  - Collects email, username, and password with inline validation and clear error states.
  - Explains in one short sentence what MOMENT is and why to sign up now.
  - Links to login for existing users and to terms/privacy (even if just as placeholders in this change).
- Wire the registration screen into the existing auth flow:
  - Use existing backend/Supabase registration endpoints (no new auth API surface).
  - On successful registration, persist the Supabase session and navigate into the authenticated Home shell.
- Define registration validation rules and error mapping:
  - Client‑side checks (basic format, password length, required fields).
  - Server‑side error mapping (email already used, username taken, weak password, generic failure).
- Integrate analytics for registration:
  - Track events for “registration_started”, “registration_submitted”, “registration_succeeded”, “registration_failed”.
- Ensure the registration flow is testable:
  - Add widget- and/or integration‑test targets around the registration screen for happy path and common error cases.

## Capabilities

### New Capabilities

- `registration-screen`: User‑facing registration UI and flow that lets new users create an account with email, username, and password, and land in the authenticated Home experience.

### Modified Capabilities

- `auth`: Extend existing authentication behavior to include a first‑class registration path and well‑defined validation/error handling semantics, without changing how existing login works.

## Impact

- **Frontend (Flutter)**
  - New registration screen widget(s) under the auth feature module.
  - Routing updates so unauthenticated users can choose between login and registration, and so registration success routes into the Home shell.
  - New controller/state logic for:
    - Submitting registration.
    - Showing loading / errors / disabled state for the submit button.
    - Simple field validation and error messages.
  - New tests covering registration form behavior and navigation.

- **Backend / Auth**
  - Reuse existing NestJS auth module and Supabase Auth integration for user creation (no new tables).
  - Clearly document expected request/response shapes and error codes so the Flutter client can map them to user‑friendly messages.

- **Database**
  - No new tables; relies on existing `users` table and Supabase Auth user IDs.

- **Analytics / Observability**
  - New events for registration funnel (start, submit, success, failure).
  - Potential logging of validation failures and error types to help tune the UX later.

- **Future Work (not in this change, but enabled by it)**
  - Add optional profile completion steps after registration (avatar, groups, initial friends).
  - A/B test variants of the registration copy and layout to improve conversion.


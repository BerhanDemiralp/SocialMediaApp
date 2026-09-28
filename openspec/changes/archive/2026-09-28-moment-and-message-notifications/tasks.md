## 1. Integration baseline and configuration

- [x] 1.1 Audit all message persistence paths and Moment activation/reminder transactions; identify enqueue boundaries and capture regression baseline.
- [x] 1.2 Select compatible Firebase dependencies and document Android/iOS identifiers, configuration inputs, feature flags and unavailable external prerequisites.

## 2. Registration and persistence

- [x] 2.1 Add Prisma installation, notification-intent and delivery models with ownership constraints, event uniqueness, lease/retry fields and an additive migration.
- [x] 2.2 Implement authenticated installation upsert/delete with validation, rotation, account reassignment and ownership checks.
- [x] 2.3 Test registration idempotency, unauthorized operations, stale cleanup, account switching and schema constraints.

## 3. Event production and delivery

- [x] 3.1 Implement a Firebase transport adapter with explicit configuration validation, redacted diagnostics and classified provider errors.
- [x] 3.2 Implement durable enqueue and per-installation delivery claims, bounded retries, expiry, invalid-registration cleanup and no-device handling.
- [x] 3.3 Replace the Moment no-op binding and atomically persist activation/start intents and reminder markers/intents; preserve current eligibility rules.
- [x] 3.4 Enqueue new-message intents transactionally for direct, group-pair and persistent group participants across HTTP/socket paths, excluding the sender.
- [x] 3.5 Recheck access, installation ownership and reminder freshness at dispatch; construct generic text and versioned destination data.
- [x] 3.6 Test rollback/crash boundaries, duplicate enqueue, concurrent claims, lease recovery, partial provider failure, invalid registration, stale reminders and revoked access.

## 4. Flutter integration

- [x] 4.1 Add conditional mobile Firebase initialization and an account-scoped notification feature; keep unconfigured/web startup functional.
- [x] 4.2 Implement deliberate permission UI and installation registration/refresh/resume/logout lifecycle, including pending offline cleanup and late-callback guards.
- [x] 4.3 Handle foreground events with per-event deduplication and suppress notices for the visible conversation without duplicating background OS alerts.
- [x] 4.4 Handle cold-start/background taps through an auth-ready destination queue and authorized metadata lookup; preserve shared chat navigation and read-only behavior.
- [x] 4.5 Test permission denial, unavailable configuration, account changes, deferred taps, duplicate taps, open-chat suppression and denied destinations.

## 5. Configuration and real-device acceptance

- [x] 5.1 Configure Firebase Android, permissions/channels and server credentials; document setup without committing secrets. iOS/APNs is deferred by user scope decision.
- [x] 5.2 Apply the additive migration to the intended test environment and configure backend credentials/worker; verify migration and feature-disable rollback instructions.
- [ ] 5.3 Verify Android delivery using two accounts: Moment start/reminder, direct/group messages, foreground/background/cold-start taps, logout and denied permissions.
- [x] 5.4 Record user-requested deferral of iOS setup/build/device acceptance outside MVP; retain follow-up prerequisites in the setup guide. This is a scope change, not a passed iOS test.

## 6. Verification and tracking

- [x] 6.1 Run backend tests/build, Prisma validation, Flutter analysis/tests and relevant platform builds; record delivery limitations separately from automated results.
- [x] 6.2 Verify implementation against the change specs and document configuration, diagnostics and rollout steps.
- [x] 6.3 Update MVP_TAMAMLAMA_SURECLERI.md with completed milestones and the next step; do not mark notification delivery complete until Android acceptance checks pass.

## Evidence and remaining prerequisites (2026-09-28)

- MVP platform: Android only, explicitly revised by user. iOS/APNs setup and acceptance are deferred, not verified; existing scaffolding remains.
- User confirmed Pixel_7 emulator permission, background direct-message notification/tap, cold-start tap opening the correct conversation after swipe-away, group-message delivery and open-chat live updates.
- Android Moment delivery/taps, denial/logout/account-switch matrix remain open in 5.3. See `docs/moment-notification-test-results.md`; automated transport acceptance does not prove OS delivery.
- Previous validation: 100 backend tests, 69 Flutter tests, clean Flutter analysis, configured Android APK/web builds. Synchronization evidence: `docs/synchronization-test-results.md`.
- Additive migration applied to the user-approved development/test database; RLS verified. Credentials and client configuration stay outside Git.
- Real PostgreSQL test results are recorded in `docs/moment-notification-test-results.md`. Concurrent enqueue exposed a unique-key race; production enqueue now uses conflict-safe insert followed by lookup.
- Setup: `docs/notification-setup.md`. Roadmap: `notes_for_me/MVP_TAMAMLAMA_SURECLERI.md`. The change was archived at the user's request with Android task 5.3 still open.

- Latest execution: 28/28 real PostgreSQL tests and 104/104 backend regression tests passed. Disposable schema cleanup was verified. Overall: 22/23 tasks complete; Android device acceptance (5.3) remains open.
- Android emulator follow-up: user confirmed friend Moment start, no-message reminder, reminder suppression after a message, group Moment notification opening the correct Moment screen, and the conditional Android notification-settings link. Device permission restoration/new delivery, foreground/cold-start Moment tap, logout/account switch and revoked access remain unverified. Task 5.3 stays open.

## Why

Moment notifications currently resolve through a no-op service, and users do not receive a push when new messages arrive. The MVP needs timely invitations back into a conversation even when the app is in the background, with notification taps opening the correct authorized chat.

## What Changes

- Add mobile push registration and lifecycle management for authenticated installations, including permission denial, refresh, logout, account switching, and invalid registrations.
- Deliver Moment-start, existing inactivity-reminder, and persisted-new-message notifications through Firebase Cloud Messaging; use APNs for iOS delivery through Firebase.
- Add durable notification intents and bounded retry processing so external delivery failures do not fail message sends or matching runs.
- Handle foreground notifications and background/cold-start taps with account and conversation access checks; avoid redundant notices for the open conversation.
- Add configuration guidance, migration files, automated coverage, and an explicit real-device acceptance checklist.
- Track the wider MVP roadmap in `MVP_TAMAMLAMA_SURECLERI.md`.

## Capabilities

### New Capabilities
- `mobile-push-notifications`: Device registration, notification event production and delivery, permissions, account-safe navigation, retry and duplicate handling, and deployment verification.

### Modified Capabilities
None. Existing matching eligibility, reminder timing, message authorization, and writable/read-only rules remain the authority.

## Impact

- Backend: notification module and authenticated registration API; integration with matching-engine, conversations and all message creation paths; Prisma schema and migration.
- Flutter: notification feature, startup/auth lifecycle wiring, router integration, Firebase dependencies and Android/iOS configuration.
- Infrastructure: Firebase project configuration, server credentials outside source control, and APNs configuration for iOS.
- Confirmed MVP scope (updated by user on 2026-09-28): Android only. iOS/APNs setup and device acceptance are deferred outside this change; existing cross-platform scaffolding is retained. Web remains runnable without push configuration; browser push is outside this change.
- Actual remote setup, device delivery and migration execution require configured environments; proposal completion is not delivery completion. No automatic commit or push.

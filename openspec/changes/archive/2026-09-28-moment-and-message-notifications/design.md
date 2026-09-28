## Context

MomentNotificationService currently resolves to a no-op. MatchingEngineService invokes start notifications on activation and reminders when a due Moment has zero messages, then marks the reminder. ConversationsService.createMessageForConversation persists messages and is used by the socket gateway; implementation must also audit HTTP and legacy paths. Flutter has no Firebase dependencies. Supabase remains the authentication authority.

The user revised MVP scope on 2026-09-28 to Android only. iOS configuration and acceptance are deferred; existing iOS scaffolding is retained. Web development must continue without push configuration. Preserve shared chat navigation, account isolation, matching eligibility and writable/read-only rules.

## Goals / Non-Goals

Goals: Moment-start, existing inactivity-reminder and new-message notifications; account-safe conversation opening; permission and registration lifecycle; bounded retries independent of external delivery availability.

Non-goals: browser push, unread counts, read receipts, friend-request notifications, marketing messages, a notification inbox, quiet hours or new matching/reminder rules. OS delivery is best-effort, not guaranteed or exactly-once.

## Decisions

### Transport and registrations

Use Firebase Cloud Messaging for both platforms, with APNs configured through Firebase for iOS. Keep the server transport behind an interface. Confirm compatible stable SDK versions and supported provider registration identifiers against official documentation during implementation. Avoid tying the database abstraction to a permanently stable token format.

Add authenticated installation upsert and ownership-checked delete APIs, proposed under `/api/notifications/installations`. Store installation identity, owner, platform, provider registration identifier, enabled state and last-seen time. Enforce unique active ownership and atomically rotate/reassign registrations on account changes. The client never supplies the recipient account as authority. Never log identifiers or credentials.

Separate direct APNs/FCM implementations duplicate work; client-side sends would expose privileged credentials. Neither is needed.

### Durable intents and worker

Use a PostgreSQL outbox and per-installation delivery records instead of adding a separate queue service to the MVP. Logical event keys are `(kind, source_id, recipient_id)`; delivery keys additionally identify the installation. Atomically claim work with an expiring lease; record attempts, next-attempt time and redacted failure categories. Retry transient failures with bounded backoff, disable confirmed invalid registrations, and expire stale work. Do not replay old events when an account registers its first device.

Commit message intents in the same transaction as message persistence. Make Moment activation/start-intent persistence atomic, and reminder marking/reminder-intent persistence atomic. Audit repository boundaries to close the crash gap between a state change and enqueue. A reminder marker means durable scheduling, not confirmed device receipt. FCM network calls happen only in the worker; provider failures must not fail accepted messages or matching runs.

Direct fire-and-forget calls risk losing events on restart. Waiting for FCM in business transactions unnecessarily couples messaging to provider availability.

### Recipients and privacy

Moment-start events target both participants. Preserve existing due-time and zero-message reminder eligibility; suppress queued reminders if the Moment ends or receives messages before dispatch. New-message events target current authorized participants other than the sender in direct, group-pair and persistent group chats. Recheck membership/access and installation ownership immediately before dispatch.

Use generic lock-screen text rather than message previews. Versioned data carries event ID, kind, intended account ID, conversation ID and optional Moment/message ID; none grants access. Expire Moment events at the Moment deadline and message events after a configurable short lifetime. Avoid public topics.

### Flutter lifecycle and presentation

Initialize only on supported, configured mobile platforms. Ask permission at a deliberate post-login entry point with explanatory UI. Denial must not block the app or cause repeated prompts. Register after auth and permission; update on provider refresh and resume. Detach before ordinary logout; retain pending cleanup for offline logout and supersede ownership when accounts switch. An OS notification already accepted by the provider can still arrive after logout, so use generic content and tap-time account checks.

Use a single in-app notice for foreground delivery and suppress it when the same conversation is visible. Do not display an additional local notification for OS-rendered background delivery. Deduplicate by event ID; do not claim exactly-once OS display after ambiguous provider acceptance. An open socket does not establish that a chat is visible.

### Navigation

Handle terminated-app launch and background notification taps. Queue a validated destination until auth/router readiness, require the intended account, resolve authorized conversation metadata, and open a known-ID chat through shared navigation. Avoid duplicate routes when already open. Expired Moments retain existing read-only/permanent semantics. Missing access produces non-blocking feedback on a safe screen, never a newly created conversation or friendship.

## Risks / Trade-offs

- Provider acceptance is not device receipt -> separate queued/accepted/failed/expired records and require real-device evidence.
- Crash after acceptance can duplicate an OS alert -> stable event IDs and per-device records reduce duplicates without promising exactly-once delivery.
- Offline logout delays cleanup -> pending local cleanup, current ownership checks, generic content and account-safe taps.
- Windows cannot alone verify iOS delivery -> separately track APNs setup and an iOS-capable build/test environment.
- Legacy context differs from recent code -> use current matching and conversation behavior as the baseline.

## Migration Plan

1. Implement additive Prisma migrations and deterministic tests locally; document environment variables without secrets.
2. Apply migrations to the intended test database before enabling producers/worker; document exact deployment commands.
3. Configure Firebase applications, Android identifiers, server credentials outside Git; defer iOS bundle/APNs setup.
4. Validate registration, delivery and taps with two accounts on Android before enabling beta notifications.
5. Roll back by disabling notification producers/worker and client initialization; retain additive records for diagnosis rather than dropping data.

## Open Questions

- Firebase project/app identifiers and server credential availability must be established during setup.
- APNs credentials and an iOS build/test environment are deferred prerequisites for a later iOS release.
- Retention and retry defaults will be explicit configurable values selected during implementation.

## References

- [Firebase Flutter receive and interaction lifecycle](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Firebase registration lifecycle](https://firebase.google.com/docs/cloud-messaging/manage-tokens)

Verify SDK compatibility against these official sources during implementation.

# Moment and message notification test results

28 September 2026. MVP platform: **Android**. iOS/APNs setup and acceptance are deferred.

The user confirmed friend Moment start delivery, a reminder after no message, and suppression when a message was sent before the reminder. A group Moment start notification opened the correct Moment presentation rather than a generic chat. Earlier Android checks confirmed direct and group message notifications and a cold-start direct-message tap opening the correct conversation.

The Profile notification switch stores the app preference and detaches the installation when turned off. When the switch is on and Android permission is off, an **Open notification settings** panel leads to this app's Android notification settings. Permission is not queried while the app switch is off. The user confirmed the settings navigation and a new notification after restoring permission. The switch behavior and conditional settings panel also passed Flutter tests. Android debug build and emulator installation passed.

## Automated verification

**28/28 real PostgreSQL notification tests** passed on the user-approved development/test database. Each run creates a random isolated `notification_test_*` schema, uses two independent Prisma connections and verifies schema removal afterward. Application tables and real user data are untouched. The FCM transport is replaced by a recording test implementation, so these results do not prove OS display.

| Scenario | Verified outcome |
| --- | --- |
| Friend and group Moment activation | One start delivery per participant; repeat processing does not duplicate it |
| Future or expired Moment | No start event |
| Enqueue failure on activation | Status remains scheduled; intents and deliveries roll back |
| Enqueue failure on reminder | `reminder_sent_at` rolls back |
| Enqueue failure on message | Message and conversation timestamp roll back; no live event is emitted |
| Due Moment without messages | One reminder; earlier chat history does not suppress it |
| Early, expired or messaged Moment | No reminder |
| Message or expiry after a reminder is queued | Stale reminder is suppressed |
| Friend, group-pair and persistent group message | Recipients are notified; sender is excluded |
| Concurrent enqueue of one event | One intent and one delivery per installation |
| Two workers read the same candidates | Atomic claim allows each delivery to be processed once |
| Active versus expired lease | Active claim remains protected; expired claim is recovered |
| One device has a transient provider failure | Accepted device is not retried; failed device has bounded retries |
| Invalid registration versus permanent payload failure | Only the invalid registration is disabled |
| Recipient leaves the group | Queued delivery is skipped after access check |
| Event occurred before device registration | No historical replay on later registration |
| Idempotent registration, account reassignment, stale logout | Ownership, secret and version guards hold |
| Database constraints | Unique token, recipient FK, RLS and anon/authenticated grant restrictions hold |
| Development Moment fixture | Starts, reminds, expires and cleans only its own data; rejects foreign cleanup |

The first PostgreSQL run exposed a concurrent Prisma `upsert` unique-key race. Production enqueue now uses a conflict-safe insert followed by lookup; the rerun passed. The latest full backend regression suite passed **104/104 tests**. Flutter notification and settings tests, analysis, and configured Android build passed after the last UI changes.

The lease test constructs the database state left by an interrupted worker; it does not kill an OS process. A crash after provider acceptance can still cause another OS notification. Exactly-once OS delivery is not promised.

Automated test source and the local Moment fixture runner remain local at the user's request and are excluded from the notification commit. This document records the executed results.

## Android acceptance matrix

The emulator used **userAaAaA** and Chrome used **userB**. The manual Moment fixture runner shortened the test window to five minutes with a one-minute reminder; normal scheduling settings were unchanged. Test conversations created by that runner were later removed. A read-only expired group-pair check requires accounts that are not friends; the two current test accounts are friends.

| ID | Scenario | Expected | Evidence |
| --- | --- | --- | --- |
| A1 | Direct message while app is backgrounded; tap | Correct chat | User confirmed |
| A2 | Swipe app away, then tap a direct-message notification | Correct chat after cold start | User confirmed |
| A3 | Persistent group message | Group notification arrives | User confirmed |
| M1 | Friend Moment start | Start notification opens writable Moment chat | User confirmed |
| M2 | Group-pair Moment start | Opens the matching Moment presentation, not the group chat | User confirmed |
| M3 | No-message Moment reminder | One reminder opens the correct Moment | Friend reminder confirmed; group reminder remains unchecked |
| M4 | Send a message before reminder time | No reminder | User confirmed |
| M5 | Expired group-pair for non-friends | Authorized historical chat is read-only; no new reminder | Unchecked |
| M6 | Foreground and cold-start Moment start/reminder taps | One alert and correct Moment presentation | Unchecked |
| M7 | Message while Moment chat is visible | Live update without an extra top alert | General open-chat update confirmed; Moment-specific check remains |
| A4 | Group notification followed by Messages overview | Correct group and live preview/time/order | Group notification confirmed; overview sequence remains unchecked |
| A5 | Restore Android notification permission from Profile | Correct system settings; subsequent new notification arrives | User confirmed |
| A6 | Logout, offline logout and account switch; tap old notification | Old account chat does not open or receive new delivery | Unchecked |
| A7 | Lose group access, then tap old notification | Unauthorized chat does not open | Unchecked |

A group-message event and a group Moment start are different events. Passing PostgreSQL tests does not count unchecked Android device cases as passed. A physical Android device has not been tested; device evidence is from the Pixel_7 emulator.

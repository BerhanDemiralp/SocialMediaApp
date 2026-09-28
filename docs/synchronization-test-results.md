# Synchronization verification — 28 September 2026

## Issues found and fixed

- The Messages tab previously refreshed only after returning from a chat or a manual reload. The server now emits `conversationChanged` to an authenticated account room for current participants. A client cannot subscribe to another account's room. The event contains no message body; the client reloads previews, timestamps and ordering from the server. This also works on web and when push permission is off.
- Reconnects and app resumes previously left missed data stale. A shared synchronization host now refreshes conversations, relationships, groups, group members and Moments. Tab changes also trigger refresh. Socket events arriving within 150 ms are coalesced.
- The socket could remain associated with a previous account after a switch. Socket ownership is now account scoped; the previous connection is closed, renewed auth reconnects, and queued updates for the old account are discarded.
- Older responses could overwrite newer chat or group data. Request ordering guards prevent stale replies from restoring write access or erasing messages/groups after a failed refresh.
- Group creation, joining and leaving now refresh the Messages list. Moment notifications also refresh the active Moment list.

## Automated evidence

At the time of this synchronization pass, **100 backend tests across 14 suites** and **69 Flutter tests** passed, along with the backend build and `flutter analyze`. The configured Android debug APK and web release build passed. The APK was installed on a Pixel_7 emulator and backend health returned HTTP 200. Later notification changes have their own validation in [the notification report](moment-notification-test-results.md).

| Scenario | Evidence |
| --- | --- |
| Previews and ordering update without opening a chat or enabling push | Messages widget test with a live event and changing repository response |
| An HTTP message reaches the right account room, not an unrelated account | Local Nest HTTP + Socket.IO integration with test doubles for database and auth |
| A repeated send/broadcast does not duplicate a message | Chat controller test |
| A message arriving during initial load is preserved | Chat controller test |
| An old response cannot overwrite newer messages or write permission | Out-of-order request completion test |
| Returning to the app refreshes missed previews | Flutter lifecycle widget test |
| Reconnect requests a full refresh | Synchronization host test |
| Events for different conversations survive the same burst | Synchronization host test |
| Account switching cancels pending events for the previous account | ProviderContainer account-switch test |
| Group mutations refresh Messages; stale or failed reads preserve the list | Groups controller test |
| A former group member does not receive the group update | Backend audience selection test |

## Limits and manual checks

These results do not establish that the entire app is free of defects. No physical Android device was tested. Real token rotation and long network outages still need device checks. Relationship and group-membership changes made on another device do not have their own immediate server event; app resume, tab change or manual refresh retrieves them. Existing periodic Moment refresh also remains active.

With two accounts, keep Messages open on the emulator and send a message from Chrome. The preview, time and ordering should update without opening the chat. Repeat after backgrounding and resuming the app; an open chat should show the new message once. No tools sent messages on behalf of other users during this check.

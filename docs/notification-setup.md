# Android notification setup

MVP scope (28 September 2026): **Android only**. iOS/APNs setup and acceptance are deferred. Firebase Android registration, backend credentials and the additive database migration have been configured in the approved development/test environment. The user confirmed Android background and cold-start direct messages, group messages, Moment start/reminder behavior, and delivery after restoring Android notification permission on a Pixel_7 emulator. See [notification test results](moment-notification-test-results.md) for the exact evidence and remaining cases.

## 1. Firebase application

Create a Firebase project with Cloud Messaging API v1 enabled. Register an Android app with the application ID currently used in the code: `com.example.moment_app`. Place its `google-services.json` at `frontend/android/app/google-services.json`; the file is Git-ignored. If the release application ID changes, register that ID in Firebase too. The Android Google Services plugin is applied when the file exists. The Dart client configuration and native JSON must refer to the same Firebase project/app.

The FCM legacy API does not need to be enabled. Android `POST_NOTIFICATIONS` permission and the `moment_messages` channel are configured in the app. In **Profile → Notifications**, the app switch controls the installation registration. If the switch is on but Android permission is off, **Open notification settings** opens this app's system notification settings. The app does not check OS permission while its notification switch is off.

## 2. iOS/APNs after the MVP

The current development bundle identifier is `com.example.momentApp`; its Firebase file would be `frontend/ios/Runner/GoogleService-Info.plist`, also Git-ignored. A later iOS release needs macOS/Xcode, an Apple Developer signing profile, Push Notifications and Background Modes → Remote notifications capabilities, an APNs authentication key uploaded in Firebase, and a physical-iPhone delivery check. The iOS minimum version is 15.0. Keep the `.p8` key outside the repository. The existing iOS scaffolding is not a claim of tested iOS delivery.

## 3. Backend and migration

Confirm locally that `backend/.env` points to the intended database. Review pending migrations before `migrate deploy`, since it applies every pending migration. Do not reset or use `db push` for this change.

```powershell
cd backend
npm ci
npx prisma migrate status
npx prisma migrate deploy
npx prisma generate
npm run build
```

Migration `20260928000000_mobile_notifications` adds installation, intent and delivery tables without deleting user data. RLS is enabled and anon/authenticated table grants are removed. The backend must use a server/owner database role; clients do not read these tables directly.

Backend configuration (`backend/.env.example` has the same keys):

```dotenv
PUSH_ENABLED=1
FIREBASE_PROJECT_ID=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=C:/private/firebase-service-account.json
PUSH_MESSAGE_TTL_SECONDS=3600
PUSH_MAX_ATTEMPTS=5
PUSH_RETENTION_DAYS=30
```

`GOOGLE_APPLICATION_CREDENTIALS` points to a Firebase Admin service-account file outside Git. Workload/application default credentials can be used in production. Never put an Admin key or Supabase service-role key in the Flutter configuration.

The worker runs every five seconds within the NestJS process and takes up to 25 candidates per tick. Its lease lasts 120 seconds. Transient errors back off exponentially up to 300 seconds; the default attempt limit is five. Message intents expire after one hour by default (configurable between 60 and 86,400 seconds). Moment intents expire when their Moment ends. Invalid registrations are disabled. Expired intents and their deliveries are removed after the configured retention period by hourly cleanup.

## 4. Flutter configuration

Create `frontend/push-config.android.json` from the template below with public Android Firebase values. The file is Git-ignored. The iOS equivalent is deferred.

```json
{
  "PUSH_ENABLED": "true",
  "FIREBASE_API_KEY": "firebase-client-api-key",
  "FIREBASE_APP_ID": "android-firebase-app-id",
  "FIREBASE_MESSAGING_SENDER_ID": "firebase-project-number",
  "FIREBASE_PROJECT_ID": "your-project-id",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-public-anon-key",
  "API_BASE_URL": "https://your-test-api.example/api",
  "WS_BASE_URL": "https://your-test-api.example"
}
```

```powershell
cd frontend
flutter pub get
flutter run --dart-define-from-file=push-config.android.json
```

A physical device needs an API address it can reach; `localhost` and Android emulator address `10.0.2.2` are not usable as-is from a phone. Omitting `PUSH_ENABLED` keeps notifications off. Missing client configuration does not block app startup.

## 5. Android acceptance

The [notification test results](moment-notification-test-results.md) distinguish user-confirmed emulator behavior from untested cases. Foreground/cold-start Moment taps, logout/account switching, revoked group access and a physical Android device are still unchecked. iOS acceptance is outside this MVP. Provider `accepted` means FCM accepted a request, not that the device displayed it. A crash immediately after provider acceptance can result in another OS notification; exactly-once OS delivery is not guaranteed. A notification accepted before logout may remain visible, but opening it still requires the intended account and authorized conversation access.

## 6. Diagnostics and rollback

Do not log tokens, installation secrets, auth headers or private keys. For aggregate counts:

```sql
SELECT status, error_code, count(*)
FROM notification_deliveries GROUP BY status, error_code;
SELECT count(*) AS intents_without_devices
FROM notification_intents i
WHERE NOT EXISTS (SELECT 1 FROM notification_deliveries d WHERE d.intent_id = i.id);
```

`pending` means due or retryable; `sending` has a lease; `accepted` means provider acceptance; `failed` means permanent error or exhausted retries; `expired` is past its lifetime; `skipped` means access/registration changed or a reminder became unnecessary. Events from before an installation registered are not replayed.

To roll back delivery, restart the backend with `PUSH_ENABLED=0` and build Flutter with `PUSH_ENABLED=false`. This stops new events and sends; retain the tables. Already accepted OS notifications cannot be recalled. Re-enabling can process still-valid pending events.

## Verification limits

The latest backend regression suite passed 104/104 tests, and 28/28 real PostgreSQL notification tests passed in isolated disposable schemas. Those database tests use a fake FCM transport and do not establish device delivery. Flutter notification/settings tests, analysis and a configured Android debug build passed. See the [test report](moment-notification-test-results.md) for device evidence.

Official references: [Flutter FCM setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [receiving/opening messages](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages), [Admin sending](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk), [token management](https://firebase.google.com/docs/cloud-messaging/manage-tokens).

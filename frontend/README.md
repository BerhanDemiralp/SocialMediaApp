# moment_app

Flutter client for the MOMENT social app.

## Messaging tab

The Home shell uses a bottom navigation bar with three tabs:

- **Home**: Friends search and friend request management.
- **Messages**: Friend conversations inbox. This tab lists direct friend conversations
  loaded from the backend `/conversations?type=friend` endpoint and lets users open
  chat via the existing `ChatScreen`.
- **Profile**: Reserved for future profile settings.

The Messages tab is implemented in `lib/features/home/presentation/home_messages_screen.dart`.
It consumes friend conversation summaries from
`lib/features/home/data/friend_conversations_api_client.dart` and
`lib/features/home/data/home_messaging_repository.dart`.

## Getting Started

Run the app from the `frontend` directory:

```bash
flutter pub get
flutter run
```

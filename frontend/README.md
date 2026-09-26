# moment_app

Flutter client for the MOMENT social app.

## Shared user system

User UI and relationship operations live in `lib/features/users/`:

- `UserIdentity` and DTO adapters give every screen the same identity format.
- `UserIdentityView` renders avatar, compact row, and profile-header variants. `UserName` uses the same identity resolution for message sender labels.
- `UserCard` connects the shared controller to `UserCardView`; screens pass an identity instead of friendship flags or request callbacks.
- `UserRelationshipsController` owns the account-scoped friends/request snapshot, request IDs, per-person action locks, refresh revisions, and confirmed transitions.
- `UserConversationCoordinator` guards friend chat creation/navigation. Existing conversation rows supply their saved ID to preserve history access.

The common action policy is Add friend, Cancel request, Accept / Cancel for incoming requests, and Message with Remove friend in an overflow menu for confirmed friends. Self cards have no social actions. Unknown relationships require loading/retry before mutations are enabled.

Profile edits publish identity overrides and an identity revision so stale list data cannot replace a freshly updated name/avatar. Supabase account changes reset the shared state and invalidate pending navigation. User data clients and repositories are shared under `features/users/data`; group and Moment business rules remain in their own features.

Run `flutter analyze` and `flutter test` from `frontend/`. The focused controller, card-system, request, group-navigation, and notice tests cover synchronization, account switching, retries, history navigation, and narrow layouts.

## Messaging tab

The Home shell uses a bottom navigation bar with three tabs:

- **Home**: Friends search and friend request management.
- **Messages**: Friend conversations inbox. This tab lists direct friend conversations
  loaded from the backend `/conversations?type=friend` endpoint and lets users open
  chat via the existing `ChatScreen`.
- **Profile**: Profile/avatar editing, password management, theme settings, and logout.

The Messages tab is implemented in `lib/features/home/presentation/home_messages_screen.dart`.
It consumes conversation summaries from the shared Users feature and friend state
from `UserRelationshipsController`. Group conversations keep their group-specific presentation.

## Getting Started

Run the app from the `frontend` directory:

```bash
flutter pub get
flutter run
```

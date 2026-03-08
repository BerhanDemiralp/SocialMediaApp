## Home Friends Search & Requests (Flutter)

This document describes the Home/Friends experience for searching users by
username, sending friend requests, and managing incoming/outgoing requests.

### Data layer

- `UserSearchApiClient` (`frontend/lib/features/home/data/user_search_api_client.dart`)
  - Calls `GET /api/users/search?query=&limit=`.
  - Returns a list of `UserSummary { id, username, avatarUrl }`.

- `FriendRequestsApiClient` (`frontend/lib/features/home/data/friend_requests_api_client.dart`)
  - `sendRequest(targetUserId)` → `POST /api/friends/requests`.
  - `listIncoming()` → `GET /api/friends/requests/incoming`.
  - `listOutgoing()` → `GET /api/friends/requests/outgoing`.
  - `acceptRequest(id)` → `PATCH /api/friends/requests/:id/accept`.
  - `rejectRequest(id)` → `PATCH /api/friends/requests/:id/reject`.
  - `cancelRequest(id)` → `PATCH /api/friends/requests/:id/cancel`.

- `HomeFriendsRepository` (`frontend/lib/features/home/data/home_friends_repository.dart`)
  - Wraps both API clients and is exposed via `homeFriendsRepositoryProvider`.
  - Provides methods for search and friend-request operations used by the UI.

### Presentation layer

- `HomeFriendsScreen` (`frontend/lib/features/home/presentation/home_friends_screen.dart`)
  - Search:
    - Text field bound to `_searchQueryProvider`.
    - Results loaded via `searchResultsProvider` from `HomeFriendsRepository`.
    - Shows empty, loading, and error states.
    - Allows sending friend requests directly from search results.
  - Incoming requests:
    - Loaded via `incomingRequestsProvider`.
    - Accept/reject actions call `HomeFriendsRepository` and refresh the list.
  - Outgoing requests:
    - Loaded via `outgoingRequestsProvider`.
    - Cancel action calls `HomeFriendsRepository` and refreshes the list.

- `HomeShellScreen` (`frontend/lib/features/home/presentation/home_shell.dart`)
  - Uses an `IndexedStack` with:
    - Index 0: `HomeFriendsScreen` (Home tab).
    - Index 1: Messages placeholder.
    - Index 2: Profile placeholder.

### Analytics

- `AppAnalytics` (`frontend/lib/core/analytics/app_analytics.dart`)
  - Placeholder analytics service exposed via `appAnalyticsProvider`.
  - `HomeFriendsScreen` tracks:
    - `home_search_changed` when the search query changes.
    - `friend_request_sent` when a request is sent.
    - `friend_request_accepted` / `friend_request_rejected` / `friend_request_canceled`
      when corresponding actions are performed.


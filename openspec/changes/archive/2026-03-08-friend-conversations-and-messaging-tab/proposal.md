## Why

We now have a unified conversations backend and a Home/Friends flow for discovering and adding friends, but there is no dedicated “Messaging” experience that lets users see all of their friend conversations in one place and jump straight into chat. Today, chats are reached indirectly (e.g., through Moments or ad hoc entry points), which makes the app feel fragmented and makes it harder for users to treat MOMENT as their cozy place to talk with friends.

## What Changes

- Add backend endpoints to:
  - Create or reuse a direct conversation between two friends on demand (outside the daily matching window).
  - List a user’s friend conversations (type `friend`) with enough metadata for a Messaging tab (name, avatar, last message snippet/time).
- Extend the Flutter app with a **Messaging** tab that:
  - Lists all friend conversations for the authenticated user.
  - Allows tapping into a conversation to open `ChatScreen(conversationId, ...)`.
  - Provides empty/loading/error states consistent with the rest of the app.
- Ensure that friend conversations opened from the Messaging tab and those created via other flows (e.g., Moments, Home/Friends) converge on the same `conversation_id` so that history and real-time behavior are coherent.

## Capabilities

### New Capabilities
- `messaging-tab-friend-conversations`: Messaging tab UX that surfaces all friend conversations and lets users open chats directly by `conversation_id`.

### Modified Capabilities
- `backend-api`: Add/clarify HTTP endpoints to:
  - Create or reuse friend conversations.
  - List friend conversations for the authenticated user.
- `friends-and-groups`: Specify how friend relationships map to direct conversations (creation/reuse rules) independently of daily matching.

## Impact

- **Backend (NestJS + Prisma)**
  - New or extended conversations-related endpoints for:
    - Creating/reusing `ConversationType.friend` conversations between two friends.
    - Listing friend conversations (subset of `/conversations`) tuned for the Messaging tab.
  - Possible small changes to existing services so that friend conversations are consistently created/reused across flows (Home/Friends, Moments, Messaging).

- **Flutter app**
  - New repositories/API methods to fetch friend conversations and open chats by `conversation_id`.
  - A Messaging tab in the main shell that shows:
    - Friend conversation list with last message and basic context.
    - Navigation into `ChatScreen(conversationId)` when a conversation is tapped.

- **Specs & future changes**
  - Backend specs (`backend-api`, `friends-and-groups`, and the new `messaging-tab-friend-conversations`) updated so friend conversations and the Messaging UX are first-class parts of the product.
  - Provides groundwork for future enhancements like unread counts, pinning, or additional conversation metadata without changing the fundamental model.


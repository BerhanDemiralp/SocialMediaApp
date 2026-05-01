## Why

Groups currently let users create, join, leave, and list memberships, but they do not provide a persistent shared chat surface for the group itself. Adding group chats makes each group feel alive in the Messages tab and keeps conversation access aligned with membership.

## What Changes

- Add a persistent group chat conversation for every group.
- Show group chat conversations in the Messages tab alongside friend conversations, with a visually distinct group chat row/chat header treatment.
- Allow group members to open the group chat and exchange messages through the existing conversation/message model.
- Remove a group chat from a user's Messages tab when that user leaves the group.
- Delete or deactivate the group chat and its messages when the group is deleted.
- Enforce membership-based access so only current group members can list, open, or receive real-time events for the group chat.

## Capabilities

### New Capabilities

### Modified Capabilities

- `conversations-backend-foundation`: Add first-class persistent group chat conversations tied to group records and group membership.
- `messages`: Require message history, persistence, and real-time delivery to work for group chat conversations.
- `backend-api`: Expose group chat conversations in authenticated conversation APIs and handle group chat lifecycle cleanup.
- `messaging-tab-friend-conversations`: Expand the Messaging tab from friend-only conversations to include group chats with distinct presentation.
- `group-frontend`: Remove group chat access from the frontend when a user leaves a group and support opening a group's chat from group or message surfaces.
- `friends-and-groups`: Define group deletion and member leave behavior for associated group chat conversations.
- `database-schema`: Add or update schema requirements needed to associate groups with their persistent conversations and cascade/soft-delete chat data.

## Impact

- Backend conversation, message, group, and membership modules.
- Prisma schema and migrations for group conversation associations and cleanup behavior.
- Conversation list and message history APIs.
- Socket.io subscription authorization for group chat conversations.
- Flutter Messages tab data model, list UI, navigation, and ChatScreen styling for group chat context.
- Group leave/delete flows and related tests.

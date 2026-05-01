## 1. Database And Migration

- [x] 1.1 Inspect the existing Prisma conversation, group, group member, and message models to identify the smallest schema change for persistent group chat association.
- [x] 1.2 Add schema support for a `group` conversation type and a one-to-one group-to-conversation association, including uniqueness constraints and deleted/active-state fields consistent with existing conventions.
- [x] 1.3 Create a migration/backfill path so existing groups receive exactly one persistent group chat conversation.

## 2. Backend Group Chat Lifecycle

- [x] 2.1 Update group creation to create the persistent group chat conversation in the same transaction as the group and creator membership.
- [x] 2.2 Update group join flow so new members can access the existing persistent group chat conversation.
- [x] 2.3 Update group leave flow so the leaving user loses group chat access and no longer sees the group chat in conversation lists.
- [x] 2.4 Update group deletion flow so the associated group chat conversation and messages are deleted, soft-deleted, or deactivated according to database conventions.

## 3. Backend Conversation And Message Access

- [x] 3.1 Extend conversation list APIs to include `group` conversations for current group members with group metadata and last message preview.
- [x] 3.2 Enforce group membership authorization for group chat metadata, message history, message sending, and Socket.io `conversation:<id>` subscriptions.
- [x] 3.3 Ensure group chat messages use the existing conversation-scoped persistence, pagination, and real-time delivery path.
- [x] 3.4 Add backend tests for group chat creation, listing, member leave removal, deleted group cleanup, unauthorized access, and message delivery.

## 4. Flutter Data And Navigation

- [x] 4.1 Extend conversation DTOs/domain models/repositories to carry group conversation type, group identifier, group name, visual metadata, last message, and timestamp.
- [x] 4.2 Update Messaging tab loading so friend and group conversations are shown together in the correct recency order.
- [x] 4.3 Add navigation from group surfaces to the group's persistent chat conversation.
- [x] 4.4 Clear or invalidate local group chat state after a successful leave group action.

## 5. Flutter Presentation

- [x] 5.1 Add distinct Messaging tab row styling for group chats while preserving existing friend chat presentation.
- [x] 5.2 Add group-specific ChatScreen header or context treatment for group chat conversations.
- [x] 5.3 Add Flutter tests for group chat rows, opening a group chat, removal after leaving, and friend chat regression coverage.

## 6. Verification

- [x] 6.1 Run backend schema generation/migration validation and backend tests relevant to groups, conversations, messages, and sockets.
- [x] 6.2 Run Flutter analysis and tests relevant to messaging and group surfaces.
- [x] 6.3 Manually verify create group, join group, message in group chat, leave group, and delete group flows if the local app/backend can be run.

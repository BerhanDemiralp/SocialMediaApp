## Context

MOMENT already has groups, a unified conversations model, message persistence, conversation APIs, real-time conversation channels, and a Messages tab currently scoped to friend conversations. This change adds one persistent group-wide chat per group, visible to current members in Messages and removed from access when membership ends.

The implementation crosses backend group lifecycle logic, conversation/message access control, database associations, Socket.io authorization, and Flutter Messages tab presentation.

## Goals / Non-Goals

**Goals:**

- Create or associate one persistent conversation for each group.
- Show group chats in the Messages tab with a distinct group visual treatment.
- Reuse existing conversation-scoped message APIs and real-time channels.
- Restrict group chat access to current group members.
- Remove chat access when a member leaves and remove/deactivate chat data when a group is deleted.

**Non-Goals:**

- Public group discovery.
- Multi-room channels inside a single group.
- Media-rich group chat.
- Changes to temporary group pair match chats, except ensuring they remain separate from the persistent group chat.
- New external messaging dependencies.

## Decisions

1. Use the unified `conversations` model for group chats.

   A group chat will be represented as a conversation type such as `group` with a stable `conversation_id`. This reuses message history, pagination, and Socket.io `conversation:<id>` channels instead of adding a separate group messages table. Alternative considered: a dedicated `group_messages` table. That would duplicate message logic and complicate the Messages tab.

2. Associate each group with exactly one persistent group conversation.

   The database should enforce or service-guard a one-to-one relationship between a group and its group chat conversation. A group create flow should create the group chat conversation in the same transaction as the group and owner membership when possible. Alternative considered: lazy-create on first open. Eager creation better satisfies "every group will have group chat" and keeps Messages tab behavior deterministic.

3. Authorize group chats through current group membership.

   Backend APIs and Socket.io subscription logic should verify that the requesting user is an active member of the linked group before listing, opening, reading, sending, or subscribing. Conversation participant rows may be used for current members, but group membership remains the source of truth so leave/delete behavior cannot drift.

4. Remove access on leave without deleting shared history for remaining members.

   When a member leaves, that user must no longer see or access the group chat, and their participant record should be removed or marked inactive. The group chat remains for the group and other members. Alternative considered: deleting messages when any member leaves. That would destroy shared group history for everyone and does not match group chat expectations.

5. Delete or soft-delete the group chat when the group is deleted.

   Project database conventions prefer `deleted_at` for soft deletes. Group deletion should mark the group conversation and messages deleted or otherwise make them inaccessible to all former members. A hard cascade may be acceptable only if existing migration patterns already use hard delete for dependent records.

6. Extend Messages tab items with conversation type metadata.

   Flutter conversation list models should include enough metadata to render friend and group rows differently: conversation type, group name/avatar or initials, participant summary, last message preview, and timestamp. The chat screen should also use the conversation type to render a distinct group header/treatment.

## Risks / Trade-offs

- [Risk] Conversation participants can fall out of sync with group members. -> Mitigation: centralize join/leave/delete updates in group service methods and authorize against group membership.
- [Risk] Group deletion can leave orphaned messages or real-time subscriptions. -> Mitigation: transactionally soft-delete the group conversation, filter deleted conversations from APIs, and reject socket joins after deletion.
- [Risk] Expanding the friend-only Messages tab could regress friend chat display. -> Mitigation: keep friend row data compatible and add type-specific rendering branches with focused widget tests.
- [Risk] Eager group chat creation adds more work to group creation. -> Mitigation: wrap group, membership, and conversation creation in a single backend transaction.

## Migration Plan

1. Add schema fields/indexes to link groups and conversations, and to represent `group` conversation type if not already supported.
2. Backfill existing groups with a persistent group conversation.
3. Update backend group create, join, leave, and delete flows.
4. Extend conversation listing, message access, and Socket.io authorization for group chat membership.
5. Update Flutter conversation models, repositories, Messages tab UI, and ChatScreen group styling.
6. Add backend and Flutter tests for listing, access removal, group deletion cleanup, and visual routing.

Rollback should remove group chat entries from conversation listings and disable group chat creation while leaving any migrated conversations inaccessible through feature-gated API filters.

## Open Questions

- Should group deletion be exposed as a hard delete endpoint or soft-delete-only admin action in the current backend?
- Should group chat display use a generated initials avatar or a future group avatar field when no image exists?

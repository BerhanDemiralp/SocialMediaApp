-- Indexes for the remote Supabase/Postgres query paths used most often by
-- auth-gated messaging, friends, groups, and group chat screens.

CREATE INDEX IF NOT EXISTS "friendships_requester_id_status_idx"
ON "friendships"("requester_id", "status");

CREATE INDEX IF NOT EXISTS "friendships_addressee_id_status_idx"
ON "friendships"("addressee_id", "status");

CREATE INDEX IF NOT EXISTS "group_members_group_id_idx"
ON "group_members"("group_id");

CREATE INDEX IF NOT EXISTS "group_members_user_id_idx"
ON "group_members"("user_id");

CREATE INDEX IF NOT EXISTS "messages_conversation_id_deleted_at_created_at_idx"
ON "messages"("conversation_id", "deleted_at", "created_at");

CREATE INDEX IF NOT EXISTS "messages_sender_id_idx"
ON "messages"("sender_id");

CREATE INDEX IF NOT EXISTS "conversations_deleted_at_type_updated_at_idx"
ON "conversations"("deleted_at", "type", "updated_at");

CREATE INDEX IF NOT EXISTS "conversation_participants_user_id_conversation_id_idx"
ON "conversation_participants"("user_id", "conversation_id");

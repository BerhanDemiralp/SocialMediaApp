-- CreateEnum
CREATE TYPE "ConversationMode" AS ENUM ('friend', 'active_moment', 'exception', 'read_only');

-- AlterTable
ALTER TABLE "conversations"
ADD COLUMN "mode" "ConversationMode",
ADD COLUMN "direct_user_low_id" TEXT,
ADD COLUMN "direct_user_high_id" TEXT;

-- Backfill canonical direct-pair ids for existing 1:1 friend and group-pair conversations.
WITH direct_pairs AS (
  SELECT
    cp."conversation_id",
    MIN(cp."user_id") AS low_id,
    MAX(cp."user_id") AS high_id,
    COUNT(DISTINCT cp."user_id") AS participant_count
  FROM "conversation_participants" cp
  INNER JOIN "conversations" c ON c."id" = cp."conversation_id"
  WHERE c."type" IN ('friend', 'group_pair')
  GROUP BY cp."conversation_id"
)
UPDATE "conversations" c
SET
  "direct_user_low_id" = dp.low_id,
  "direct_user_high_id" = dp.high_id,
  "mode" = CASE
    WHEN c."type" = 'friend' THEN 'friend'::"ConversationMode"
    ELSE 'read_only'::"ConversationMode"
  END
FROM direct_pairs dp
WHERE c."id" = dp."conversation_id"
  AND dp.participant_count = 2;

-- Merge duplicate direct conversations that may already exist for the same pair.
-- The canonical row prefers a friend conversation, then the oldest conversation.
WITH ranked_direct AS (
  SELECT
    c."id",
    FIRST_VALUE(c."id") OVER (
      PARTITION BY c."direct_user_low_id", c."direct_user_high_id"
      ORDER BY
        CASE WHEN c."type" = 'friend' THEN 0 ELSE 1 END,
        c."created_at" ASC,
        c."id" ASC
    ) AS canonical_id
  FROM "conversations" c
  WHERE c."deleted_at" IS NULL
    AND c."direct_user_low_id" IS NOT NULL
    AND c."direct_user_high_id" IS NOT NULL
),
duplicates AS (
  SELECT "id", "canonical_id"
  FROM ranked_direct
  WHERE "id" <> "canonical_id"
)
UPDATE "moment_matches" mm
SET "conversation_id" = d."canonical_id"
FROM duplicates d
WHERE mm."conversation_id" = d."id";

WITH ranked_direct AS (
  SELECT
    c."id",
    FIRST_VALUE(c."id") OVER (
      PARTITION BY c."direct_user_low_id", c."direct_user_high_id"
      ORDER BY
        CASE WHEN c."type" = 'friend' THEN 0 ELSE 1 END,
        c."created_at" ASC,
        c."id" ASC
    ) AS canonical_id
  FROM "conversations" c
  WHERE c."deleted_at" IS NULL
    AND c."direct_user_low_id" IS NOT NULL
    AND c."direct_user_high_id" IS NOT NULL
),
duplicates AS (
  SELECT "id", "canonical_id"
  FROM ranked_direct
  WHERE "id" <> "canonical_id"
)
UPDATE "messages" m
SET "conversation_id" = d."canonical_id"
FROM duplicates d
WHERE m."conversation_id" = d."id";

WITH ranked_direct AS (
  SELECT
    c."id",
    FIRST_VALUE(c."id") OVER (
      PARTITION BY c."direct_user_low_id", c."direct_user_high_id"
      ORDER BY
        CASE WHEN c."type" = 'friend' THEN 0 ELSE 1 END,
        c."created_at" ASC,
        c."id" ASC
    ) AS canonical_id
  FROM "conversations" c
  WHERE c."deleted_at" IS NULL
    AND c."direct_user_low_id" IS NOT NULL
    AND c."direct_user_high_id" IS NOT NULL
),
duplicates AS (
  SELECT "id"
  FROM ranked_direct
  WHERE "id" <> "canonical_id"
)
UPDATE "conversations" c
SET "deleted_at" = CURRENT_TIMESTAMP
FROM duplicates d
WHERE c."id" = d."id";

-- Promote canonical rows to friend mode if any duplicate in the pair was a friend chat.
WITH pair_modes AS (
  SELECT
    "direct_user_low_id",
    "direct_user_high_id",
    BOOL_OR("type" = 'friend') AS has_friend
  FROM "conversations"
  WHERE "direct_user_low_id" IS NOT NULL
    AND "direct_user_high_id" IS NOT NULL
  GROUP BY "direct_user_low_id", "direct_user_high_id"
)
UPDATE "conversations" c
SET
  "type" = CASE WHEN pm.has_friend THEN 'friend'::"ConversationType" ELSE c."type" END,
  "mode" = CASE WHEN pm.has_friend THEN 'friend'::"ConversationMode" ELSE COALESCE(c."mode", 'read_only'::"ConversationMode") END
FROM pair_modes pm
WHERE c."deleted_at" IS NULL
  AND c."direct_user_low_id" = pm."direct_user_low_id"
  AND c."direct_user_high_id" = pm."direct_user_high_id";

-- CreateTable
CREATE TABLE "conversation_write_exceptions" (
    "id" TEXT NOT NULL,
    "conversation_id" TEXT NOT NULL,
    "granted_by_id" TEXT NOT NULL,
    "granted_to_id" TEXT,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "conversation_write_exceptions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "conversations_direct_user_low_id_direct_user_high_id_idx" ON "conversations"("direct_user_low_id", "direct_user_high_id");

-- CreateIndex
CREATE UNIQUE INDEX "conversations_direct_pair_unique" ON "conversations"("direct_user_low_id", "direct_user_high_id")
WHERE "deleted_at" IS NULL
  AND "direct_user_low_id" IS NOT NULL
  AND "direct_user_high_id" IS NOT NULL;

-- CreateIndex
CREATE INDEX "conversation_write_exceptions_conversation_id_expires_at_idx" ON "conversation_write_exceptions"("conversation_id", "expires_at");

-- CreateIndex
CREATE INDEX "conversation_write_exceptions_granted_to_id_expires_at_idx" ON "conversation_write_exceptions"("granted_to_id", "expires_at");

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_direct_user_low_id_fkey" FOREIGN KEY ("direct_user_low_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_direct_user_high_id_fkey" FOREIGN KEY ("direct_user_high_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation_write_exceptions" ADD CONSTRAINT "conversation_write_exceptions_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation_write_exceptions" ADD CONSTRAINT "conversation_write_exceptions_granted_by_id_fkey" FOREIGN KEY ("granted_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation_write_exceptions" ADD CONSTRAINT "conversation_write_exceptions_granted_to_id_fkey" FOREIGN KEY ("granted_to_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

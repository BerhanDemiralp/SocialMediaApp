-- CreateEnum
CREATE TYPE "MomentMatchType" AS ENUM ('friend', 'group');

-- CreateEnum
CREATE TYPE "MomentMatchStatus" AS ENUM ('active', 'successful', 'expired');

-- CreateEnum
CREATE TYPE "MomentOptInState" AS ENUM ('pending', 'opted_in');

-- CreateTable
CREATE TABLE "moment_matches" (
    "id" TEXT NOT NULL,
    "match_type" "MomentMatchType" NOT NULL,
    "status" "MomentMatchStatus" NOT NULL DEFAULT 'active',
    "user_a_id" TEXT NOT NULL,
    "user_b_id" TEXT NOT NULL,
    "group_id" TEXT,
    "conversation_id" TEXT NOT NULL,
    "scheduled_day" TIMESTAMP(3) NOT NULL,
    "scheduled_at" TIMESTAMP(3) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "reminder_sent_at" TIMESTAMP(3),
    "user_a_opt_in" "MomentOptInState" NOT NULL DEFAULT 'pending',
    "user_b_opt_in" "MomentOptInState" NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "moment_matches_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "moment_matches_status_expires_at_idx" ON "moment_matches"("status", "expires_at");

-- CreateIndex
CREATE INDEX "moment_matches_user_a_id_match_type_scheduled_at_idx" ON "moment_matches"("user_a_id", "match_type", "scheduled_at");

-- CreateIndex
CREATE INDEX "moment_matches_user_b_id_match_type_scheduled_at_idx" ON "moment_matches"("user_b_id", "match_type", "scheduled_at");

-- CreateIndex
CREATE INDEX "moment_matches_conversation_id_idx" ON "moment_matches"("conversation_id");

-- CreateIndex
CREATE INDEX "moment_matches_group_id_idx" ON "moment_matches"("group_id");

-- CreateIndex
CREATE UNIQUE INDEX "moment_matches_scheduled_day_match_type_user_a_id_key" ON "moment_matches"("scheduled_day", "match_type", "user_a_id");

-- CreateIndex
CREATE UNIQUE INDEX "moment_matches_scheduled_day_match_type_user_b_id_key" ON "moment_matches"("scheduled_day", "match_type", "user_b_id");

-- CreateIndex
CREATE UNIQUE INDEX "moment_matches_scheduled_day_match_type_user_a_id_user_b_id_key" ON "moment_matches"("scheduled_day", "match_type", "user_a_id", "user_b_id");

-- AddForeignKey
ALTER TABLE "moment_matches" ADD CONSTRAINT "moment_matches_user_a_id_fkey" FOREIGN KEY ("user_a_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moment_matches" ADD CONSTRAINT "moment_matches_user_b_id_fkey" FOREIGN KEY ("user_b_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moment_matches" ADD CONSTRAINT "moment_matches_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moment_matches" ADD CONSTRAINT "moment_matches_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

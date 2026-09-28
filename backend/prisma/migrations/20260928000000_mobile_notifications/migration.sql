-- CreateTable
CREATE TABLE "notification_installations" (
    "id" TEXT NOT NULL,
    "secret_hash" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "last_seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_installations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification_intents" (
    "id" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "source_id" TEXT NOT NULL,
    "recipient_id" TEXT NOT NULL,
    "conversation_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "notification_intents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification_deliveries" (
    "id" TEXT NOT NULL,
    "intent_id" TEXT NOT NULL,
    "installation_id" TEXT NOT NULL,
    "installation_version" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "next_attempt_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lease_until" TIMESTAMP(3),
    "claim_id" TEXT,
    "error_code" TEXT,
    "accepted_at" TIMESTAMP(3),

    CONSTRAINT "notification_deliveries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "notification_installations_token_key" ON "notification_installations"("token");

-- CreateIndex
CREATE INDEX "notification_installations_user_id_enabled_idx" ON "notification_installations"("user_id", "enabled");

-- CreateIndex
CREATE INDEX "notification_intents_expires_at_idx" ON "notification_intents"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "notification_intents_kind_source_id_recipient_id_key" ON "notification_intents"("kind", "source_id", "recipient_id");

-- CreateIndex
CREATE INDEX "notification_deliveries_status_next_attempt_at_lease_until_idx" ON "notification_deliveries"("status", "next_attempt_at", "lease_until");

-- CreateIndex
CREATE UNIQUE INDEX "notification_deliveries_intent_id_installation_id_key" ON "notification_deliveries"("intent_id", "installation_id");

-- AddForeignKey
ALTER TABLE "notification_installations" ADD CONSTRAINT "notification_installations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_intents" ADD CONSTRAINT "notification_intents_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_intents" ADD CONSTRAINT "notification_intents_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_deliveries" ADD CONSTRAINT "notification_deliveries_intent_id_fkey" FOREIGN KEY ("intent_id") REFERENCES "notification_intents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_deliveries" ADD CONSTRAINT "notification_deliveries_installation_id_fkey" FOREIGN KEY ("installation_id") REFERENCES "notification_installations"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- These private tables are only accessed by the server database role.
ALTER TABLE "notification_installations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "notification_intents" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "notification_deliveries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "notification_installations" ADD CONSTRAINT "notification_platform" CHECK (platform IN ('android', 'ios'));
ALTER TABLE "notification_deliveries" ADD CONSTRAINT "notification_delivery_status" CHECK (status IN ('pending', 'sending', 'accepted', 'failed', 'expired', 'skipped'));
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON notification_installations, notification_intents, notification_deliveries FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON notification_installations, notification_intents, notification_deliveries FROM authenticated;
  END IF;
END $$;

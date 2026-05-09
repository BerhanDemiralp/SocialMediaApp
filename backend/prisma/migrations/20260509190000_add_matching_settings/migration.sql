-- CreateTable
CREATE TABLE "matching_settings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "daily_time_utc" TEXT NOT NULL DEFAULT '16:00',
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "reminder_after_min" INTEGER NOT NULL DEFAULT 30,
    "active_duration_min" INTEGER NOT NULL DEFAULT 60,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "matching_settings_pkey" PRIMARY KEY ("id")
);

-- Seed default settings for development/admin editing.
INSERT INTO "matching_settings" (
    "id",
    "daily_time_utc",
    "enabled",
    "reminder_after_min",
    "active_duration_min",
    "updated_at"
)
VALUES (
    'default',
    '16:00',
    true,
    30,
    60,
    CURRENT_TIMESTAMP
)
ON CONFLICT ("id") DO NOTHING;

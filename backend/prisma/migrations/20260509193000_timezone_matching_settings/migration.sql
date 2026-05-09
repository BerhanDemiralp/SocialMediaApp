-- AlterTable
ALTER TABLE "matching_settings"
ADD COLUMN IF NOT EXISTS "daily_time_local" TEXT NOT NULL DEFAULT '19:00',
ADD COLUMN IF NOT EXISTS "timezone" TEXT NOT NULL DEFAULT 'Europe/Istanbul';

-- Preserve the previous 16:00 UTC default as 19:00 Europe/Istanbul for existing rows.
UPDATE "matching_settings"
SET
  "daily_time_local" = CASE
    WHEN "daily_time_utc" = '16:00' THEN '19:00'
    ELSE COALESCE("daily_time_local", '19:00')
  END,
  "timezone" = COALESCE("timezone", 'Europe/Istanbul');

-- Drop the UTC-only setting after local-time fields are populated.
ALTER TABLE "matching_settings"
DROP COLUMN IF EXISTS "daily_time_utc";

-- New matches are created ahead of time and activated at scheduled_at.
ALTER TABLE "moment_matches" ALTER COLUMN "status" SET DEFAULT 'scheduled';

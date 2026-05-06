-- Add scheduled lifecycle state for pre-created Moment matches.
ALTER TYPE "MomentMatchStatus" ADD VALUE IF NOT EXISTS 'scheduled';

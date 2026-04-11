-- Migration 006: Add walkie_id column to sources table
-- Purpose: Store agent Walkie identity for P2P responses
-- Date: 2026-04-11

BEGIN;

ALTER TABLE sources ADD COLUMN IF NOT EXISTS walkie_id TEXT;

COMMENT ON COLUMN sources.walkie_id IS 'Agent Walkie identity for P2P messaging responses (e.g., "MyTradingBot")';

COMMIT;

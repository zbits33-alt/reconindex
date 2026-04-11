-- Content Table: ecosystem_updates
-- Purpose: Living feed of XRPL activity for Casino Media
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS ecosystem_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE SET NULL,
  source_account TEXT,
  headline TEXT NOT NULL,
  summary TEXT,
  source_url TEXT,
  update_type TEXT CHECK (update_type IN (
    'launch', 'update', 'partnership', 'warning', 'milestone',
    'community', 'technical', 'market', 'governance', 'other'
  )),
  importance_score NUMERIC DEFAULT 0.5,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  approved BOOLEAN DEFAULT FALSE,
  approved_by TEXT,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ecosystem_updates_entity_id ON ecosystem_updates(entity_id);
CREATE INDEX IF NOT EXISTS idx_ecosystem_updates_type ON ecosystem_updates(update_type);
CREATE INDEX IF NOT EXISTS idx_ecosystem_updates_approved ON ecosystem_updates(approved) WHERE approved = TRUE;
CREATE INDEX IF NOT EXISTS idx_ecosystem_updates_detected ON ecosystem_updates(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_ecosystem_updates_importance ON ecosystem_updates(importance_score DESC);

COMMENT ON TABLE ecosystem_updates IS 'Living feed of XRPL ecosystem activity — launches, updates, partnerships, warnings, milestones';
COMMENT ON COLUMN ecosystem_updates.source_account IS 'X handle, RSS feed URL, or other source identifier';
COMMENT ON COLUMN ecosystem_updates.update_type IS 'Type of update: launch, update, partnership, warning, milestone, community, technical, market, governance, other';
COMMENT ON COLUMN ecosystem_updates.importance_score IS 'How important this update is (0–1), used for sorting and filtering';
COMMENT ON COLUMN ecosystem_updates.approved IS 'Whether this update has been reviewed and approved by Recon admins';

COMMIT;

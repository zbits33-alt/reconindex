-- ═══════════════════════════════════════════════════════
-- SUGGESTION BOX TABLE
-- Added: 2026-04-09
-- ═══════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS suggestions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submitter_name TEXT,
  submitter_type TEXT NOT NULL CHECK (submitter_type IN ('human', 'agent', 'bot', 'tool')),
  submitter_id  TEXT,                     -- agent source_id or human handle
  email         TEXT,                     -- optional contact
  category      TEXT NOT NULL CHECK (category IN (
                  'feature', 'improvement', 'bug', 'integration',
                  'documentation', 'ecosystem', 'other'
                )),
  title         TEXT NOT NULL,
  description   TEXT NOT NULL,
  priority      TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  status        TEXT DEFAULT 'submitted' CHECK (status IN (
                  'submitted', 'reviewed', 'approved', 'in_progress',
                  'implemented', 'rejected', 'deferred'
                )),
  recon_notes   TEXT,                     -- Recon's analysis/decision
  reviewed_at   TIMESTAMPTZ,
  reviewed_by   TEXT,                     -- who reviewed (Recon, human)
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_suggestions_status ON suggestions(status);
CREATE INDEX IF NOT EXISTS idx_suggestions_category ON suggestions(category);
CREATE INDEX IF NOT EXISTS idx_suggestions_submitter ON suggestions(submitter_type, submitter_id);

-- RLS policies (allow anonymous submissions, admin-only review)
ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;

-- Anyone can submit
CREATE POLICY "Anyone can insert suggestions" ON suggestions
  FOR INSERT WITH CHECK (true);

-- Anyone can read public suggestions (not rejected internal notes)
CREATE POLICY "Anyone can read non-sensitive suggestions" ON suggestions
  FOR SELECT USING (status != 'rejected' OR recon_notes IS NULL);

-- Service role can do everything
-- (handled by service_role key bypassing RLS)

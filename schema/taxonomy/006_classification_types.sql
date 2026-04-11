-- Taxonomy Table: classification_types
-- Purpose: Controlled vocabulary for classification dimensions
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS classification_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  allowed_values TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_classification_types_name ON classification_types(name);

COMMENT ON TABLE classification_types IS 'Controlled vocabulary for classification dimensions (e.g., chain_scope, vertical, audience)';
COMMENT ON COLUMN classification_types.allowed_values IS 'Optional constraint: list of valid values for this classification type';

-- Seed with default classification types
INSERT INTO classification_types (name, description, allowed_values) VALUES
  ('chain_scope', 'Which blockchain(s) this entity operates on', ARRAY['xrpl_native', 'xrpl_evm', 'cross_chain', 'multi_chain']),
  ('vertical', 'Primary business vertical or category', ARRAY['nft', 'defi', 'meme_coin', 'infra', 'media', 'trading', 'wallet', 'analytics', 'gaming', 'social']),
  ('audience', 'Primary target audience', ARRAY['collectors', 'builders', 'traders', 'newcomers', 'developers', 'investors', 'community']),
  ('monetization', 'How the entity generates revenue or sustains itself', ARRAY['fee_based', 'rewards_based', 'token_based', 'donation_based', 'free']),
  ('maturity', 'Development and market maturity', ARRAY['concept', 'live', 'scaling', 'dormant', 'deprecated'])
ON CONFLICT (name) DO NOTHING;

COMMIT;

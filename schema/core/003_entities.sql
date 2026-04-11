-- Core Table: entities
-- Purpose: Canonical master record for any ecosystem object
-- Replaces: assets table
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID REFERENCES sources(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  entity_type TEXT NOT NULL CHECK (entity_type IN (
    'project', 'platform', 'protocol', 'token', 'meme_coin',
    'nft_collection', 'nft_project', 'defi_app', 'marketplace',
    'infrastructure', 'wallet', 'tool', 'service',
    'media', 'community', 'developer_tool', 'analytics_tool',
    'documentation', 'event', 'partner'
  )),
  description TEXT,
  ecosystem TEXT[],
  stage TEXT CHECK (stage IN ('concept', 'prototype', 'testing', 'live', 'deprecated')),
  meta JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_entities_source_id ON entities(source_id);
CREATE INDEX IF NOT EXISTS idx_entities_type ON entities(entity_type);
CREATE INDEX IF NOT EXISTS idx_entities_stage ON entities(stage);
CREATE INDEX IF NOT EXISTS idx_entities_ecosystem ON entities USING GIN(ecosystem);

COMMENT ON TABLE entities IS 'Canonical master record for any ecosystem object (projects, tokens, NFTs, tools, etc.)';
COMMENT ON COLUMN entities.entity_type IS 'Type of entity: project, platform, protocol, token, meme_coin, nft_collection, nft_project, defi_app, marketplace, infrastructure, wallet, tool, service, media, community, developer_tool, analytics_tool, documentation, event, partner';
COMMENT ON COLUMN entities.stage IS 'Development stage: concept, prototype, testing, live, deprecated';

COMMIT;

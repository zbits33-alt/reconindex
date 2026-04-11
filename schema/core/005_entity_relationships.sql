-- Core Table: entity_relationships
-- Purpose: Map the ecosystem graph (partnerships, integrations, etc.)
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS entity_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  to_entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL CHECK (relationship_type IN (
    'partnered_with', 'built_by', 'integrates_with', 'powers',
    'part_of', 'related_to', 'supports', 'competes_with',
    'forked_from', 'acquired_by', 'inspired_by'
  )),
  bidirectional BOOLEAN DEFAULT FALSE,
  confidence NUMERIC DEFAULT 0.5,
  source TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(from_entity_id, to_entity_id, relationship_type)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_entity_relationships_from ON entity_relationships(from_entity_id);
CREATE INDEX IF NOT EXISTS idx_entity_relationships_to ON entity_relationships(to_entity_id);
CREATE INDEX IF NOT EXISTS idx_entity_relationships_type ON entity_relationships(relationship_type);

COMMENT ON TABLE entity_relationships IS 'Ecosystem graph: maps relationships between entities (partnerships, integrations, dependencies, etc.)';
COMMENT ON COLUMN entity_relationships.bidirectional IS 'If true, the reverse relationship is implied (e.g., partnered_with is symmetric)';
COMMENT ON COLUMN entity_relationships.confidence IS 'How certain Recon is about this relationship (0–1)';
COMMENT ON COLUMN entity_relationships.source IS 'Where this relationship was detected (submission ID, URL, manual entry)';

COMMIT;

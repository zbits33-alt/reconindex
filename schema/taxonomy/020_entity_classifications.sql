-- Taxonomy Table: entity_classifications
-- Purpose: Junction table linking entities to classification dimensions
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS entity_classifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  classification_type_id UUID REFERENCES classification_types(id),
  value TEXT NOT NULL,
  assigned_by TEXT DEFAULT 'reconindex',
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  confidence NUMERIC DEFAULT 0.5,
  UNIQUE(entity_id, classification_type_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_entity_classifications_entity_id ON entity_classifications(entity_id);
CREATE INDEX IF NOT EXISTS idx_entity_classifications_type_id ON entity_classifications(classification_type_id);
CREATE INDEX IF NOT EXISTS idx_entity_classifications_value ON entity_classifications(value);

COMMENT ON TABLE entity_classifications IS 'Junction table: links entities to classification dimensions (chain_scope, vertical, audience, etc.)';
COMMENT ON COLUMN entity_classifications.assigned_by IS 'Who set this classification: reconindex (auto), admin (manual), or source name';
COMMENT ON COLUMN entity_classifications.confidence IS 'How certain Recon is about this classification (0–1)';

COMMIT;

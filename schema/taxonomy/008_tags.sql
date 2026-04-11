-- Taxonomy Table: tags
-- Purpose: Proper tag taxonomy system (replaces TEXT[] arrays)
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  category TEXT,
  usage_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Junction: entities ↔ tags
CREATE TABLE IF NOT EXISTS entity_tags (
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  assigned_by TEXT DEFAULT 'reconindex',
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (entity_id, tag_id)
);

-- Junction: knowledge_units ↔ tags
CREATE TABLE IF NOT EXISTS knowledge_unit_tags (
  knowledge_unit_id UUID REFERENCES knowledge_units(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (knowledge_unit_id, tag_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);
CREATE INDEX IF NOT EXISTS idx_tags_category ON tags(category);
CREATE INDEX IF NOT EXISTS idx_entity_tags_tag_id ON entity_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_unit_tags_tag_id ON knowledge_unit_tags(tag_id);

COMMENT ON TABLE tags IS 'Proper tag taxonomy system — replaces TEXT[] arrays for efficient querying';
COMMENT ON TABLE entity_tags IS 'Junction: links entities to tags';
COMMENT ON TABLE knowledge_unit_tags IS 'Junction: links knowledge_units to tags';
COMMENT ON COLUMN tags.category IS 'Optional tag category: technology, vertical, chain, etc.';
COMMENT ON COLUMN tags.usage_count IS 'How many times this tag has been used (updated by trigger or cron)';

COMMIT;

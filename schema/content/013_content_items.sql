-- Content Table: content_items
-- Purpose: Browseable content layer for Society Libraries
-- Date: 2026-04-11

BEGIN;

CREATE TABLE IF NOT EXISTS content_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE SET NULL,
  content_type TEXT NOT NULL CHECK (content_type IN (
    'guide', 'tutorial', 'explainer', 'update', 'project_brief',
    'ecosystem_report', 'warning', 'event_post', 'profile', 'pattern_report'
  )),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  body TEXT,
  summary TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'in_review', 'approved', 'published', 'archived'
  )),
  author TEXT,
  published_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  view_count INT DEFAULT 0,
  meta JSONB DEFAULT '{}'
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_content_items_entity_id ON content_items(entity_id);
CREATE INDEX IF NOT EXISTS idx_content_items_slug ON content_items(slug);
CREATE INDEX IF NOT EXISTS idx_content_items_type ON content_items(content_type);
CREATE INDEX IF NOT EXISTS idx_content_items_status ON content_items(status);
CREATE INDEX IF NOT EXISTS idx_content_items_published ON content_items(published_at) WHERE status = 'published';

COMMENT ON TABLE content_items IS 'Browseable content layer for Society Libraries — guides, tutorials, project briefs, warnings, pattern reports';
COMMENT ON COLUMN content_items.content_type IS 'Type of content: guide, tutorial, explainer, update, project_brief, ecosystem_report, warning, event_post, profile, pattern_report';
COMMENT ON COLUMN content_items.status IS 'Content workflow status: draft, in_review, approved, published, archived';
COMMENT ON COLUMN content_items.author IS 'Who wrote this: reconindex (auto-generated), admin (manual), or source name';
COMMENT ON COLUMN content_items.view_count IS 'Number of times this content has been viewed (updated by API or cron)';

COMMIT;

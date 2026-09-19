-- +goose Up
-- CA4-3B: immutable Normal-Hero promotion restoration source facts only.
-- The runtime decomposition algorithm remains a separately versioned
-- compatibility policy; Activity activation/multipliers remain outside CA4-3B.

CREATE TABLE gxb_content_hero_promotion_restoration_equipment (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  equipment_item_id bigint NOT NULL CHECK (equipment_item_id > 0),
  source_quality smallint NOT NULL CHECK (source_quality BETWEEN 2 AND 6),
  PRIMARY KEY(revision_id,equipment_item_id),
  FOREIGN KEY(revision_id,equipment_item_id)
    REFERENCES gxb_content_equipment_primitives(revision_id,item_id) ON DELETE RESTRICT,
  FOREIGN KEY(revision_id,equipment_item_id)
    REFERENCES gxb_content_hero_fumo_targets(revision_id,item_id) ON DELETE RESTRICT
);

CREATE TABLE gxb_content_hero_promotion_restoration_fractions (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  quality smallint NOT NULL CHECK (quality BETWEEN 2 AND 6),
  numerator bigint NOT NULL CHECK (numerator > 0),
  denominator bigint NOT NULL CHECK (denominator > 0),
  PRIMARY KEY(revision_id,quality)
);

CREATE TABLE gxb_content_hero_promotion_restoration_denominations (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  ordinal smallint NOT NULL CHECK (ordinal >= 0),
  item_id bigint NOT NULL CHECK (item_id > 0),
  value bigint NOT NULL CHECK (value > 0),
  PRIMARY KEY(revision_id,ordinal),
  UNIQUE(revision_id,item_id),
  FOREIGN KEY(revision_id,item_id)
    REFERENCES gxb_content_hero_fumo_materials(revision_id,item_id) ON DELETE RESTRICT
);

-- Forward-only by project law. Rollback is restore/redeploy.

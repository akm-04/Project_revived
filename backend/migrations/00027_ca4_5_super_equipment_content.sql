-- +goose Up
-- CA4-5: immutable Super-Hero fixed equipment topology and enhancement policy.
-- Player-owned Super equipment state remains single-owned by player_heroes equip_1..equip_6.

CREATE TABLE gxb_content_super_equipment_positions (
  revision_id text NOT NULL,
  hero_table_id bigint NOT NULL CHECK (hero_table_id > 0),
  slot smallint NOT NULL CHECK (slot BETWEEN 1 AND 6),
  item_id bigint NOT NULL CHECK (item_id > 0),
  PRIMARY KEY(revision_id, hero_table_id, slot),
  FOREIGN KEY(revision_id, hero_table_id)
    REFERENCES gxb_content_hero_templates(revision_id, table_id) ON DELETE RESTRICT,
  FOREIGN KEY(revision_id, item_id)
    REFERENCES gxb_content_equipment_primitives(revision_id, item_id) ON DELETE RESTRICT
);
CREATE INDEX gxb_content_super_equipment_item_idx
  ON gxb_content_super_equipment_positions(revision_id, item_id);

CREATE TABLE gxb_content_super_equipment_caps (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  star smallint NOT NULL CHECK (star BETWEEN 1 AND 10),
  max_enhancement smallint NOT NULL CHECK (max_enhancement BETWEEN 1 AND 60),
  effective_client_reachable boolean NOT NULL,
  PRIMARY KEY(revision_id, star)
);

CREATE TABLE gxb_content_super_equipment_tiers (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  tier smallint NOT NULL CHECK (tier BETWEEN 1 AND 6),
  min_star smallint NOT NULL CHECK (min_star BETWEEN 1 AND 10),
  duplicate_count smallint NOT NULL CHECK (duplicate_count BETWEEN 1 AND 2),
  effective_client_reachable boolean NOT NULL,
  PRIMARY KEY(revision_id, tier)
);

-- Forward-only by project law. Rollback is restore/redeploy.

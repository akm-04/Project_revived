-- +goose Up
-- CA3-2: immutable Pet acquisition/incubation content and one player-wide
-- first-free acceleration use. Function-38 starter reconciliation is not a
-- migration-side gameplay write; it remains I5-owned and runs only after an
-- explicit PET_ACQUISITION_CA3-capable revision is active.

ALTER TABLE player_pet_roots
  ADD COLUMN first_free_hatch_used boolean NOT NULL DEFAULT false;

CREATE TABLE gxb_content_pet_acquisition (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  table_id bigint NOT NULL CHECK (table_id > 0),
  origin_table_id bigint NOT NULL CHECK (origin_table_id > 0),
  initial_star smallint NOT NULL CHECK (initial_star BETWEEN 1 AND 5),
  egg_item_id bigint NOT NULL CHECK (egg_item_id > 0),
  essence_item_id bigint NOT NULL CHECK (essence_item_id > 0),
  fragment_count bigint NOT NULL CHECK (fragment_count > 0),
  hatch_seconds bigint NOT NULL CHECK (hatch_seconds > 0),
  summon_type bigint NOT NULL CHECK (summon_type > 0),
  PRIMARY KEY(revision_id, table_id),
  UNIQUE(revision_id, origin_table_id),
  FOREIGN KEY(revision_id, table_id)
    REFERENCES gxb_content_pet_templates(revision_id, table_id) ON DELETE RESTRICT
);

CREATE TABLE gxb_content_pet_acquisition_policy (
  revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  starter_egg_item_id bigint NOT NULL CHECK (starter_egg_item_id > 0),
  hatch_cost_param bigint NOT NULL CHECK (hatch_cost_param > 0)
);

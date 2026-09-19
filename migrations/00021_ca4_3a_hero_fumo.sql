-- +goose Up
-- CA4-3A-A: immutable Hero Fumo content plus Hero-owned six-slot raw Fumo
-- durability. MID58 gameplay/route activation is deliberately not part of A.

CREATE TABLE gxb_content_hero_fumo_targets (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  item_id bigint NOT NULL CHECK (item_id > 0),
  threshold_increments jsonb NOT NULL CHECK (jsonb_typeof(threshold_increments)='array'),
  total_cap bigint NOT NULL CHECK (total_cap > 0),
  mana_per_fumo bigint NOT NULL CHECK (mana_per_fumo >= 0),
  attr_ids jsonb NOT NULL CHECK (jsonb_typeof(attr_ids)='array'),
  stage_delta_by_attr jsonb NOT NULL CHECK (jsonb_typeof(stage_delta_by_attr)='array'),
  PRIMARY KEY(revision_id,item_id)
);

CREATE TABLE gxb_content_hero_fumo_materials (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  item_id bigint NOT NULL CHECK (item_id > 0),
  item_type bigint NOT NULL CHECK (item_type IN (1,2,4,5,6)),
  moneng bigint NOT NULL CHECK (moneng > 0),
  resource_definition_key text NOT NULL,
  PRIMARY KEY(revision_id,item_id),
  FOREIGN KEY(revision_id,resource_definition_key)
    REFERENCES gxb_content_resource_definitions(revision_id,definition_key) ON DELETE RESTRICT
);

ALTER TABLE player_heroes
  ADD COLUMN fumo_1 bigint NOT NULL DEFAULT 0 CHECK (fumo_1 >= 0),
  ADD COLUMN fumo_2 bigint NOT NULL DEFAULT 0 CHECK (fumo_2 >= 0),
  ADD COLUMN fumo_3 bigint NOT NULL DEFAULT 0 CHECK (fumo_3 >= 0),
  ADD COLUMN fumo_4 bigint NOT NULL DEFAULT 0 CHECK (fumo_4 >= 0),
  ADD COLUMN fumo_5 bigint NOT NULL DEFAULT 0 CHECK (fumo_5 >= 0),
  ADD COLUMN fumo_6 bigint NOT NULL DEFAULT 0 CHECK (fumo_6 >= 0);

-- Forward-only by project law. Rollback is restore/redeploy.

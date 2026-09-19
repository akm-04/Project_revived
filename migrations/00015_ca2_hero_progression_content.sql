-- +goose Up
-- CA2-2: revision-bound Hero EXP consumable values. Content Registry owns this
-- immutable relation; gameplay never parses source Lua or hardcodes item EXP.

ALTER TABLE gxb_content_hero_super_star
  ADD COLUMN need_hero_num smallint NOT NULL DEFAULT 0 CHECK (need_hero_num >= 0);

CREATE TABLE gxb_content_hero_exp_items (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  item_id bigint NOT NULL CHECK (item_id > 0),
  exp_value bigint NOT NULL CHECK (exp_value > 0),
  PRIMARY KEY(revision_id, item_id)
);

-- Forward-only by project law. Rollback is restore/redeploy.

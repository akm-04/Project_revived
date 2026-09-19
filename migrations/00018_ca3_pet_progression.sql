-- +goose Up
-- CA3-3: Pet progression persistence and immutable progression content.
-- Expand-compatible raw skill defaults remain during mixed-version cutover so
-- pre-CA3-3 writers that omit these columns can still insert valid Pets.

ALTER TABLE player_pets
  ADD COLUMN skill_1 bigint NOT NULL DEFAULT 1 CHECK (skill_1 >= 1),
  ADD COLUMN skill_2 bigint NOT NULL DEFAULT 1 CHECK (skill_2 >= 1),
  ADD COLUMN skill_3 bigint NOT NULL DEFAULT 1 CHECK (skill_3 >= 1),
  ADD COLUMN skill_4 bigint NOT NULL DEFAULT 1 CHECK (skill_4 >= 1),
  ADD COLUMN skill_5 bigint NOT NULL DEFAULT 1 CHECK (skill_5 >= 1);

CREATE TABLE gxb_content_pet_progression (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  table_id bigint NOT NULL CHECK (table_id > 0),
  stone_item_id bigint NOT NULL CHECK (stone_item_id > 0),
  PRIMARY KEY(revision_id, table_id),
  FOREIGN KEY(revision_id, table_id)
    REFERENCES gxb_content_pet_templates(revision_id, table_id) ON DELETE RESTRICT
);

CREATE TABLE gxb_content_pet_skill_slots (
  revision_id text NOT NULL,
  table_id bigint NOT NULL,
  slot smallint NOT NULL CHECK (slot BETWEEN 1 AND 5),
  source_skill_id bigint NOT NULL CHECK (source_skill_id >= 0),
  star_bonus bigint NOT NULL CHECK (star_bonus >= 0),
  PRIMARY KEY(revision_id, table_id, slot),
  FOREIGN KEY(revision_id, table_id)
    REFERENCES gxb_content_pet_progression(revision_id, table_id) ON DELETE RESTRICT
);

CREATE TABLE gxb_content_pet_exp (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  level bigint NOT NULL CHECK (level BETWEEN 1 AND 100),
  exp_delta bigint NOT NULL CHECK (exp_delta >= 0),
  total_exp bigint NOT NULL CHECK (total_exp >= 0),
  PRIMARY KEY(revision_id, level)
);

CREATE TABLE gxb_content_pet_exp_items (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  item_id bigint NOT NULL CHECK (item_id > 0),
  exp_value bigint NOT NULL CHECK (exp_value > 0),
  PRIMARY KEY(revision_id, item_id)
);

CREATE TABLE gxb_content_pet_skill_books (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  effective_level bigint NOT NULL CHECK (effective_level BETWEEN 1 AND 130),
  book_count bigint NOT NULL CHECK (book_count > 0),
  PRIMARY KEY(revision_id, effective_level)
);

CREATE TABLE gxb_content_pet_skill_slot_policy (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  slot smallint NOT NULL CHECK (slot BETWEEN 1 AND 5),
  effective_offset bigint NOT NULL CHECK (effective_offset >= 0),
  min_color bigint NOT NULL CHECK (min_color >= 0),
  requires_awakened boolean NOT NULL,
  PRIMARY KEY(revision_id, slot)
);

CREATE TABLE gxb_content_pet_evolution (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  target_star smallint NOT NULL CHECK (target_star BETWEEN 2 AND 5),
  stone_count bigint NOT NULL CHECK (stone_count > 0),
  PRIMARY KEY(revision_id, target_star)
);

CREATE TABLE gxb_content_pet_progression_policy (
  revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  skill_book_item_id bigint NOT NULL CHECK (skill_book_item_id > 0)
);

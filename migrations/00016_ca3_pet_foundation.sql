-- +goose Up
-- CA3-1: Pet core identity, immutable lineage content, empty owner root,
-- private roster persistence, and reload projection. Acquisition/progression,
-- capacity, starter entitlement, and independent is_born semantics are absent.

CREATE TABLE gxb_content_pet_templates (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  table_id bigint NOT NULL CHECK (table_id > 0),
  origin_table_id bigint NOT NULL CHECK (origin_table_id > 0),
  is_awakened boolean NOT NULL,
  awaken_table_id bigint NOT NULL CHECK (awaken_table_id >= 0),
  initial_star smallint NOT NULL CHECK (initial_star BETWEEN 1 AND 5),
  PRIMARY KEY(revision_id, table_id)
);
CREATE INDEX gxb_content_pet_templates_origin_idx ON gxb_content_pet_templates(revision_id, origin_table_id);

CREATE TABLE player_pet_roots (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  next_pet_id bigint NOT NULL DEFAULT 1 CHECK (next_pet_id > 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE player_pets (
  player_id bigint NOT NULL REFERENCES player_pet_roots(player_id) ON DELETE CASCADE,
  pet_id bigint NOT NULL CHECK (pet_id > 0),
  table_id bigint NOT NULL CHECK (table_id > 0),
  origin_table_id bigint NOT NULL CHECK (origin_table_id > 0),
  star smallint NOT NULL CHECK (star BETWEEN 1 AND 5),
  level bigint NOT NULL CHECK (level > 0),
  exp bigint NOT NULL CHECK (exp >= 0),
  color smallint NOT NULL CHECK (color BETWEEN 1 AND 16),
  birthday bigint NOT NULL CHECK (birthday >= 0),
  is_show boolean NOT NULL,
  creation_content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  state_version bigint NOT NULL CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_id, pet_id),
  UNIQUE(player_id, origin_table_id)
);
CREATE INDEX player_pets_table_idx ON player_pets(player_id, table_id);

-- Existing V2 players gain only the Pet owner root. No starter egg/Pet,
-- capacity, tutorial occurrence, birthday, or hatch/show transition is fabricated.
INSERT INTO player_pet_roots(player_id,next_pet_id,state_version,created_at,updated_at)
SELECT player_id,1,1,transaction_timestamp(),transaction_timestamp()
FROM players
ON CONFLICT (player_id) DO NOTHING;

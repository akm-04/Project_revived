-- +goose Up
-- CA2-1: Hero foundation, immutable Hero content, and private roster projection.
-- Character Asset owns player_hero_roots/player_heroes. Content Registry owns
-- gxb_content_hero_* tables. Capacity policy is intentionally absent/UNKNOWN.

CREATE TABLE gxb_content_hero_templates (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  table_id bigint NOT NULL CHECK (table_id > 0),
  origin_table_id bigint NOT NULL CHECK (origin_table_id > 0),
  kind text NOT NULL CHECK (kind IN ('NORMAL','SUPER')),
  is_awakened boolean NOT NULL,
  initial_star smallint NOT NULL CHECK (initial_star BETWEEN 1 AND 8),
  fragment_item_id bigint NOT NULL CHECK (fragment_item_id >= 0),
  PRIMARY KEY(revision_id, table_id)
);
CREATE INDEX gxb_content_hero_templates_origin_idx ON gxb_content_hero_templates(revision_id, origin_table_id);

CREATE TABLE gxb_content_hero_exp (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  level smallint NOT NULL CHECK (level BETWEEN 1 AND 100),
  exp_delta bigint NOT NULL CHECK (exp_delta >= 0),
  total_exp bigint NOT NULL CHECK (total_exp >= 0),
  PRIMARY KEY(revision_id, level)
);

CREATE TABLE gxb_content_hero_normal_star (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  target_star smallint NOT NULL CHECK (target_star BETWEEN 1 AND 5),
  evolve_fragment_count bigint NOT NULL CHECK (evolve_fragment_count >= 0),
  evolve_mana bigint NOT NULL CHECK (evolve_mana >= 0),
  summon_fragment_count bigint NOT NULL CHECK (summon_fragment_count >= 0),
  summon_mana bigint NOT NULL CHECK (summon_mana >= 0),
  PRIMARY KEY(revision_id, target_star)
);

CREATE TABLE gxb_content_hero_super_star (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  target_star smallint NOT NULL CHECK (target_star BETWEEN 1 AND 10),
  fragment_count bigint NOT NULL CHECK (fragment_count >= 0),
  mana bigint NOT NULL CHECK (mana >= 0),
  effective_client_reachable boolean NOT NULL,
  PRIMARY KEY(revision_id, target_star)
);

CREATE TABLE gxb_content_super_hero_prerequisites (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  super_table_id bigint NOT NULL CHECK (super_table_id > 0),
  ordinal smallint NOT NULL CHECK (ordinal BETWEEN 1 AND 5),
  prerequisite_origin_table_id bigint NOT NULL CHECK (prerequisite_origin_table_id > 0),
  PRIMARY KEY(revision_id, super_table_id, ordinal),
  UNIQUE(revision_id, super_table_id, prerequisite_origin_table_id)
);

CREATE TABLE player_hero_roots (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  next_partner_id bigint NOT NULL DEFAULT 1 CHECK (next_partner_id > 0),
  sort_type integer NOT NULL DEFAULT 0 CHECK (sort_type BETWEEN 0 AND 8191),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE player_heroes (
  player_id bigint NOT NULL REFERENCES player_hero_roots(player_id) ON DELETE CASCADE,
  partner_id bigint NOT NULL CHECK (partner_id > 0),
  table_id bigint NOT NULL CHECK (table_id > 0),
  origin_table_id bigint NOT NULL CHECK (origin_table_id > 0),
  star smallint NOT NULL CHECK (star BETWEEN 1 AND 8),
  level bigint NOT NULL CHECK (level > 0),
  exp bigint NOT NULL CHECK (exp >= 0),
  color smallint NOT NULL CHECK (color BETWEEN 1 AND 16),
  creation_content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  state_version bigint NOT NULL CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_id, partner_id),
  UNIQUE(player_id, origin_table_id)
);
CREATE INDEX player_heroes_table_idx ON player_heroes(player_id, table_id);

-- Existing V2 players gain infrastructure only. No starter Hero or capacity is fabricated.
INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)
SELECT player_id,1,0,1,transaction_timestamp(),transaction_timestamp()
FROM players
ON CONFLICT (player_id) DO NOTHING;

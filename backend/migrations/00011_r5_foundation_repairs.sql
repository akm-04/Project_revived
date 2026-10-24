-- +goose Up
-- R5: progression/temporal/function eligibility foundations.
-- Historical migrations remain immutable; this migration only expands the
-- content/owner model required by the candidate-bound Pass480 R5 contract.

ALTER TABLE gxb_content_resource_definitions
  DROP CONSTRAINT gxb_content_resource_definitions_settlement_activation_check;
ALTER TABLE gxb_content_resource_definitions
  ADD CONSTRAINT gxb_content_resource_definitions_settlement_activation_check
  CHECK (settlement_activation IN ('ENABLED_R4','ENABLED_R5','OWNER_REQUIRED','R5_REQUIRED','FAIL_CLOSED'));

-- Stock numeric 0 means paused/full last-regeneration anchor. SQL NULL is the
-- canonical durable representation of that sentinel.
ALTER TABLE player_temporal_resources
  ALTER COLUMN regen_anchor_at DROP NOT NULL;

CREATE TABLE player_function_state_owners (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL
);

INSERT INTO player_function_state_owners(player_id,state_version,updated_at)
SELECT p.player_id,1,p.updated_at
FROM player_progression p
ON CONFLICT(player_id) DO NOTHING;

CREATE TABLE player_function_eligibility (
  player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  function_id bigint NOT NULL CHECK (function_id > 0),
  content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  source_fact_key text NOT NULL CHECK (btrim(source_fact_key) <> ''),
  eligible_at timestamptz NOT NULL,
  PRIMARY KEY(player_id,function_id),
  UNIQUE(player_id,source_fact_key)
);

CREATE TABLE gxb_content_function_gates (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  function_id bigint NOT NULL CHECK (function_id > 0),
  gate_kind text NOT NULL CHECK (gate_kind IN ('PURE_LEVEL','UNSUPPORTED_COMPOSITE')),
  required_level bigint NULL CHECK (required_level IS NULL OR required_level > 0),
  raw_open_value text NOT NULL,
  source_fact_key text NOT NULL CHECK (btrim(source_fact_key) <> ''),
  announcement_capability text NOT NULL DEFAULT 'NONE' CHECK (btrim(announcement_capability) <> ''),
  PRIMARY KEY(revision_id,function_id)
);

-- Forward-only by project law. Rollback is restore/redeploy.

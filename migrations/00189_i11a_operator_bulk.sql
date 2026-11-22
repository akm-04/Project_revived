-- +goose Up
-- owner: operator
-- I11A-2 O2 bulk target core (I11A_OPERATOR_COMMANDS_V1 ruling 5): the bus
-- freezes the resolved recipient set in the command transaction and a River
-- job settles one recipient at a time with the command key plus recipient as
-- the business key. The applied/refused counters are the resume cursor.
CREATE TABLE operator_bulk_targets (
  semantic_key text PRIMARY KEY REFERENCES operator_commands(semantic_key) ON DELETE RESTRICT,
  module_command text NOT NULL CHECK (module_command ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'),
  selector text NOT NULL CHECK (selector IN ('players', 'server', 'global')),
  player_ids jsonb NOT NULL CHECK (jsonb_typeof(player_ids) = 'array'),
  player_count integer NOT NULL CHECK (player_count >= 0),
  player_ids_sha256 text NOT NULL CHECK (player_ids_sha256 ~ '^[0-9a-f]{64}$'),
  payload jsonb NOT NULL,
  principal text NOT NULL CHECK (char_length(principal) BETWEEN 1 AND 64),
  reason text NOT NULL CHECK (char_length(reason) BETWEEN 1 AND 500),
  processed integer NOT NULL DEFAULT 0 CHECK (processed >= 0),
  applied integer NOT NULL DEFAULT 0 CHECK (applied >= 0),
  refused integer NOT NULL DEFAULT 0 CHECK (refused >= 0),
  state text NOT NULL DEFAULT 'PENDING' CHECK (state IN ('PENDING', 'DONE')),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  finished_at timestamptz,
  CHECK ((state = 'DONE') = (finished_at IS NOT NULL)),
  CHECK (processed <= player_count)
);
CREATE INDEX operator_bulk_targets_pending ON operator_bulk_targets (created_at, semantic_key) WHERE state = 'PENDING';

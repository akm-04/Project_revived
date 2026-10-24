-- +goose Up
-- Pass438 / I4: minimum stock-visible player directory projection.
-- owner: player-core/directory-projection
-- bootstrap creator: identity/logicalserver/bootstrap
--
-- Wave-D requires MID18 to expose complete character summaries rather than
-- half-characters.  Player Core is implemented in I5; this table is the narrow
-- forward seam that lets I4 create the source-consumed directory projection in
-- the same transaction as the player root.  I5 becomes the canonical mutator.
--
-- 110001001 is corroborated by the frozen V1 oracle and is an initial-owned
-- avatar row in the verified current avatar.lua corpus.  A numeric zero is not
-- used because RegionWindow passes avatar_id directly to setPlayerAvatar.
--
-- Pass436 never had a canonical directory/profile row, so an already-populated
-- players table cannot be upgraded by inventing names/avatar/progression state.
-- Fail closed and require an explicit evidence-backed import/backfill procedure.
-- +goose StatementBegin
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM players LIMIT 1) THEN
    RAISE EXCEPTION 'I4 player-directory migration refuses to invent profile state for existing player roots; run an explicit verified backfill/import first';
  END IF;
END $$;
-- +goose StatementEnd

CREATE TABLE player_directory_profiles (
  player_id bigint PRIMARY KEY REFERENCES players(player_id),
  name text NOT NULL DEFAULT '',
  lev bigint NOT NULL DEFAULT 1 CHECK (lev >= 1),
  vip bigint NOT NULL DEFAULT 0 CHECK (vip >= 0),
  avatar_id bigint NOT NULL DEFAULT 110001001 CHECK (avatar_id > 0),
  avatar_frame_id bigint NOT NULL DEFAULT 0 CHECK (avatar_frame_id >= 0),
  conquer_lev bigint NOT NULL DEFAULT 0 CHECK (conquer_lev >= 0),
  conquer_loop_id bigint NOT NULL DEFAULT 1 CHECK (conquer_loop_id >= 1),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

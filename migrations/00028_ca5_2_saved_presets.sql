-- +goose Up
-- CA5-2: saved-preset canonical owner, ordered lane/reference state, and the
-- permanent player-scoped rank-440 root. Raw stock strings are projections.

CREATE TABLE player_saved_preset_roots (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE player_saved_preset_lanes (
  player_id bigint NOT NULL REFERENCES player_saved_preset_roots(player_id) ON DELETE CASCADE,
  lane_ordinal integer NOT NULL CHECK (lane_ordinal > 0),
  name text NOT NULL,
  pet_id bigint NULL CHECK (pet_id IS NULL OR pet_id > 0),
  PRIMARY KEY(player_id,lane_ordinal)
);
CREATE INDEX player_saved_preset_lanes_pet_ref_idx
  ON player_saved_preset_lanes(player_id,pet_id) WHERE pet_id IS NOT NULL;

CREATE TABLE player_saved_preset_heroes (
  player_id bigint NOT NULL,
  lane_ordinal integer NOT NULL,
  hero_ordinal integer NOT NULL CHECK (hero_ordinal > 0),
  partner_id bigint NOT NULL CHECK (partner_id > 0),
  PRIMARY KEY(player_id,lane_ordinal,hero_ordinal),
  FOREIGN KEY(player_id,lane_ordinal)
    REFERENCES player_saved_preset_lanes(player_id,lane_ordinal) ON DELETE CASCADE
);
CREATE INDEX player_saved_preset_heroes_hero_ref_idx
  ON player_saved_preset_heroes(player_id,partner_id);

-- Existing V2 players gain only the empty saved-preset owner root. No preset
-- lane, Hero reference, Pet reference, name, capacity or gameplay policy is fabricated.
INSERT INTO player_saved_preset_roots(player_id,state_version,created_at,updated_at)
SELECT player_id,1,transaction_timestamp(),transaction_timestamp()
FROM players
ON CONFLICT (player_id) DO NOTHING;

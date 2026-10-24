-- +goose Up
-- R2C: durable TypedEconomy owner/root fence.
--
-- This row is synchronization/creation authority only. It does NOT encode a
-- starter balance, temporal anchor, item, or source content policy. Those
-- remain owned by the source-correct R4/R5 repair.
CREATE TABLE player_economy_owners (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  state_version bigint NOT NULL CHECK (state_version > 0),
  created_at timestamptz NOT NULL
);

-- Forward-compatible repair for players created before R2C. There is no
-- gameplay-value invention here: the owner row contains no balances.
INSERT INTO player_economy_owners(player_id,state_version,created_at)
SELECT p.player_id,1,p.created_at
FROM players p
ON CONFLICT (player_id) DO NOTHING;

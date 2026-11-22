-- +goose Up
-- owner: Arena
-- D507: the opponents of the last issued match lists stay fightable after a
-- refresh; pre-existing players start with no retained list.
ALTER TABLE arena_players ADD COLUMN recent_offers jsonb NOT NULL DEFAULT '[]'::jsonb
 CHECK(jsonb_typeof(recent_offers)='array' AND jsonb_array_length(recent_offers)<=3);
CREATE INDEX arena_matches_attacker_fingerprint ON arena_matches(attacker_id,fingerprint) WHERE status='SETTLED';

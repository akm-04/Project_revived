-- +goose Up
-- owner: OneOnOne
-- D488 parity: the latest issued normal-mode MATCH list records the challenger
-- and target ranks it showed. A player whose offer predates this column has no
-- snapshot, so START treats the offer as stale (35026).
ALTER TABLE one_on_one_players ADD COLUMN offer_snapshot jsonb
 CHECK(offer_snapshot IS NULL OR jsonb_typeof(offer_snapshot)='object');

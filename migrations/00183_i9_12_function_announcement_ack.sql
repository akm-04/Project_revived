-- +goose Up
-- owner: player-core
-- BUGS #114: the stock client starts a function guide only from a reply's
-- new_funcs_ (Backend.lua:775-777, SelfPlayer.lua:487-518,554). An announcement
-- whose reply is lost must repeat on later successful replies until the client
-- acknowledges it. NULL means pending; rows written before this migration were
-- announced under the one-shot rule, so they are backfilled as acknowledged.
ALTER TABLE player_function_unlocks ADD COLUMN acknowledged_at timestamptz;

UPDATE player_function_unlocks SET acknowledged_at = opened_at;

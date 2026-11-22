-- +goose Up
-- owner: identity/logicalserver/bootstrap
-- D510: random Dorm visits select the 256 most recently active same-server
-- players from the canonical login activity owner.
CREATE INDEX player_login_observations_server_activity_idx ON player_login_observations(logical_server_id,last_login_at DESC,player_id DESC);

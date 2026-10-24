-- +goose Up
-- owner: identity/logicalserver/bootstrap
-- I8.5-6 F3 (D63 private policy): stock builds other_player_id as
-- table_id + region*100000 for robots and players alike and classifies
-- table_id <= 25000 as a robot, so new characters are allocated above that
-- range. Players already allocated below it keep their ids.
UPDATE logical_servers
SET next_player_id = logical_server_id::bigint*100000 + 25001, state_version = state_version + 1
WHERE next_player_id < logical_server_id::bigint*100000 + 25001;
ALTER TABLE logical_servers ADD CONSTRAINT logical_servers_cursor_above_robot_range
  CHECK (next_player_id >= logical_server_id::bigint*100000 + 25001);

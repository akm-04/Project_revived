-- +goose Up
-- owner: identity/logicalserver/bootstrap
CREATE TABLE player_login_observations (
 player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 last_login_at timestamptz NOT NULL,
 source_operation_id uuid NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 CHECK(player_id>logical_server_id::bigint*100000 AND player_id<(logical_server_id::bigint+1)*100000)
);
CREATE INDEX gameplay_contexts_player_id_idx ON gameplay_contexts(player_id);

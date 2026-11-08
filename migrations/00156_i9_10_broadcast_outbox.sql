-- +goose Up
-- owner: Broadcast
CREATE TABLE broadcast_outbox (
	broadcast_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	logical_server_id integer NOT NULL,
	mid smallint NOT NULL,
	msg_type integer NOT NULL,
	player_id bigint NOT NULL REFERENCES players(player_id),
	enemy_player_id bigint REFERENCES players(player_id),
	fields jsonb NOT NULL,
	created_at timestamptz NOT NULL
);

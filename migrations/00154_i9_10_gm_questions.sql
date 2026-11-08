-- +goose Up
-- owner: gmquestion
CREATE TABLE player_gm_questions (
 operation_id uuid PRIMARY KEY,
 player_id bigint NOT NULL REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 message text NOT NULL CHECK(octet_length(message) BETWEEN 1 AND 4096),
 asked_at timestamptz NOT NULL,
 CHECK(player_id/100000=logical_server_id)
);
CREATE INDEX player_gm_questions_history ON player_gm_questions(player_id,logical_server_id,asked_at DESC,operation_id DESC);

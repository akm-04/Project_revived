-- +goose Up
-- R6 undelivered-reply replay: one cache row per player holding the latest committed reply the edge could not
-- deliver. Not restored (cache) and cleared by the player's next state-changing request.
CREATE TABLE player_undelivered_replies (
    player_id bigint PRIMARY KEY REFERENCES players(player_id),
    session_id uuid NOT NULL,
    mid bigint NOT NULL,
    params_fingerprint bytea NOT NULL CHECK (octet_length(params_fingerprint) = 32),
    reply bytea NOT NULL,
    marked_at timestamptz NOT NULL
);

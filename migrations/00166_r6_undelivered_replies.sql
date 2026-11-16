-- +goose Up
-- R6 undelivered-reply replay: one cache row per player. claim fences a mark
-- write by the state request that took it; a row whose reply is NULL holds
-- only the claim and is not replayable.
CREATE SEQUENCE player_undelivered_replies_claim_seq AS bigint START WITH 1 INCREMENT BY 1 NO CYCLE;
CREATE TABLE player_undelivered_replies (
    player_id bigint PRIMARY KEY REFERENCES players(player_id),
    claim bigint NOT NULL DEFAULT nextval('player_undelivered_replies_claim_seq'),
    session_id uuid,
    mid bigint,
    params_fingerprint bytea CHECK (params_fingerprint IS NULL OR octet_length(params_fingerprint) = 32),
    reply bytea,
    marked_at timestamptz
);

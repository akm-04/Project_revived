-- +goose Up
-- owner: TopFloor
-- D488: the latest issued offer set per player and mode generation, so 294/285 and
-- START can detect a moved challenger or selected opponent without an opponent lease.
CREATE TABLE top_floor_offer_snapshots (
 player_id bigint NOT NULL,
 logical_server_id bigint NOT NULL,
 scope smallint NOT NULL CHECK (scope IN (0,1)),
 generation bigint NOT NULL CHECK (generation >= 0),
 challenger_rank bigint NOT NULL CHECK (challenger_rank >= 1),
 offers jsonb NOT NULL CHECK (jsonb_typeof(offers) = 'array' AND jsonb_array_length(offers) <= 3),
 updated_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, scope)
);

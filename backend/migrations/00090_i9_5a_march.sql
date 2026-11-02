-- +goose Up
-- owner: content-registry
CREATE TABLE content_march_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);
-- owner: march
CREATE TABLE march_players (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 updated_at timestamptz NOT NULL
);

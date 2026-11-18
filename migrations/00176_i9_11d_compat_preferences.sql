-- +goose Up
-- owner: Content
CREATE TABLE content_compat_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object')
);
-- owner: compat
CREATE TABLE player_compat_preferences (
 player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
 first_main_touch smallint NOT NULL DEFAULT 1 CHECK (first_main_touch IN (0, 1)),
 message_push_ids bigint[] NOT NULL DEFAULT '{}',
 state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL
);
-- I9-11D C1: existing players were already past first touch before this table
-- existed; a player without a row is a new player and projects 0.
INSERT INTO player_compat_preferences(player_id, first_main_touch, state_version, created_at, updated_at)
SELECT player_id, 1, 1, now(), now() FROM players;

-- +goose Up
-- owner: public-profile
-- Canonical immutable custom-avatar references and retained publication history.
-- Physical bytes/control pins remain owned by ProfileAssetStore.
CREATE TABLE player_public_profile_media_history (
 operation_id uuid PRIMARY KEY,
 player_id bigint NOT NULL REFERENCES player_public_profile_roots(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 reference jsonb NOT NULL CHECK(jsonb_typeof(reference)='object'),
 root_version bigint NOT NULL CHECK(root_version > 0),
 decision_at timestamptz NOT NULL,
 UNIQUE(player_id,operation_id)
);
CREATE TABLE player_public_profile_media_current (
 player_id bigint PRIMARY KEY REFERENCES player_public_profile_roots(player_id),
 operation_id uuid NOT NULL,
 FOREIGN KEY(player_id,operation_id) REFERENCES player_public_profile_media_history(player_id,operation_id)
);

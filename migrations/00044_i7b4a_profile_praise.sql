-- +goose Up
CREATE TABLE player_profile_feedback_roots (
 player_id bigint PRIMARY KEY CHECK (player_id > 0),
 state_version bigint NOT NULL CHECK (state_version > 0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK (updated_at >= created_at)
);
CREATE TABLE player_profile_praises (
 target_player_id bigint NOT NULL REFERENCES player_profile_feedback_roots(player_id),
 actor_player_id bigint NOT NULL CHECK (actor_player_id > 0 AND actor_player_id <> target_player_id),
 praise_time timestamptz NOT NULL,
 root_version bigint NOT NULL CHECK (root_version > 0),
 PRIMARY KEY(target_player_id,actor_player_id)
);
CREATE INDEX player_profile_praises_history ON player_profile_praises(target_player_id,praise_time DESC,actor_player_id DESC);

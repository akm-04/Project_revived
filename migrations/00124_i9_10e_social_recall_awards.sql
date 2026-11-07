-- +goose Up
-- owner: socialrecall
CREATE TABLE social_recall_awards (
 player_id bigint NOT NULL REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 award_id bigint NOT NULL CHECK(award_id>0),
 gift_id bigint NOT NULL CHECK(gift_id>0),
 operation_id uuid NOT NULL UNIQUE,
 content_revision text NOT NULL CHECK(content_revision ~ '^[0-9a-f]{64}$'),
 policy_version text NOT NULL CHECK(length(policy_version)>0),
 grant_key text NOT NULL UNIQUE CHECK(grant_key ~ '^[0-9a-f]{64}$'),
 earned_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,award_id),
 CHECK(player_id/100000=logical_server_id)
);

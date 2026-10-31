-- +goose Up
-- owner: content-registry
CREATE TABLE content_world_boss_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);
-- owner: worldboss
CREATE TABLE worldboss_occurrences (
 logical_server_id integer PRIMARY KEY REFERENCES logical_servers(logical_server_id),
 generation bigint NOT NULL CHECK(generation>0),
 current_boss bigint NOT NULL CHECK(current_boss BETWEEN 10011 AND 10015),
 courage bigint NOT NULL CHECK(courage>=0),
 courage_day bigint NOT NULL,
 updated_at timestamptz NOT NULL
);
CREATE TABLE worldboss_players (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 challenged_day bigint NOT NULL CHECK(challenged_day>=0),
 day bigint NOT NULL CHECK(day>=0),
 attempts bigint NOT NULL CHECK(attempts>=0),
 bought bigint NOT NULL CHECK(bought>=0),
 swept_day bigint NOT NULL CHECK(swept_day>=0),
 best_hit bigint NOT NULL CHECK(best_hit>=0),
 best_hit_at bigint NOT NULL,
 updated_at timestamptz NOT NULL
);
CREATE INDEX worldboss_players_challengers_idx ON worldboss_players(logical_server_id,challenged_day);
CREATE TABLE worldboss_player_totals (
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 generation bigint NOT NULL CHECK(generation>0),
 boss_id bigint NOT NULL CHECK(boss_id BETWEEN 10011 AND 10015),
 player_id bigint NOT NULL REFERENCES players(player_id),
 hurt bigint NOT NULL CHECK(hurt>=0),
 first_hurt_at bigint NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(logical_server_id,generation,boss_id,player_id)
);
CREATE INDEX worldboss_player_totals_rank_idx ON worldboss_player_totals(logical_server_id,generation,boss_id,hurt DESC,first_hurt_at,player_id);
CREATE TABLE worldboss_attempts (
 attempt_id text PRIMARY KEY,
 attempt_sequence bigint GENERATED ALWAYS AS IDENTITY,
 player_id bigint NOT NULL REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 generation bigint NOT NULL CHECK(generation>0),
 campaign_id bigint NOT NULL CHECK(campaign_id BETWEEN 10011 AND 10015),
 formation text NOT NULL,
 frozen_at bigint NOT NULL,
 resolved boolean NOT NULL,
 damage bigint NOT NULL CHECK(damage>=0)
);
CREATE UNIQUE INDEX worldboss_attempts_open_idx ON worldboss_attempts(player_id) WHERE NOT resolved;
CREATE INDEX worldboss_attempts_player_idx ON worldboss_attempts(player_id,logical_server_id,campaign_id,attempt_sequence DESC);

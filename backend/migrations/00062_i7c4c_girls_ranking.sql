-- +goose Up
-- owner: Ranking
CREATE TABLE ranking_girls_roots (
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 policy_id text NOT NULL CHECK(length(policy_id)>0),
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 PRIMARY KEY(logical_server_id,policy_id)
);
CREATE TABLE ranking_girls_snapshots (
 logical_server_id integer NOT NULL,
 policy_id text NOT NULL,
 generation bigint NOT NULL CHECK(generation>0),
 operation_id uuid NOT NULL UNIQUE,
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 observed_at timestamptz NOT NULL,
 digest text NOT NULL CHECK(digest ~ '^[0-9a-f]{64}$'),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 PRIMARY KEY(logical_server_id,policy_id,generation),
 FOREIGN KEY(logical_server_id,policy_id) REFERENCES ranking_girls_roots(logical_server_id,policy_id)
);
CREATE TABLE ranking_girls_periods (
 logical_server_id integer NOT NULL,
 policy_id text NOT NULL,
 week_start timestamptz NOT NULL,
 snapshot_generation bigint NOT NULL,
 settled_at timestamptz,
 PRIMARY KEY(logical_server_id,policy_id,week_start),
 FOREIGN KEY(logical_server_id,policy_id,snapshot_generation) REFERENCES ranking_girls_snapshots(logical_server_id,policy_id,generation)
);
CREATE INDEX ranking_girls_pending_periods ON ranking_girls_periods(logical_server_id,policy_id,week_start) WHERE settled_at IS NULL;
CREATE TABLE ranking_girls_awards (
 logical_server_id integer NOT NULL,
 policy_id text NOT NULL,
 week_start timestamptz NOT NULL,
 player_id bigint NOT NULL REFERENCES players(player_id),
 rank bigint NOT NULL CHECK(rank BETWEEN 1 AND 20),
 title_id bigint NOT NULL CHECK(title_id BETWEEN 100059 AND 100062),
 origin_key text NOT NULL UNIQUE,
 starts_at timestamptz NOT NULL,
 end_time bigint NOT NULL CHECK(end_time>0),
 PRIMARY KEY(logical_server_id,policy_id,week_start,player_id),
 FOREIGN KEY(logical_server_id,policy_id,week_start) REFERENCES ranking_girls_periods(logical_server_id,policy_id,week_start)
);
CREATE TABLE ranking_girls_birth_tracking (
 player_id bigint NOT NULL REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 policy_id text NOT NULL CHECK(length(policy_id)>0),
 started_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,policy_id)
);

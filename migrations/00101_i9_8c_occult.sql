-- +goose Up
-- owner: content-registry
CREATE TABLE content_occult_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);

-- owner: occult
-- lock rank 605: a player's best score per chapter. Tickets are I5 scalars.
CREATE TABLE occult_players (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 scores jsonb NOT NULL CHECK(jsonb_typeof(scores)='object'),
 updated_at timestamptz NOT NULL
);
-- One row per started room; the live run state is the shared room payload
-- (rank 607). This row outlives the room and keys the logs and reports.
CREATE TABLE occult_runs (
 room_id bigint PRIMARY KEY,
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 chapter_id integer NOT NULL CHECK(chapter_id BETWEEN 1 AND 6),
 campaign_type integer NOT NULL CHECK(campaign_type IN (1,2)),
 started_at timestamptz NOT NULL,
 finished_at timestamptz,
 CHECK(finished_at IS NULL OR finished_at>=started_at)
);
CREATE TABLE occult_reports (
 report_id text PRIMARY KEY,
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 room_id bigint NOT NULL REFERENCES occult_runs(room_id),
 member_ids bigint[] NOT NULL CHECK(cardinality(member_ids) BETWEEN 1 AND 3),
 content jsonb NOT NULL,
 created_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL,
 CHECK(expires_at=created_at+interval '7 days')
);
CREATE INDEX occult_reports_expiry_idx ON occult_reports(expires_at,report_id);
CREATE TABLE occult_logs (
 log_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 room_id bigint NOT NULL REFERENCES occult_runs(room_id),
 log_type integer NOT NULL CHECK(log_type IN (1,2)),
 player_id bigint NOT NULL REFERENCES players(player_id),
 content jsonb NOT NULL,
 created_at timestamptz NOT NULL
);
CREATE INDEX occult_logs_room_idx ON occult_logs(room_id,log_id);
CREATE INDEX occult_logs_player_idx ON occult_logs(player_id,log_id DESC);

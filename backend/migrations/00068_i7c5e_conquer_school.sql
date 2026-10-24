-- +goose Up
-- owner: Content
CREATE TABLE content_conquer_mode_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: conquer
-- C5E_CONQUER_SCHOOL_MODE_V1 / C5E_CONQUER_PRIVATE_POLICY_V1. Mode state beside the
-- I7C-2J facts row (run/progress stay there); empty on upgrade, created by the first INFO.
CREATE TABLE conquer_school_players(
 player_id bigint PRIMARY KEY REFERENCES player_conquer_facts(player_id),
 logical_server_id bigint NOT NULL REFERENCES logical_servers(logical_server_id),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 state jsonb NOT NULL CHECK(jsonb_typeof(state)='object' AND (state->>'left_times')::bigint>=0 AND (state->>'buff')::bigint BETWEEN 0 AND 10
  AND (state->>'buy_times')::bigint BETWEEN 0 AND 10 AND (state->>'report_award_times')::bigint BETWEEN 0 AND 10),
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at),
 CHECK(player_id/100000=logical_server_id)
);
-- Kept won-fight reports, immutable; only the best report_limit per (loop, mission, team) survive.
CREATE TABLE conquer_school_reports(
 report_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 report_key uuid NOT NULL UNIQUE,
 owner_player_id bigint NOT NULL REFERENCES conquer_school_players(player_id),
 loop_id bigint NOT NULL CHECK(loop_id BETWEEN 1 AND 8),
 mission_id bigint NOT NULL CHECK(mission_id>0),
 team_id bigint NOT NULL CHECK(team_id BETWEEN 1 AND 5),
 score bigint NOT NULL CHECK(score>=0),
 profile jsonb NOT NULL CHECK(jsonb_typeof(profile)='object'),
 heroes jsonb NOT NULL CHECK(jsonb_typeof(heroes)='array' AND jsonb_array_length(heroes) BETWEEN 1 AND 6),
 pet jsonb NOT NULL CHECK(jsonb_typeof(pet)='object'),
 report jsonb NOT NULL CHECK(jsonb_typeof(report)='object'),
 attempt_id text NOT NULL UNIQUE,
 recorded_at timestamptz NOT NULL
);
CREATE INDEX conquer_school_reports_rank ON conquer_school_reports(loop_id,mission_id,team_id,score DESC,report_id);
-- One row per (report, viewer, 05:00 GMT+8 day): only a first view can reward the owner.
CREATE TABLE conquer_school_report_views(
 report_key uuid NOT NULL REFERENCES conquer_school_reports(report_key) ON DELETE CASCADE,
 viewer_player_id bigint NOT NULL REFERENCES players(player_id),
 day bigint NOT NULL,
 viewed_at timestamptz NOT NULL,
 PRIMARY KEY(report_key,viewer_player_id,day)
);

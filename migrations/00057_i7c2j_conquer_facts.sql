-- +goose Up
-- owner: Content
CREATE TABLE content_conquer_input_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL);
-- owner: ConquerSchool
-- Missing historical provenance is UNKNOWN, never an inferred directory default.
CREATE TABLE player_conquer_facts(player_id bigint PRIMARY KEY REFERENCES players(player_id),state_version bigint NOT NULL CHECK(state_version>0),content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),created_at timestamptz NOT NULL,updated_at timestamptz NOT NULL,CHECK(updated_at>=created_at));

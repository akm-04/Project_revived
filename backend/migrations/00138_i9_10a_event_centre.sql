-- +goose Up
-- owner: EventCentre
CREATE TABLE player_event_centre_roots (player_id bigint PRIMARY KEY REFERENCES players(player_id), state_version bigint NOT NULL CHECK(state_version>0), creation_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id), facts jsonb NOT NULL CHECK(jsonb_typeof(facts)='object'), created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL);

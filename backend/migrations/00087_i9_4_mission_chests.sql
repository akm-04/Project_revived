-- +goose Up
-- owner: Content
CREATE TABLE content_mission_activity_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);

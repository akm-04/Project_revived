-- +goose Up
CREATE TABLE content_public_profile_policies (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);
-- Immutable revisions use existing Content installation/activation transactions.

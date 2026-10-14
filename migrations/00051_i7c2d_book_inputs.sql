-- +goose Up
-- owner: Content
CREATE TABLE content_book_input_catalogs (revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id), payload jsonb NOT NULL);
-- owner: BookSkillProgression
CREATE TABLE player_book_roots (player_id bigint PRIMARY KEY REFERENCES players(player_id), state_version bigint NOT NULL CHECK(state_version>0), creation_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id), facts jsonb NOT NULL CHECK(jsonb_typeof(facts)='object'), created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL);
CREATE TABLE player_book_admissions (player_id bigint NOT NULL REFERENCES player_book_roots(player_id), family text NOT NULL, operation_id uuid NOT NULL, request_fingerprint text NOT NULL, operation_context jsonb NOT NULL, content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id), admission_state text NOT NULL CHECK(admission_state IN('PENDING','COMMITTED','REJECTED')), created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, PRIMARY KEY(player_id,family));

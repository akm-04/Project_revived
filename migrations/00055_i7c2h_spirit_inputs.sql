-- +goose Up
-- owner: Content
CREATE TABLE content_spirit_input_catalogs (revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL);
-- owner: SpiritInstance
CREATE TABLE player_spirit_roots(player_id bigint PRIMARY KEY REFERENCES players(player_id),state_version bigint NOT NULL CHECK(state_version>0),creation_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),facts jsonb NOT NULL CHECK(jsonb_typeof(facts)='object'),created_at timestamptz NOT NULL,updated_at timestamptz NOT NULL);
CREATE TABLE player_spirit_heroes(player_id bigint NOT NULL REFERENCES player_spirit_roots(player_id),partner_id bigint NOT NULL CHECK(partner_id>0),state_version bigint NOT NULL CHECK(state_version>0),facts jsonb NOT NULL CHECK(jsonb_typeof(facts)='object'),created_at timestamptz NOT NULL,updated_at timestamptz NOT NULL,PRIMARY KEY(player_id,partner_id));
CREATE TABLE player_spirit_admissions(player_id bigint NOT NULL REFERENCES player_spirit_roots(player_id),family text NOT NULL,operation_id uuid NOT NULL,request_fingerprint text NOT NULL,operation_context jsonb NOT NULL,content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),admission_state text NOT NULL CHECK(admission_state IN('PENDING','COMMITTED','REJECTED')),created_at timestamptz NOT NULL,updated_at timestamptz NOT NULL,PRIMARY KEY(player_id,family));

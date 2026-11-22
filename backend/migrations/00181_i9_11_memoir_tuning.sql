-- +goose Up
-- owner: Memoir
-- D476 operator overlay (I11 tool): one row; absent or invalid keeps the
-- source catalog. No endpoint in I9-11.
CREATE TABLE memoir_tuning (
 singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
 payload_version smallint NOT NULL DEFAULT 0 CHECK (payload_version >= 0),
 revision bigint NOT NULL DEFAULT 0,
 updated_at timestamptz NOT NULL
);

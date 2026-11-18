-- +goose Up
-- owner: Content
-- One immutable daily-buy input object per content revision; no player state.
CREATE TABLE content_daily_buy_input_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object')
);

-- Operator overlay (D476, I11 tool): one row; absent or invalid keeps the
-- source tunables. No endpoint in I9-11.
CREATE TABLE items_energy_tuning(
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 payload_version smallint NOT NULL DEFAULT 0 CHECK(payload_version >= 0),
 updated_at timestamptz NOT NULL
);

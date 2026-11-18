-- +goose Up
-- owner: Content
-- One immutable daily-buy input object per content revision; no player state.
CREATE TABLE content_daily_buy_input_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object')
);

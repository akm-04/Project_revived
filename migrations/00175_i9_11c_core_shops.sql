-- +goose Up
-- owner: Content
-- One immutable core-shop object per content revision; no player state.
CREATE TABLE content_shop_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object')
);

-- owner: Shop
-- One row per (player, shop type): the frozen stock generation with per-slot
-- purchase state, the manual refresh counter and its game day.
CREATE TABLE shop_players (
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 shop_type smallint NOT NULL CHECK (shop_type > 0),
 generation bigint NOT NULL DEFAULT 0 CHECK (generation >= 0),
 refresh_times integer NOT NULL DEFAULT 0 CHECK (refresh_times >= 0),
 refresh_day bigint NOT NULL DEFAULT 0,
 stock jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(stock) = 'object'),
 payload_version smallint NOT NULL DEFAULT 0 CHECK (payload_version >= 0),
 state_version bigint NOT NULL DEFAULT 1 CHECK (state_version >= 0),
 updated_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, shop_type)
);

-- owner: Shop
-- D476 operator overlay (I11 tool): one row; absent or invalid keeps the
-- source catalog. No endpoint in I9-11.
CREATE TABLE shop_tuning (
 singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
 payload_version smallint NOT NULL DEFAULT 0 CHECK (payload_version >= 0),
 revision bigint NOT NULL DEFAULT 0,
 updated_at timestamptz NOT NULL
);

-- +goose Up
-- owner: content-registry
CREATE TABLE content_player_display_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);
-- owner: player/economy
-- Existing canonical profile columns remain the display/name authority. No
-- backfill guesses catalog identity from accepted historical bootstrap icons.
CREATE TABLE player_display_selections (
 player_id bigint PRIMARY KEY REFERENCES player_profiles(player_id),
 avatar_table_id bigint NOT NULL DEFAULT 0 CHECK(avatar_table_id>=0),
 avatar_category smallint NOT NULL DEFAULT 0 CHECK(avatar_category BETWEEN 0 AND 5),
 title_id bigint NOT NULL DEFAULT 0 CHECK(title_id>=0),
 title_unique_id bigint NOT NULL DEFAULT 0 CHECK(title_unique_id>=0),
 bubble_id bigint NOT NULL DEFAULT 10001 CHECK(bubble_id>0),
 CHECK((avatar_table_id=0)=(avatar_category=0))
);
CREATE TABLE player_cosmetic_entitlements (
 player_id bigint NOT NULL REFERENCES player_profiles(player_id),
 origin_key text NOT NULL CHECK(length(origin_key)>0),
 origin_owner text NOT NULL CHECK(length(origin_owner)>0),
 family text NOT NULL CHECK(family IN ('avatar','frame','title','bubble')),
 catalog_id bigint NOT NULL CHECK(catalog_id>0),
 unique_id bigint NOT NULL DEFAULT 0 CHECK(unique_id>=0),
 starts_at timestamptz,
 end_time bigint NOT NULL DEFAULT 0,
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 state_version bigint NOT NULL CHECK(state_version>0),
 PRIMARY KEY(player_id,origin_key)
);
CREATE INDEX player_cosmetic_family ON player_cosmetic_entitlements(player_id,family,catalog_id,unique_id);
-- Preparatory control journal, separate from the single semantic value Tx.
CREATE TABLE player_display_admissions (
 operation_id uuid PRIMARY KEY,
 player_id bigint NOT NULL REFERENCES player_profiles(player_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 state text NOT NULL CHECK(state IN ('PENDING','COMMITTED','ABORTED'))
);
CREATE UNIQUE INDEX player_display_one_pending ON player_display_admissions(player_id) WHERE state='PENDING';

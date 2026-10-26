-- +goose Up
-- owner: content-registry
CREATE TABLE content_awakening_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);
-- owner: objective-core
CREATE TABLE player_awakening_roots (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 CHECK((payload->>'version')::bigint=state_version)
);
-- owner: character/hero-core
ALTER TABLE player_hero_raw_awakening ADD COLUMN producer_reference text NOT NULL DEFAULT '';
-- owner: campaign
-- NULL preserves an unknown historical date; it does not fabricate a first clear.
ALTER TABLE campaign_nodes ADD COLUMN first_clear_day bigint;
ALTER TABLE campaign_players ADD COLUMN pending_awakening jsonb;

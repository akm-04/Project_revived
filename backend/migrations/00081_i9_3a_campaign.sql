-- +goose Up
-- owner: Content
CREATE TABLE content_campaign_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: Campaign
-- I9_CAMPAIGN_V1 C1. Empty on upgrade: an absent row is the new-player map (node 100001 open, nothing cleared).
-- pending_items are the drops frozen by the open FIGHT of pending_generation (C4, one sticky session as V1); last_result is the
-- settled FIGHT_RESULT body a duplicate 114 of last_generation replays with error_code 30005 (F4e).
CREATE TABLE campaign_players(
 player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
 normal_bonus_id bigint NOT NULL CHECK(normal_bonus_id>=0),
 super_bonus_id bigint NOT NULL CHECK(super_bonus_id>=0),
 pending_generation text NOT NULL,
 pending_items jsonb CHECK(pending_items IS NULL OR jsonb_typeof(pending_items)='array'),
 last_generation text NOT NULL,
 last_result jsonb CHECK(last_result IS NULL OR jsonb_typeof(last_result)='object'),
 state_version bigint NOT NULL CHECK(state_version>0),
 updated_at timestamptz NOT NULL
);
CREATE TABLE campaign_nodes(
 player_id bigint NOT NULL REFERENCES campaign_players(player_id) ON DELETE CASCADE,
 campaign_id bigint NOT NULL CHECK(campaign_id>0),
 star smallint NOT NULL CHECK(star BETWEEN 0 AND 3),
 win_day bigint NOT NULL,
 wins bigint NOT NULL CHECK(wins>=0),
 reset_day bigint NOT NULL,
 resets bigint NOT NULL CHECK(resets>=0),
 partner_drop boolean NOT NULL,
 PRIMARY KEY(player_id,campaign_id)
);

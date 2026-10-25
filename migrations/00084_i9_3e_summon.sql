-- +goose Up
-- owner: Content
CREATE TABLE content_summon_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: Summon
-- I9_GACHA_V1. Empty on upgrade: an absent row is the fresh Vending state (both free pulls ready, 5 Small free pulls, counters 0).
-- Free times are the last free pull (0 = ready, client recoverByTime). Counters are monotonic per family (small, medium_paid,
-- medium_free); a slot whose counter reaches a summon.lua milestone draws that milestone's special pool.
CREATE TABLE summon_players(
 player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
 mana_free_time bigint NOT NULL CHECK(mana_free_time>=0),
 mana_free_num bigint NOT NULL CHECK(mana_free_num>=0),
 mana_free_day bigint NOT NULL,
 crystal_free_time bigint NOT NULL CHECK(crystal_free_time>=0),
 counters jsonb NOT NULL CHECK(jsonb_typeof(counters)='object'),
 featured_target bigint NOT NULL CHECK(featured_target>=0),
 featured_pity bigint NOT NULL CHECK(featured_pity>=0),
 sx_target bigint NOT NULL CHECK(sx_target>=0),
 sx_pity bigint NOT NULL CHECK(sx_pity>=0),
 magic_target bigint NOT NULL CHECK(magic_target>=0),
 state_version bigint NOT NULL CHECK(state_version>0),
 updated_at timestamptz NOT NULL
);
-- Operator overlay (I11 operator tool): one row; absent = I9_GACHA_PRIVATE_POLICY_V1 unchanged. Rejected payloads leave the
-- source policy in force (summon.Tuning validation).
CREATE TABLE summon_tuning(
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 updated_at timestamptz NOT NULL
);

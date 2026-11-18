-- +goose Up
-- owner: Achievement
-- I9_11E C5: qualified (player, achievement, campaign) Fantasy facts. A row is
-- inserted once when a settlement proves the fact; progress is its bounded
-- row count (at most the 12 Fantasy campaigns).
CREATE TABLE achievement_boss_facts(
 player_id bigint NOT NULL REFERENCES players(player_id),
 achievement_id bigint NOT NULL CHECK(achievement_id IN (100006,100007)),
 campaign_id bigint NOT NULL CHECK(campaign_id BETWEEN 100001 AND 100012),
 occurrence_day bigint NOT NULL CHECK(occurrence_day>0),
 created_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,achievement_id,campaign_id)
);
-- I9_11E C8: the daily counter of 100011; earned tiers stay in achievement_streaks.
CREATE TABLE achievement_daily_counts(
 player_id bigint NOT NULL REFERENCES players(player_id),
 achievement_id bigint NOT NULL CHECK(achievement_id=100011),
 day date NOT NULL,
 count bigint NOT NULL CHECK(count>=0),
 PRIMARY KEY(player_id,achievement_id)
);
-- I9_11E C5: the new fact families use their own policy and stay non-periodic.
-- 100011 is admitted here so the later C7 slice shares this migration.
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_profile;
ALTER TABLE achievement_streaks ADD CONSTRAINT achievement_streaks_profile CHECK(
 achievement_id=100001 AND policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1' OR
 achievement_id=100002 AND policy_id='C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1' OR
 achievement_id=100028 AND policy_id='C5C_ONE_ON_ONE_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100003 AND policy_id='C5D_ARENA_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100032 AND policy_id='C5F_LEAGUE_TOP5_DAYS_V2' AND last_day IS NULL OR
 achievement_id IN (100004,100005,100010,100013,100015,100016,100017,100019,100020,100021,100022,100023,100024,100025,100027,100029,100030,100031) AND policy_id='C4F_OWNED_STATE_COUNT_V1' AND last_day IS NULL OR
 achievement_id IN (100006,100007,100011,100012) AND policy_id='I9_11E_ACHIEVEMENT_FACT_V1' AND last_day IS NULL);

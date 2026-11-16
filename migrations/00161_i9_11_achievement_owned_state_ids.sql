-- +goose Up
-- owner: Achievement
-- ACHIEVEMENT_EVENT_FACTS_V1: the eight owner-fact ids join the existing
-- owned-state high-water streak rows (no new table or column).
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_profile;
ALTER TABLE achievement_streaks ADD CONSTRAINT achievement_streaks_profile CHECK(
 achievement_id=100001 AND policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1' OR
 achievement_id=100002 AND policy_id='C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1' OR
 achievement_id=100028 AND policy_id='C5C_ONE_ON_ONE_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100003 AND policy_id='C5D_ARENA_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100032 AND policy_id='C5F_LEAGUE_TOP5_DAYS_V2' AND last_day IS NULL OR
 achievement_id IN (100004,100005,100010,100013,100015,100016,100017,100019,100020,100021,100022,100023,100024,100025,100027,100029,100030,100031) AND policy_id='C4F_OWNED_STATE_COUNT_V1' AND last_day IS NULL);

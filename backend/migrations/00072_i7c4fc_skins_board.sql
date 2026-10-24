-- +goose Up
-- owner: Achievement
-- C4F_SKINS_ACHIEVEMENT_V1: 100016 joins the owned-state counts over the 1003 skin collection.
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_profile;
ALTER TABLE achievement_streaks ADD CONSTRAINT achievement_streaks_profile CHECK(
 achievement_id=100001 AND policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1' OR
 achievement_id=100002 AND policy_id='C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1' OR
 achievement_id=100028 AND policy_id='C5C_ONE_ON_ONE_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100003 AND policy_id='C5D_ARENA_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100032 AND policy_id='C5F_LEAGUE_TOP5_DAYS_V2' AND last_day IS NULL OR
 achievement_id IN (100013,100015,100016,100017,100019,100021,100023,100025,100029,100030) AND policy_id='C4F_OWNED_STATE_COUNT_V1' AND last_day IS NULL);
-- owner: Ranking
-- C4F_PRIVATE_SKINS_SERVER_RANKING_V1 settles titles 100063..100066 beside the Girls and AP titles.
ALTER TABLE ranking_girls_awards DROP CONSTRAINT ranking_girls_awards_title_id_check;
ALTER TABLE ranking_girls_awards ADD CONSTRAINT ranking_girls_awards_title_id_check CHECK(title_id BETWEEN 100059 AND 100066 OR title_id=100001 AND rank=1);

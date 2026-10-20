-- +goose Up
-- owner: Achievement
-- C4F_OWNED_STATE_COUNT_V1: nine high-water owned-state counts share the streak row shape.
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_profile;
ALTER TABLE achievement_streaks ADD CONSTRAINT achievement_streaks_profile CHECK(
 achievement_id=100001 AND policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1' OR
 achievement_id=100002 AND policy_id='C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1' OR
 achievement_id=100028 AND policy_id='C5C_ONE_ON_ONE_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100003 AND policy_id='C5D_ARENA_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100032 AND policy_id='C5F_LEAGUE_TOP5_DAYS_V2' AND last_day IS NULL OR
 achievement_id IN (100013,100015,100017,100019,100021,100023,100025,100029,100030) AND policy_id='C4F_OWNED_STATE_COUNT_V1' AND last_day IS NULL);
-- C4F_POINT_LEVEL_AWARDS_V1: one claim per point level, granted through I5.
CREATE TABLE achievement_award_claims(
 player_id bigint NOT NULL REFERENCES achievement_roots(player_id),
 level_id bigint NOT NULL CHECK(level_id BETWEEN 2 AND 10),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 operation_id uuid NOT NULL,
 total_points bigint NOT NULL CHECK(total_points>=0),
 claimed_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,level_id),
 UNIQUE(operation_id)
);
-- C4F_ACHIEVEMENT_NOTICE_V1: durable best-effort notice intents for newly earned tiers.
CREATE TABLE achievement_notices(
 notice_id bigserial PRIMARY KEY,
 player_id bigint NOT NULL REFERENCES achievement_roots(player_id),
 achievement_id bigint NOT NULL CHECK(achievement_id BETWEEN 100001 AND 100033),
 tier int NOT NULL CHECK(tier BETWEEN 1 AND 3),
 complete_time timestamptz NOT NULL,
 delivered_at timestamptz,
 UNIQUE(player_id,achievement_id,tier)
);
CREATE INDEX achievement_notices_pending ON achievement_notices(player_id) WHERE delivered_at IS NULL;

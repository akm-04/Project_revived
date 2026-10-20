-- +goose Up
-- owner: Content
CREATE TABLE content_league_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: ChampionsLeague
-- C5F_CHAMPIONS_LEAGUE_MODE_V1: global mode serialization rank604.
CREATE TABLE league_competitions(
 competition_id text PRIMARY KEY CHECK(competition_id='GLOBAL'),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object' AND (payload->>'Version')::bigint=state_version)
);
CREATE TABLE league_players(
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 logical_server_id bigint NOT NULL REFERENCES logical_servers(logical_server_id),
 competition_id text NOT NULL DEFAULT 'GLOBAL' REFERENCES league_competitions(competition_id),
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object' AND (payload->>'Version')::bigint=state_version AND (payload->>'ID')::bigint=player_id AND (payload->>'Server')::bigint=logical_server_id)
);
CREATE TABLE league_matches(
 match_id uuid PRIMARY KEY,
 wire_id bigserial UNIQUE NOT NULL CHECK(wire_id>0),
 attacker bigint NOT NULL REFERENCES league_players(player_id),
 defender bigint NOT NULL REFERENCES league_players(player_id) CHECK(defender<>attacker),
 intent bigint NOT NULL CHECK(intent>0),
 attempt_id uuid UNIQUE NOT NULL REFERENCES combat_attempts(attempt_id),
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object' AND (payload->>'Version')::bigint=state_version),
 UNIQUE(attacker,intent)
);
CREATE INDEX league_matches_open ON league_matches((payload->>'Status')) WHERE payload->>'Status'='FIGHTING';
CREATE TABLE league_settlements(
 kind text NOT NULL CHECK(kind IN ('DAY','SEASON','ROLL')),
 number bigint NOT NULL,
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 PRIMARY KEY(kind,number)
);
CREATE TABLE league_cosmetic_origins(
 player_id bigint NOT NULL REFERENCES league_players(player_id),
 origin_key text NOT NULL,
 family text NOT NULL CHECK(family IN ('title','bubble')),
 catalog_id bigint NOT NULL CHECK(catalog_id>0),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 PRIMARY KEY(player_id,origin_key)
);
-- owner: Achievement
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_profile;
ALTER TABLE achievement_streaks ADD CONSTRAINT achievement_streaks_profile CHECK(
 achievement_id=100001 AND policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1' OR
 achievement_id=100002 AND policy_id='C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1' OR
 achievement_id=100028 AND policy_id='C5C_ONE_ON_ONE_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100003 AND policy_id='C5D_ARENA_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100032 AND policy_id='C5F_LEAGUE_TOP5_DAYS_V2' AND last_day IS NULL);
-- +goose Down
DELETE FROM achievement_streaks WHERE achievement_id=100032;
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_profile;
ALTER TABLE achievement_streaks ADD CONSTRAINT achievement_streaks_profile CHECK(
 achievement_id=100001 AND policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1' OR
 achievement_id=100002 AND policy_id='C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1' OR
 achievement_id=100028 AND policy_id='C5C_ONE_ON_ONE_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100003 AND policy_id='C5D_ARENA_WIN_STREAK_V1' AND last_day IS NULL);

DROP TABLE league_cosmetic_origins;
DROP TABLE league_settlements;
DROP TABLE league_matches;
DROP TABLE league_players;
DROP TABLE league_competitions;
DROP TABLE content_league_catalogs;

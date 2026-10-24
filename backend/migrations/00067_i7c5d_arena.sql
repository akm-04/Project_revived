-- +goose Up
-- owner: Content
CREATE TABLE content_arena_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: Arena
-- C5D_ARENA_SEASON_MODE_V1 / C5D_ARENA_PRIVATE_POLICY_V1. One competition over all
-- logical servers (lock rank 603); empty on upgrade, created on the first entry.
CREATE TABLE arena_competitions(
 competition_id text PRIMARY KEY CHECK(competition_id='GLOBAL'),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 policy_id text NOT NULL CHECK(policy_id='C5D_ARENA_PRIVATE_POLICY_V1'),
 settled_through bigint NOT NULL CHECK(settled_through>=0),
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at)
);
-- Season-scoped columns belong to season; a newer season resets them on the next write.
CREATE TABLE arena_players(
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 logical_server_id bigint NOT NULL REFERENCES logical_servers(logical_server_id),
 competition_id text NOT NULL REFERENCES arena_competitions(competition_id),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 season bigint NOT NULL CHECK(season>=0),
 star bigint NOT NULL CHECK(star BETWEEN 0 AND 95),
 point bigint NOT NULL CHECK(point>=0),
 star_at timestamptz NOT NULL,
 total_fight bigint NOT NULL CHECK(total_fight>=0),
 win_times bigint NOT NULL CHECK(win_times BETWEEN 0 AND total_fight),
 keep_win bigint NOT NULL CHECK(keep_win BETWEEN 0 AND win_times),
 defense_wins bigint NOT NULL CHECK(defense_wins BETWEEN 0 AND 2),
 defense_losses bigint NOT NULL CHECK(defense_losses BETWEEN 0 AND 2),
 daily_day bigint NOT NULL,
 daily_fights bigint NOT NULL CHECK(daily_fights>=0),
 defense jsonb NOT NULL CHECK(jsonb_typeof(defense->'heroes')='array' AND jsonb_array_length(defense->'heroes') IN (0,5) AND jsonb_typeof(defense->'pet')='number'),
 opponent bigint REFERENCES players(player_id),
 practice boolean NOT NULL,
 match_counter bigint NOT NULL CHECK(match_counter>=0),
 missions jsonb NOT NULL CHECK(jsonb_typeof(missions)='array' AND jsonb_array_length(missions)<=3),
 mission_time timestamptz NOT NULL,
 mission_draws bigint NOT NULL CHECK(mission_draws>=0),
 exchange_star bigint NOT NULL CHECK(exchange_star>=0),
 exchange_awaken bigint NOT NULL CHECK(exchange_awaken>=0),
 exchange_summon bigint NOT NULL CHECK(exchange_summon>=0),
 awards jsonb NOT NULL CHECK(jsonb_typeof(awards)='array'),
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at),
 CHECK(player_id/100000=logical_server_id),
 CHECK(opponent IS NULL OR opponent<>player_id)
);
CREATE INDEX arena_players_season ON arena_players(season);
CREATE INDEX arena_players_server ON arena_players(logical_server_id);
CREATE TABLE arena_matches(
 match_id uuid PRIMARY KEY,
 attacker_id bigint NOT NULL REFERENCES arena_players(player_id),
 defender_id bigint NOT NULL REFERENCES arena_players(player_id),
 season bigint NOT NULL CHECK(season>0),
 practice boolean NOT NULL,
 defense_heroes jsonb NOT NULL CHECK(jsonb_typeof(defense_heroes)='array' AND jsonb_array_length(defense_heroes) BETWEEN 1 AND 5),
 defense_pet bigint NOT NULL CHECK(defense_pet>=0),
 started_at timestamptz NOT NULL,
 formation jsonb CHECK(formation IS NULL OR jsonb_typeof(formation)='array' AND jsonb_array_length(formation) BETWEEN 1 AND 5),
 attack_pet bigint NOT NULL CHECK(attack_pet>=0),
 attempt_id uuid UNIQUE REFERENCES combat_attempts(attempt_id),
 fingerprint text CHECK(fingerprint IS NULL OR fingerprint ~ '^[0-9a-f]{64}$'),
 status text NOT NULL CHECK(status IN ('STARTED','FIGHTING','SETTLED','CLOSED')),
 outcome jsonb CHECK(outcome IS NULL OR jsonb_typeof(outcome)='object'),
 settled_at timestamptz,
 state_version bigint NOT NULL CHECK(state_version>0),
 CHECK(defender_id<>attacker_id),
 CHECK((status='SETTLED')=(outcome IS NOT NULL)),
 CHECK((status IN ('STARTED','FIGHTING'))=(settled_at IS NULL)),
 CHECK(status<>'FIGHTING' OR attempt_id IS NOT NULL AND formation IS NOT NULL AND fingerprint IS NOT NULL),
 CHECK(status<>'STARTED' OR attempt_id IS NULL)
);
CREATE UNIQUE INDEX arena_matches_one_open ON arena_matches(attacker_id) WHERE status IN ('STARTED','FIGHTING');
CREATE INDEX arena_matches_open ON arena_matches(started_at) WHERE status IN ('STARTED','FIGHTING');
CREATE TABLE arena_records(
 record_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 owner_player_id bigint NOT NULL REFERENCES arena_players(player_id),
 match_id uuid NOT NULL REFERENCES arena_matches(match_id),
 is_attack boolean NOT NULL,
 win boolean NOT NULL,
 recorded_at timestamptz NOT NULL,
 UNIQUE(owner_player_id,match_id)
);
CREATE INDEX arena_records_owner ON arena_records(owner_player_id,record_id DESC);
CREATE TABLE arena_partner_usage(
 player_id bigint NOT NULL REFERENCES arena_players(player_id),
 season bigint NOT NULL CHECK(season>0),
 table_id bigint NOT NULL CHECK(table_id>0),
 fights bigint NOT NULL CHECK(fights>0),
 wins bigint NOT NULL CHECK(wins BETWEEN 0 AND fights),
 kill_count bigint NOT NULL CHECK(kill_count>=0),
 harms numeric NOT NULL CHECK(harms>=0),
 PRIMARY KEY(player_id,season,table_id)
);
CREATE TABLE arena_settlements(
 season bigint PRIMARY KEY CHECK(season>0),
 cutoff_at timestamptz NOT NULL,
 settled_at timestamptz NOT NULL CHECK(settled_at>=cutoff_at),
 competition_version bigint NOT NULL CHECK(competition_version>0),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 recipients bigint NOT NULL CHECK(recipients>=0)
);
CREATE TABLE arena_settlement_ranks(
 season bigint NOT NULL REFERENCES arena_settlements(season),
 player_id bigint NOT NULL REFERENCES players(player_id),
 season_rank bigint NOT NULL CHECK(season_rank>=1),
 level bigint NOT NULL CHECK(level BETWEEN 1 AND 26),
 star bigint NOT NULL CHECK(star BETWEEN 0 AND 95),
 point bigint NOT NULL CHECK(point>=0),
 champion boolean NOT NULL,
 mail_uuid uuid,
 PRIMARY KEY(season,player_id),
 UNIQUE(season,season_rank)
);
-- owner: Achievement
-- Scoped I7C-5D amendment: Arena Skilled Master (100003) attack win streak.
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_profile;
ALTER TABLE achievement_streaks ADD CONSTRAINT achievement_streaks_profile CHECK(
 achievement_id=100001 AND policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1' OR
 achievement_id=100002 AND policy_id='C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1' OR
 achievement_id=100028 AND policy_id='C5C_ONE_ON_ONE_WIN_STREAK_V1' AND last_day IS NULL OR
 achievement_id=100003 AND policy_id='C5D_ARENA_WIN_STREAK_V1' AND last_day IS NULL);

-- +goose Up
-- owner: Content
CREATE TABLE content_one_on_one_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: OneOnOne
-- C5C_ONE_ON_ONE_MODE_V1 / C5C_ONE_ON_ONE_PRIVATE_POLICY_V1. One competition over
-- all logical servers; empty on upgrade, created on the first entry; no legacy backfill.
CREATE TABLE one_on_one_competitions(
 competition_id text PRIMARY KEY CHECK(competition_id='GLOBAL'),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 policy_id text NOT NULL CHECK(policy_id='C5C_ONE_ON_ONE_PRIVATE_POLICY_V1'),
 master_count bigint NOT NULL CHECK(master_count BETWEEN 0 AND 500),
 senior_count bigint NOT NULL CHECK(senior_count BETWEEN 0 AND 4500),
 settled_through bigint NOT NULL,
 opened_through bigint NOT NULL,
 closed_through bigint NOT NULL CHECK(closed_through<=opened_through),
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at)
);
CREATE TABLE one_on_one_players(
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 logical_server_id bigint NOT NULL REFERENCES logical_servers(logical_server_id),
 competition_id text NOT NULL REFERENCES one_on_one_competitions(competition_id),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 level bigint NOT NULL CHECK(level BETWEEN 1 AND 5),
 -- Juniors hold no slot (NULL), so the deferrable slot uniqueness spans Master/Senior only.
 slot bigint CHECK(slot BETWEEN 1 AND 5000),
 points bigint NOT NULL CHECK(points>=0),
 points_at timestamptz NOT NULL,
 tries_day bigint NOT NULL,
 tries_left bigint NOT NULL CHECK(tries_left>=0),
 purchases bigint NOT NULL CHECK(purchases>=0),
 last_fight_at timestamptz,
 teams jsonb NOT NULL CHECK(jsonb_typeof(teams)='array' AND jsonb_array_length(teams)<=7),
 offered_day bigint NOT NULL,
 refreshes bigint NOT NULL CHECK(refreshes>=0),
 offered jsonb NOT NULL CHECK(jsonb_typeof(offered)='array' AND jsonb_array_length(offered)<=3),
 mode bigint NOT NULL CHECK(mode IN (1,2)),
 promotion_week bigint NOT NULL,
 candidates jsonb NOT NULL CHECK(jsonb_typeof(candidates)='array' AND jsonb_array_length(candidates)<=3),
 opponent bigint REFERENCES players(player_id),
 challenges bigint NOT NULL CHECK(challenges>=0),
 promotion_wins bigint NOT NULL CHECK(promotion_wins BETWEEN 0 AND challenges),
 last_promotion_at timestamptz,
 win_streak bigint NOT NULL CHECK(win_streak>=0),
 fights bigint NOT NULL CHECK(fights>=0),
 wins bigint NOT NULL CHECK(wins BETWEEN 0 AND fights),
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at),
 CHECK(player_id/100000=logical_server_id),
 CHECK((level<=2)=(slot IS NOT NULL)),
 CHECK(level<>1 OR slot<=500),
 CHECK(level<>2 OR slot>500),
 CHECK((mode=2)=(jsonb_array_length(candidates)>0)),
 CONSTRAINT one_on_one_players_slot_once UNIQUE(competition_id,slot) DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX one_on_one_players_server ON one_on_one_players(logical_server_id);
CREATE TABLE one_on_one_matches(
 match_id uuid PRIMARY KEY,
 attacker_id bigint NOT NULL REFERENCES one_on_one_players(player_id),
 defender_id bigint NOT NULL REFERENCES one_on_one_players(player_id),
 mode bigint NOT NULL CHECK(mode IN (1,2)),
 start_fingerprint text NOT NULL CHECK(start_fingerprint ~ '^[0-9a-f]{64}$'),
 attack_teams jsonb NOT NULL CHECK(jsonb_typeof(attack_teams)='array' AND jsonb_array_length(attack_teams) BETWEEN 1 AND 7),
 defense_teams jsonb NOT NULL CHECK(jsonb_typeof(defense_teams)='array' AND jsonb_array_length(defense_teams)<=7),
 started_at timestamptz NOT NULL,
 status text NOT NULL CHECK(status IN ('STARTED','SETTLED','CLOSED')),
 outcome jsonb CHECK(outcome IS NULL OR jsonb_typeof(outcome)='object'),
 settled_at timestamptz,
 state_version bigint NOT NULL CHECK(state_version>0),
 CHECK(defender_id<>attacker_id),
 CHECK((status='SETTLED')=(outcome IS NOT NULL)),
 CHECK((status='STARTED')=(settled_at IS NULL))
);
CREATE UNIQUE INDEX one_on_one_matches_one_started ON one_on_one_matches(attacker_id) WHERE status='STARTED';
CREATE INDEX one_on_one_matches_open ON one_on_one_matches(started_at) WHERE status='STARTED';
CREATE INDEX one_on_one_matches_attacker ON one_on_one_matches(attacker_id,started_at DESC);
-- A round without an attempt is forfeited by a defender who lacks that team.
CREATE TABLE one_on_one_rounds(
 match_id uuid NOT NULL REFERENCES one_on_one_matches(match_id),
 round bigint NOT NULL CHECK(round BETWEEN 1 AND 7),
 attempt_id uuid UNIQUE REFERENCES combat_attempts(attempt_id),
 PRIMARY KEY(match_id,round)
);
CREATE TABLE one_on_one_records(
 record_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 owner_player_id bigint NOT NULL REFERENCES one_on_one_players(player_id),
 match_id uuid NOT NULL REFERENCES one_on_one_matches(match_id),
 is_attack boolean NOT NULL,
 win boolean NOT NULL,
 mode bigint NOT NULL CHECK(mode IN (1,2)),
 recorded_at timestamptz NOT NULL,
 UNIQUE(owner_player_id,match_id)
);
CREATE INDEX one_on_one_records_owner ON one_on_one_records(owner_player_id,record_id DESC);
CREATE TABLE one_on_one_partner_usage(
 player_id bigint NOT NULL REFERENCES one_on_one_players(player_id),
 partner_id bigint NOT NULL CHECK(partner_id>0),
 fights bigint NOT NULL CHECK(fights>0),
 wins bigint NOT NULL CHECK(wins BETWEEN 0 AND fights),
 kill_count bigint NOT NULL CHECK(kill_count>=0),
 harms numeric NOT NULL CHECK(harms>=0),
 PRIMARY KEY(player_id,partner_id)
);
CREATE TABLE one_on_one_settlements(
 day bigint PRIMARY KEY,
 cutoff_at timestamptz NOT NULL,
 settled_at timestamptz NOT NULL CHECK(settled_at>=cutoff_at),
 competition_version bigint NOT NULL CHECK(competition_version>0),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 recipients bigint NOT NULL CHECK(recipients>=0)
);
CREATE TABLE one_on_one_settlement_ranks(
 day bigint NOT NULL REFERENCES one_on_one_settlements(day),
 player_id bigint NOT NULL REFERENCES players(player_id),
 global_rank bigint NOT NULL CHECK(global_rank>=1),
 server_rank bigint NOT NULL CHECK(server_rank>=1),
 mail_uuid uuid,
 title_id bigint CHECK(title_id BETWEEN 100002 AND 100005),
 title_starts_at timestamptz,
 title_end bigint,
 PRIMARY KEY(day,player_id),
 UNIQUE(day,global_rank),
 CHECK((title_id IS NULL)=(title_end IS NULL) AND (title_id IS NULL)=(title_starts_at IS NULL))
);
CREATE INDEX one_on_one_settlement_titles ON one_on_one_settlement_ranks(player_id,title_id) WHERE title_id IS NOT NULL;
-- owner: Achievement
-- Scoped I7C-5C amendment: 1 on 1 Dominator (100002) and Smash 'em all (100028) streaks.
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_pkey;
ALTER TABLE achievement_streaks ADD PRIMARY KEY(player_id,achievement_id);
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_achievement_id_check;
ALTER TABLE achievement_streaks DROP CONSTRAINT achievement_streaks_policy_id_check;
ALTER TABLE achievement_streaks ADD CONSTRAINT achievement_streaks_profile CHECK(
 achievement_id=100001 AND policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1' OR
 achievement_id=100002 AND policy_id='C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1' OR
 achievement_id=100028 AND policy_id='C5C_ONE_ON_ONE_WIN_STREAK_V1' AND last_day IS NULL);

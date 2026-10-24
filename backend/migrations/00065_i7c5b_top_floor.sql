-- +goose Up
-- owner: Content
CREATE TABLE content_top_floor_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: TopFloor
-- C5B_TOP_FLOOR_MODE_V1 / C5B_TOP_FLOOR_PRIVATE_POLICY_V1. Empty on upgrade:
-- a ladder is seeded on its server's first entry; no legacy history backfill.
CREATE TABLE top_floor_ladders(
 logical_server_id bigint PRIMARY KEY REFERENCES logical_servers(logical_server_id),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 policy_id text NOT NULL CHECK(policy_id='C5B_TOP_FLOOR_PRIVATE_POLICY_V1'),
 size bigint NOT NULL CHECK(size>=10325),
 settled_day bigint NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at)
);
CREATE TABLE top_floor_ranks(
 logical_server_id bigint NOT NULL REFERENCES top_floor_ladders(logical_server_id),
 rank bigint NOT NULL CHECK(rank>=1),
 robot_team bigint CHECK(robot_team BETWEEN 1 AND 10325),
 player_id bigint REFERENCES players(player_id),
 PRIMARY KEY(logical_server_id,rank),
 CHECK((robot_team IS NULL)<>(player_id IS NULL)),
 CONSTRAINT top_floor_ranks_robot_once UNIQUE(logical_server_id,robot_team) DEFERRABLE INITIALLY DEFERRED,
 CONSTRAINT top_floor_ranks_player_once UNIQUE(player_id) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE top_floor_players(
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 logical_server_id bigint NOT NULL REFERENCES top_floor_ladders(logical_server_id),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 best_rank bigint NOT NULL CHECK(best_rank>=1),
 ticket_day bigint NOT NULL,
 tickets_left bigint NOT NULL CHECK(tickets_left>=0),
 purchases bigint NOT NULL CHECK(purchases>=0),
 last_match_at timestamptz,
 refresh_count bigint NOT NULL CHECK(refresh_count>=0),
 offered_day bigint NOT NULL,
 offered jsonb NOT NULL CHECK(jsonb_typeof(offered)='array' AND jsonb_array_length(offered)<=3),
 defense jsonb NOT NULL CHECK(jsonb_typeof(defense)='array' AND jsonb_array_length(defense)<=5),
 defense_pet bigint NOT NULL CHECK(defense_pet>=0),
 defense_set_at timestamptz,
 fights bigint NOT NULL CHECK(fights>=0),
 wins bigint NOT NULL CHECK(wins BETWEEN 0 AND fights),
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at),
 CHECK(player_id/100000=logical_server_id)
);
CREATE TABLE top_floor_fights(
 attempt_id uuid PRIMARY KEY REFERENCES combat_attempts(attempt_id),
 logical_server_id bigint NOT NULL REFERENCES top_floor_ladders(logical_server_id),
 challenger_id bigint NOT NULL REFERENCES top_floor_players(player_id),
 defender_robot bigint CHECK(defender_robot BETWEEN 1 AND 10325),
 defender_player bigint REFERENCES top_floor_players(player_id),
 is_avenge boolean NOT NULL,
 start_fingerprint text NOT NULL CHECK(start_fingerprint ~ '^[0-9a-f]{64}$'),
 formation jsonb NOT NULL CHECK(jsonb_typeof(formation)='array' AND jsonb_array_length(formation) BETWEEN 1 AND 5),
 pet_id bigint NOT NULL CHECK(pet_id>=0),
 challenger_rank bigint NOT NULL CHECK(challenger_rank>=1),
 defender_rank bigint NOT NULL CHECK(defender_rank>=1),
 started_at timestamptz NOT NULL,
 status text NOT NULL CHECK(status IN ('STARTED','SETTLED','CLOSED')),
 outcome jsonb CHECK(outcome IS NULL OR jsonb_typeof(outcome)='object'),
 settled_at timestamptz,
 state_version bigint NOT NULL CHECK(state_version>0),
 CHECK((defender_robot IS NULL)<>(defender_player IS NULL)),
 CHECK(defender_player IS NULL OR defender_player<>challenger_id),
 CHECK((status='SETTLED')=(outcome IS NOT NULL)),
 CHECK((status='STARTED')=(settled_at IS NULL))
);
CREATE UNIQUE INDEX top_floor_fights_one_started ON top_floor_fights(challenger_id) WHERE status='STARTED';
CREATE INDEX top_floor_fights_open ON top_floor_fights(logical_server_id,started_at) WHERE status='STARTED';
CREATE TABLE top_floor_records(
 record_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 owner_player_id bigint NOT NULL REFERENCES top_floor_players(player_id),
 attempt_id uuid NOT NULL REFERENCES top_floor_fights(attempt_id),
 is_attack boolean NOT NULL,
 win boolean NOT NULL,
 opponent_robot bigint CHECK(opponent_robot BETWEEN 1 AND 10325),
 opponent_player bigint REFERENCES players(player_id),
 recorded_at timestamptz NOT NULL,
 CHECK((opponent_robot IS NULL)<>(opponent_player IS NULL)),
 UNIQUE(owner_player_id,attempt_id)
);
CREATE INDEX top_floor_records_owner ON top_floor_records(owner_player_id,record_id DESC);
CREATE TABLE top_floor_partner_usage(
 player_id bigint NOT NULL REFERENCES top_floor_players(player_id),
 partner_id bigint NOT NULL CHECK(partner_id>0),
 fights bigint NOT NULL CHECK(fights>0),
 wins bigint NOT NULL CHECK(wins BETWEEN 0 AND fights),
 kill_count bigint NOT NULL CHECK(kill_count>=0),
 harms numeric NOT NULL CHECK(harms>=0),
 PRIMARY KEY(player_id,partner_id)
);
CREATE TABLE top_floor_day_settlements(
 logical_server_id bigint NOT NULL REFERENCES top_floor_ladders(logical_server_id),
 day bigint NOT NULL,
 cutoff_at timestamptz NOT NULL,
 settled_at timestamptz NOT NULL CHECK(settled_at>=cutoff_at),
 ladder_version bigint NOT NULL CHECK(ladder_version>0),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 recipients bigint NOT NULL CHECK(recipients>=0),
 PRIMARY KEY(logical_server_id,day)
);
CREATE TABLE top_floor_day_ranks(
 logical_server_id bigint NOT NULL,
 day bigint NOT NULL,
 player_id bigint NOT NULL REFERENCES players(player_id),
 rank bigint NOT NULL CHECK(rank>=1),
 mail_uuid uuid,
 PRIMARY KEY(logical_server_id,day,player_id),
 UNIQUE(logical_server_id,day,rank),
 FOREIGN KEY(logical_server_id,day) REFERENCES top_floor_day_settlements(logical_server_id,day)
);
-- owner: Achievement
-- Scoped I7C-4B amendment: the Top Floor Challenger (100001) streak producer.
CREATE TABLE achievement_streaks(
 player_id bigint PRIMARY KEY REFERENCES achievement_roots(player_id),
 achievement_id bigint NOT NULL CHECK(achievement_id=100001),
 policy_id text NOT NULL CHECK(policy_id='C5B_TOP_FLOOR_CHALLENGER_STREAK_V1'),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 current bigint NOT NULL CHECK(current>=0),
 last_day bigint,
 complete_times jsonb NOT NULL CHECK(jsonb_typeof(complete_times)='array' AND jsonb_array_length(complete_times)=3),
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at)
);

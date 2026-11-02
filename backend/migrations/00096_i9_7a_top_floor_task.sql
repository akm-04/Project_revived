-- +goose Up
-- owner: TopFloor
CREATE INDEX top_floor_fights_challenger_started ON top_floor_fights(challenger_id,started_at);
CREATE TABLE top_floor_task_periods (
 logical_server_id bigint NOT NULL REFERENCES top_floor_ladders(logical_server_id),
 period_number bigint NOT NULL CHECK(period_number>0),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 mode bigint NOT NULL CHECK(mode BETWEEN 1 AND 6),
 submode bigint NOT NULL CHECK(submode IN (0,1,2,3,10)),
 starts_at timestamptz NOT NULL,
 ends_at timestamptz NOT NULL CHECK(ends_at-starts_at=interval '168 hours'),
 size bigint NOT NULL CHECK(size>=10325),
 settled_day bigint NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL CHECK(created_at>=starts_at AND created_at<ends_at),
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at),
 PRIMARY KEY(logical_server_id,period_number),
 CHECK(mode=6 OR submode=0)
);
CREATE TABLE top_floor_task_ranks (
 logical_server_id bigint NOT NULL,
 period_number bigint NOT NULL,
 rank bigint NOT NULL CHECK(rank>0),
 robot_team bigint CHECK(robot_team BETWEEN 1 AND 10325),
 player_id bigint REFERENCES players(player_id),
 PRIMARY KEY(logical_server_id,period_number,rank),
 FOREIGN KEY(logical_server_id,period_number) REFERENCES top_floor_task_periods(logical_server_id,period_number),
 CHECK((robot_team IS NULL)<>(player_id IS NULL)),
 CHECK(player_id IS NULL OR player_id/100000=logical_server_id),
 UNIQUE(logical_server_id,period_number,robot_team) DEFERRABLE INITIALLY DEFERRED,
 UNIQUE(logical_server_id,period_number,player_id) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE top_floor_task_players (
 player_id bigint NOT NULL REFERENCES players(player_id),
 logical_server_id bigint NOT NULL,
 period_number bigint NOT NULL,
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 state_version bigint NOT NULL CHECK(state_version>0),
 PRIMARY KEY(player_id,period_number),
 FOREIGN KEY(logical_server_id,period_number) REFERENCES top_floor_task_periods(logical_server_id,period_number),
 CHECK(player_id/100000=logical_server_id),
 CHECK((payload->'player'->>'PlayerID')::bigint=player_id),
 CHECK((payload->'player'->>'Server')::bigint=logical_server_id),
 CHECK((payload->>'period_number')::bigint=period_number),
 CHECK((payload->'player'->>'StateVersion')::bigint=state_version)
);
CREATE TABLE top_floor_task_preferences (
 player_id bigint NOT NULL REFERENCES players(player_id),
 mode bigint NOT NULL CHECK(mode BETWEEN 1 AND 6),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 PRIMARY KEY(player_id,mode)
);
CREATE TABLE top_floor_task_fights (
 attempt_id uuid PRIMARY KEY REFERENCES combat_attempts(attempt_id),
 challenger_id bigint NOT NULL REFERENCES players(player_id),
 logical_server_id bigint NOT NULL,
 period_number bigint NOT NULL,
 started_at timestamptz NOT NULL,
 status text NOT NULL CHECK(status IN ('STARTED','SETTLED','CLOSED')),
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 FOREIGN KEY(logical_server_id,period_number) REFERENCES top_floor_task_periods(logical_server_id,period_number)
);
CREATE UNIQUE INDEX top_floor_task_one_started ON top_floor_task_fights(challenger_id) WHERE status='STARTED';
CREATE INDEX top_floor_task_latest ON top_floor_task_fights(challenger_id,started_at DESC);
CREATE TABLE top_floor_task_records (
 record_id bigint PRIMARY KEY DEFAULT nextval('top_floor_records_record_id_seq'),
 owner_player_id bigint NOT NULL REFERENCES players(player_id),
 attempt_id uuid NOT NULL REFERENCES top_floor_task_fights(attempt_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 UNIQUE(owner_player_id,attempt_id)
);
CREATE INDEX top_floor_task_records_owner ON top_floor_task_records(owner_player_id,record_id DESC);
CREATE TABLE top_floor_task_days (
 logical_server_id bigint NOT NULL,
 period_number bigint NOT NULL,
 day bigint NOT NULL,
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 PRIMARY KEY(logical_server_id,period_number,day),
 FOREIGN KEY(logical_server_id,period_number) REFERENCES top_floor_task_periods(logical_server_id,period_number)
);

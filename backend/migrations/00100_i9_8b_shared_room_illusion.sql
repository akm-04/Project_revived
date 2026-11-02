-- +goose Up
-- owner: sharedroom
-- lock rank 607 (D365): a command locks the room row before reading or writing
-- its seats; the room and its seats are one logical owner row.
CREATE TABLE shared_rooms (
 room_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 family text NOT NULL CHECK(family<>'' AND length(family)<=64),
 slot bigint NOT NULL CHECK(slot>=0),
 owner_player bigint NOT NULL REFERENCES players(player_id),
 status text NOT NULL CHECK(status IN ('OPEN','CLOSED')),
 capacity integer NOT NULL CHECK(capacity BETWEEN 1 AND 8),
 expires_at timestamptz NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 notice_version bigint NOT NULL CHECK(notice_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 closed_at timestamptz,
 UNIQUE(room_id,family,slot),
 CHECK((status='CLOSED')=(closed_at IS NOT NULL)),
 CHECK(expires_at>created_at)
);
CREATE INDEX shared_room_rooms_due ON shared_rooms(expires_at,room_id) WHERE status='OPEN';
CREATE TABLE shared_room_seats (
 room_id bigint NOT NULL,
 seat_index integer NOT NULL CHECK(seat_index BETWEEN 0 AND 7),
 player_id bigint NOT NULL REFERENCES players(player_id),
 family text NOT NULL,
 slot bigint NOT NULL,
 stage text NOT NULL CHECK(stage IN ('SEATED','LEFT','KICKED')),
 ready boolean NOT NULL,
 joined_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(room_id,player_id),
 FOREIGN KEY(room_id,family,slot) REFERENCES shared_rooms(room_id,family,slot),
 CHECK(stage='SEATED' OR NOT ready)
);
CREATE UNIQUE INDEX shared_room_seats_active_player ON shared_room_seats(player_id,family,slot) WHERE stage='SEATED';
CREATE UNIQUE INDEX shared_room_seats_active_index ON shared_room_seats(room_id,seat_index) WHERE stage='SEATED';

-- owner: content-registry
CREATE TABLE content_illusion_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);

-- owner: illusion
-- lock rank 606: the one occurrence row of a logical server. A command locks
-- the player row at rank 605 first, then this occurrence, then shared_rooms 607.
CREATE TABLE illusion_occurrences (
 logical_server_id integer PRIMARY KEY REFERENCES logical_servers(logical_server_id),
 campaign_id bigint NOT NULL CHECK(campaign_id BETWEEN 100001 AND 100012),
 pool_hp bigint NOT NULL CHECK(pool_hp>0),
 pool_hurt bigint NOT NULL CHECK(pool_hurt>=0 AND pool_hurt<=pool_hp),
 open_day bigint NOT NULL CHECK(open_day>=0),
 settled_open_day bigint NOT NULL CHECK(settled_open_day>=0),
 updated_at timestamptz NOT NULL
);
-- lock rank 605: per-player chances and daily best hit.
CREATE TABLE illusion_players (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 day bigint NOT NULL CHECK(day>=0),
 chances bigint NOT NULL CHECK(chances>=0),
 bought bigint NOT NULL CHECK(bought>=0),
 best_hit bigint NOT NULL CHECK(best_hit>=0),
 best_time bigint NOT NULL CHECK(best_time>=0),
 updated_at timestamptz NOT NULL
);
CREATE TABLE illusion_occurrence_results (
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 open_day bigint NOT NULL CHECK(open_day>=0),
 campaign_id bigint NOT NULL CHECK(campaign_id BETWEEN 100001 AND 100012),
 player_id bigint NOT NULL REFERENCES players(player_id),
 hurt bigint NOT NULL CHECK(hurt>=0),
 cost_time bigint NOT NULL CHECK(cost_time>=0),
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(logical_server_id,open_day,player_id)
);
CREATE INDEX illusion_occurrence_results_rank_idx ON illusion_occurrence_results(logical_server_id,open_day,hurt DESC,cost_time,player_id);
CREATE TABLE illusion_attempts (
 attempt_id text PRIMARY KEY,
 attempt_sequence bigint GENERATED ALWAYS AS IDENTITY,
 player_id bigint NOT NULL REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 open_day bigint NOT NULL CHECK(open_day>=0),
 campaign_id bigint NOT NULL CHECK(campaign_id BETWEEN 100001 AND 100012),
 room_id bigint,
 formation text NOT NULL,
 frozen_at bigint NOT NULL,
 resolved boolean NOT NULL,
 damage bigint NOT NULL CHECK(damage>=0)
);
CREATE UNIQUE INDEX illusion_attempts_open_idx ON illusion_attempts(player_id) WHERE NOT resolved;
CREATE INDEX illusion_attempts_player_idx ON illusion_attempts(player_id,logical_server_id,open_day,campaign_id,attempt_sequence DESC);
CREATE TABLE illusion_reports (
 report_id text PRIMARY KEY,
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 open_day bigint NOT NULL CHECK(open_day>=0),
 campaign_id bigint NOT NULL CHECK(campaign_id BETWEEN 100001 AND 100012),
 content jsonb NOT NULL,
 created_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL,
 CHECK(expires_at=created_at+interval '7 days')
);
CREATE INDEX illusion_reports_expiry_idx ON illusion_reports(expires_at,report_id);
CREATE TABLE illusion_settlements (
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 open_day bigint NOT NULL CHECK(open_day>=0),
 player_id bigint NOT NULL REFERENCES players(player_id),
 settled_at timestamptz NOT NULL,
 PRIMARY KEY(logical_server_id,open_day,player_id)
);

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

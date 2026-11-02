-- +goose Up
-- owner: Arena
CREATE TABLE arena_tournament_periods (
 season bigint PRIMARY KEY REFERENCES arena_settlements(season),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 state_version bigint NOT NULL CHECK(state_version>0),
 CHECK((payload->>'season')::bigint=season),
 CHECK(payload->>'content_revision'=content_revision),
 CHECK((payload->>'state_version')::bigint=state_version)
);
CREATE TABLE arena_tournament_rooms (
 room_id uuid PRIMARY KEY,
 season bigint REFERENCES arena_tournament_periods(season),
 casual_week_day bigint,
 first_player bigint NOT NULL REFERENCES players(player_id),
 second_player bigint NOT NULL REFERENCES players(player_id),
 status text NOT NULL CHECK(status IN ('PREPARING','SELECTING','FIGHTING','SETTLED')),
 starts_at timestamptz NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 CHECK(first_player<>second_player),
 CHECK((season IS NULL)<>(casual_week_day IS NULL)),
 CHECK((payload->>'identifier')::uuid=room_id),
 CHECK((payload->>'state_version')::bigint=state_version),
 CHECK(payload->>'status'=status),
 CHECK((payload->'selection'->'players'->>0)::bigint=first_player),
 CHECK((payload->'selection'->'players'->>1)::bigint=second_player)
);
CREATE INDEX arena_tournament_rooms_due ON arena_tournament_rooms(starts_at,room_id) WHERE status<>'SETTLED';
CREATE INDEX arena_tournament_rooms_first ON arena_tournament_rooms(first_player,starts_at DESC);
CREATE INDEX arena_tournament_rooms_second ON arena_tournament_rooms(second_player,starts_at DESC);
CREATE TABLE arena_casual_sessions (
 week_day bigint PRIMARY KEY,
 closes_at timestamptz NOT NULL,
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 settled boolean NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 CHECK((payload->'period'->>'WeekDay')::bigint=week_day),
 CHECK((payload->>'state_version')::bigint=state_version),
 CHECK((payload->>'settled')::boolean=settled),
 CHECK(payload->>'content_revision'=content_revision)
);
CREATE TABLE arena_casual_entries (
 entry_id uuid PRIMARY KEY,
 player_id bigint NOT NULL REFERENCES players(player_id),
 week_day bigint NOT NULL REFERENCES arena_casual_sessions(week_day),
 status text NOT NULL CHECK(status IN ('WAITING','MATCHED','CANCELLED','EXPIRED','FINISHED')),
 room_id uuid REFERENCES arena_tournament_rooms(room_id),
 admitted_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL CHECK(expires_at=admitted_at+interval '60 seconds'),
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 CHECK((payload->>'identifier')::uuid=entry_id),
 CHECK((payload->'actor'->>'PlayerID')::bigint=player_id),
 CHECK((payload->>'week_day')::bigint=week_day),
 CHECK((payload->>'state_version')::bigint=state_version),
 CHECK(payload->>'status'=status),
 CHECK((status IN ('MATCHED','FINISHED'))=(room_id IS NOT NULL))
);
CREATE UNIQUE INDEX arena_casual_one_active ON arena_casual_entries(player_id) WHERE status IN ('WAITING','MATCHED');
CREATE INDEX arena_casual_waiting ON arena_casual_entries(week_day,admitted_at,entry_id) WHERE status='WAITING';
CREATE TABLE arena_casual_scores (
 week_day bigint NOT NULL REFERENCES arena_casual_sessions(week_day),
 player_id bigint NOT NULL REFERENCES players(player_id),
 points bigint NOT NULL CHECK(points>=0),
 points_at timestamptz NOT NULL,
 battles bigint NOT NULL CHECK(battles>0),
 PRIMARY KEY(week_day,player_id),
 CHECK(points<=battles)
);

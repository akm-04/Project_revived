-- +goose Up
-- DormHouse owns rooms, membership, retained equipment and Lounge time inputs.
-- No foreign Hero/Player/economy SQL or implicit backfill in this migration.
CREATE TABLE player_dorm_roots (
 player_id bigint PRIMARY KEY CHECK(player_id>0),
 next_house_id bigint NOT NULL CHECK(next_house_id BETWEEN 2 AND 9007199254740991),
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL
);
CREATE TABLE player_dorm_rooms (
 player_id bigint NOT NULL REFERENCES player_dorm_roots(player_id),
 house_id bigint NOT NULL CHECK(house_id BETWEEN 1 AND 9007199254740991),
 table_id bigint NOT NULL CHECK(table_id>0),
 house_type bigint NOT NULL CHECK(house_type BETWEEN 1 AND 4),
 creation_revision text NOT NULL CHECK(length(creation_revision)=64),
 floor bigint NOT NULL CHECK(floor>0),
 position bigint NOT NULL CHECK(position BETWEEN 1 AND 6),
 comfort bigint NOT NULL CHECK(comfort>=0),
 expansion_level bigint NOT NULL CHECK(expansion_level>=0),
 state_version bigint NOT NULL CHECK(state_version>0),
 furniture_record jsonb NOT NULL CHECK(jsonb_typeof(furniture_record)='object'),
 pending_expansion jsonb CHECK(pending_expansion IS NULL OR jsonb_typeof(pending_expansion)='object'),
 last_enter_at timestamptz,
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,house_id),
 UNIQUE(player_id,house_type,floor,position)
);
CREATE TABLE player_dorm_heroes (
 player_id bigint NOT NULL REFERENCES player_dorm_roots(player_id),
 partner_id bigint NOT NULL CHECK(partner_id>0),
 house_id bigint,
 state_version bigint NOT NULL CHECK(state_version>0),
 equipment jsonb NOT NULL CHECK(jsonb_typeof(equipment)='array' AND jsonb_array_length(equipment)=5),
 lounge_anchor timestamptz,
 lounge_fraction bigint NOT NULL CHECK(lounge_fraction BETWEEN 0 AND 3599999999999),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,partner_id),
 FOREIGN KEY(player_id,house_id) REFERENCES player_dorm_rooms(player_id,house_id)
);
CREATE TABLE player_dorm_admissions (
 player_id bigint NOT NULL CHECK(player_id>0),
 family text NOT NULL CHECK(family IN ('DORM_OPEN','DORM_SAVE','DORM_EQUIP','DORM_ENTER','DORM_EXCHANGE','DORM_START','DORM_FINISH')),
 operation_id uuid NOT NULL UNIQUE,
 request_fingerprint text NOT NULL CHECK(length(request_fingerprint)=64),
 operation_context jsonb NOT NULL CHECK(jsonb_typeof(operation_context)='object'),
 content_revision text NOT NULL CHECK(length(content_revision)=64),
 admission_state text NOT NULL CHECK(admission_state IN ('PENDING','COMMITTED','REJECTED')),
 result jsonb,
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,family)
);
CREATE TABLE content_dorm_input_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);

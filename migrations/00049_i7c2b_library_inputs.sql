-- +goose Up
-- LibraryLocalProgression owns relationship/feed/collection inputs. No cross-owner backfill SQL.
CREATE TABLE player_library_roots (
 player_id bigint PRIMARY KEY CHECK (player_id > 0),
 state_version bigint NOT NULL CHECK (state_version > 0),
 special_claims jsonb NOT NULL CHECK (jsonb_typeof(special_claims)='array' AND jsonb_array_length(special_claims)=23),
 seed_policy_id text NOT NULL CHECK (seed_policy_id='LIBRARY_NEUTRAL_SEED_V1'),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL
);
CREATE TABLE player_library_heroes (
 player_id bigint NOT NULL REFERENCES player_library_roots(player_id),
 partner_id bigint NOT NULL CHECK (partner_id > 0),
 state_version bigint NOT NULL CHECK (state_version > 0),
 favor_degree bigint NOT NULL CHECK (favor_degree BETWEEN 0 AND 2000),
 is_married boolean NOT NULL,
 feed_attrs jsonb NOT NULL CHECK (jsonb_typeof(feed_attrs)='array' AND jsonb_array_length(feed_attrs)=6),
 collect_quality_stage bigint NOT NULL CHECK (collect_quality_stage >= 0),
 collect_star_stage bigint NOT NULL CHECK (collect_star_stage >= 0),
 pending_candidate jsonb CHECK (pending_candidate IS NULL OR jsonb_typeof(pending_candidate)='object'),
 seed_policy_id text NOT NULL CHECK (seed_policy_id='LIBRARY_NEUTRAL_SEED_V1'),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY (player_id,partner_id),
 CHECK (NOT is_married OR favor_degree=2000)
);
-- A retained unresolved lane is not advanced by reconnect, elapsed time or response ACK.
CREATE TABLE player_library_admissions (
 player_id bigint NOT NULL,
 family text NOT NULL CHECK (family IN ('LIBRARY_GIFT','LIBRARY_FEED','LIBRARY_SAVE','LIBRARY_NORMAL_CLAIM','LIBRARY_SPECIAL_CLAIM')),
 operation_id uuid NOT NULL UNIQUE,
 partner_id bigint NOT NULL CHECK (partner_id >= 0),
 request_fingerprint text NOT NULL CHECK (length(request_fingerprint)=64),
 operation_context jsonb NOT NULL CHECK (jsonb_typeof(operation_context)='object'),
 content_revision text NOT NULL CHECK (length(content_revision)=64),
 admission_state text NOT NULL CHECK (admission_state IN ('PENDING','COMMITTED','REJECTED')),
 result jsonb,
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY (player_id,family)
);
-- ContentRegistry owns an immutable exact-revision payload; old revisions have no fabricated Library rows.
CREATE TABLE content_library_input_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload)='object')
);

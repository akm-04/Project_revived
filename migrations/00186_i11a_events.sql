-- +goose Up
-- owner: events
-- I11A-2 E1 events owner (I11A_EVENTS_V1 rulings 1-3 and 12-13, EA-1, EA-9).
-- Definitions are immutable server data; occurrences and cycle settings are
-- per-server data; player_event_claims is a player ledger kept forever (P4).
-- Ends_at NULL means permanent. Nullable command keys exist because the cycle
-- materialiser (E4) writes CYCLE occurrences without an operator command.

-- The overlap law is one occurrence per (server, activity); the range
-- exclusion needs btree_gist for the equality columns.
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE event_definitions (
 activity_id bigint NOT NULL CHECK (activity_id > 0 AND activity_id <= 2147483647),
 revision bigint NOT NULL CHECK (revision > 0),
 body jsonb NOT NULL CHECK (jsonb_typeof(body) = 'object'),
 sha256 text NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
 deployed_by_command text NOT NULL REFERENCES operator_commands (semantic_key),
 deployed_at timestamptz NOT NULL,
 PRIMARY KEY (activity_id, revision)
);

CREATE TABLE event_occurrences (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 logical_server_id integer NOT NULL REFERENCES logical_servers (logical_server_id),
 activity_id bigint NOT NULL,
 definition_revision bigint NOT NULL,
 starts_at timestamptz NOT NULL,
 ends_at timestamptz,
 claim_until timestamptz,
 source text NOT NULL CHECK (source IN ('CYCLE', 'OPERATOR', 'TICKET')),
 revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
 created_by_command text REFERENCES operator_commands (semantic_key),
 ended_early_by_command text REFERENCES operator_commands (semantic_key),
 cancelled_by_command text REFERENCES operator_commands (semantic_key),
 cancelled_at timestamptz,
 settled_at timestamptz,
 created_at timestamptz NOT NULL,
 FOREIGN KEY (activity_id, definition_revision) REFERENCES event_definitions (activity_id, revision),
 CHECK (ends_at IS NULL OR ends_at > starts_at),
 CHECK ((ends_at IS NULL) = (claim_until IS NULL)),
 CHECK ((cancelled_at IS NULL) = (cancelled_by_command IS NULL)),
 CHECK (cancelled_at IS NULL OR settled_at IS NULL),
 CONSTRAINT event_occurrences_no_overlap EXCLUDE USING gist (
  logical_server_id WITH =,
  activity_id WITH =,
  tstzrange(starts_at, coalesce(claim_until, 'infinity'::timestamptz), '[)') WITH &&
 ) WHERE (cancelled_at IS NULL AND settled_at IS NULL)
);
CREATE INDEX event_occurrences_server_activity ON event_occurrences (logical_server_id, activity_id, starts_at DESC, id DESC);

CREATE TABLE event_cycle_settings (
 logical_server_id integer PRIMARY KEY REFERENCES logical_servers (logical_server_id),
 mode text NOT NULL DEFAULT 'AUTO' CHECK (mode IN ('AUTO', 'OFF')),
 cycle_revision bigint NOT NULL DEFAULT 0 CHECK (cycle_revision >= 0),
 cycle_body jsonb,
 claim_window_hours integer NOT NULL DEFAULT 24 CHECK (claim_window_hours BETWEEN 1 AND 720),
 lookahead integer NOT NULL DEFAULT 2 CHECK (lookahead BETWEEN 0 AND 10),
 command_key text REFERENCES operator_commands (semantic_key),
 updated_at timestamptz NOT NULL,
 CHECK ((cycle_revision = 0) = (cycle_body IS NULL))
);

CREATE TABLE player_event_claims (
 player_id bigint NOT NULL REFERENCES players (player_id),
 occurrence_id bigint NOT NULL REFERENCES event_occurrences (id),
 tier bigint NOT NULL CHECK (tier > 0),
 period text NOT NULL CHECK (char_length(period) BETWEEN 1 AND 32),
 choice integer NOT NULL CHECK (choice BETWEEN 1 AND 3),
 claimed_at timestamptz NOT NULL,
 grant_receipt text NOT NULL CHECK (char_length(grant_receipt) BETWEEN 1 AND 256),
 PRIMARY KEY (player_id, occurrence_id, tier, period)
);

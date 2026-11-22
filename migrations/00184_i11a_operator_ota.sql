-- +goose Up
-- owner: operator (operator_commands), otarelease (ota_*)
-- I11A-1 (I11A_OPERATOR_COMMANDS_V1 rulings 3 and 6, I11A_OTA_RELEASE_V1 tables).
-- operator_commands is the idempotency ledger and the audit log; rows are kept
-- forever. Lock order: the command row first, then the owner's locks.
CREATE TABLE operator_commands (
 semantic_key text PRIMARY KEY CHECK (char_length(semantic_key) BETWEEN 1 AND 128),
 module_command text NOT NULL CHECK (module_command ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'),
 payload_sha256 text NOT NULL CHECK (payload_sha256 ~ '^[0-9a-f]{64}$'),
 principal text NOT NULL CHECK (char_length(principal) BETWEEN 1 AND 64),
 role text NOT NULL CHECK (role IN ('root')),
 scope text NOT NULL CHECK (scope = 'global' OR scope ~ '^server:[0-9]+$'),
 reason text NOT NULL CHECK (char_length(reason) BETWEEN 1 AND 500),
 state text NOT NULL CHECK (state IN ('ACCEPTED', 'APPLIED', 'REFUSED', 'FAILED')),
 result_json jsonb,
 created_at timestamptz NOT NULL,
 finished_at timestamptz,
 CHECK ((state = 'ACCEPTED') = (finished_at IS NULL))
);
CREATE INDEX operator_commands_created ON operator_commands (created_at DESC, semantic_key);
CREATE INDEX operator_commands_module ON operator_commands (module_command, created_at DESC);
CREATE INDEX operator_commands_principal ON operator_commands (principal, created_at DESC);

-- One version line 1.631.N (ruling 1); artifacts are immutable (ruling 2).
CREATE TABLE ota_releases (
 version text PRIMARY KEY CHECK (version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
 lane text NOT NULL CHECK (lane IN ('assets', 'code', 'catalog')),
 state text NOT NULL CHECK (state IN ('BUILT', 'ACTIVE', 'SUPERSEDED', 'WITHDRAWN')),
 package_files jsonb NOT NULL CHECK (jsonb_typeof(package_files) = 'array'),
 total_size bigint NOT NULL CHECK (total_size > 0 AND total_size < 2147483647),
 md5 text NOT NULL CHECK (md5 ~ '^[0-9a-f]{32}$'),
 sha256 text NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
 manifest jsonb NOT NULL CHECK (jsonb_typeof(manifest) = 'object'),
 built_by_command text NOT NULL REFERENCES operator_commands (semantic_key),
 built_at timestamptz NOT NULL,
 published_by_command text REFERENCES operator_commands (semantic_key),
 published_at timestamptz,
 superseded_at timestamptz,
 withdrawn_at timestamptz,
 CHECK ((state = 'BUILT') = (published_at IS NULL)),
 CHECK ((published_at IS NULL) = (published_by_command IS NULL)),
 CHECK ((state = 'SUPERSEDED') = (superseded_at IS NOT NULL)),
 CHECK ((state = 'WITHDRAWN') = (withdrawn_at IS NOT NULL))
);
CREATE INDEX ota_releases_lane_state ON ota_releases (lane, state);

CREATE TABLE ota_activations (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 version text NOT NULL REFERENCES ota_releases (version),
 action text NOT NULL CHECK (action IN ('PUBLISH', 'WITHDRAW', 'ROLLBACK')),
 command_key text NOT NULL REFERENCES operator_commands (semantic_key),
 at timestamptz NOT NULL,
 UNIQUE (command_key, version)
);

-- Asset-miss ledger (ruling 7): ANOMALY retention, 15 days by last_seen / day.
CREATE TABLE ota_asset_misses (
 path text NOT NULL CHECK (char_length(path) BETWEEN 1 AND 512),
 md5 text NOT NULL CHECK (md5 = '' OR md5 ~ '^[0-9a-f]{32}$'),
 first_seen timestamptz NOT NULL,
 last_seen timestamptz NOT NULL CHECK (last_seen >= first_seen),
 hits bigint NOT NULL CHECK (hits > 0),
 first_uid text,
 PRIMARY KEY (path, md5)
);
CREATE INDEX ota_asset_misses_last_seen ON ota_asset_misses (last_seen);

CREATE TABLE ota_asset_served_daily (
 path text NOT NULL CHECK (char_length(path) BETWEEN 1 AND 512),
 day date NOT NULL,
 hits bigint NOT NULL CHECK (hits > 0),
 PRIMARY KEY (path, day)
);
CREATE INDEX ota_asset_served_daily_day ON ota_asset_served_daily (day);

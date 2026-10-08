-- +goose Up
-- Neutral upgrade: no import of client history, Friend DM rows or bootstrap intents.
CREATE TABLE personal_dm_intents(
 operation_id uuid PRIMARY KEY,
 operation_digest text NOT NULL CHECK(operation_digest ~ '^[0-9a-f]{64}$'),
 payload_binding_digest text NOT NULL CHECK(payload_binding_digest ~ '^[0-9a-f]{64}$'),
 sender_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 recipient_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE CHECK(recipient_id<>sender_id),
 accepted_at timestamptz NOT NULL, expires_at timestamptz NOT NULL,
 block_version bigint NOT NULL CHECK(block_version>=0),
 policy_id text NOT NULL CHECK(policy_id='GENERAL_DM_DEADLINE_V1'),
 CHECK(expires_at=accepted_at+interval '8 seconds')
);
CREATE TABLE personal_dm_payloads(
 operation_id uuid PRIMARY KEY REFERENCES personal_dm_intents(operation_id) ON DELETE CASCADE,
 payload jsonb NOT NULL
);
CREATE TABLE personal_dm_delivery(
 operation_id uuid PRIMARY KEY REFERENCES personal_dm_intents(operation_id) ON DELETE CASCADE,
 status text NOT NULL CHECK(status IN('PENDING','CLAIMED','ATTEMPTING','WRITTEN_BEFORE_DEADLINE','UNDELIVERED','EXPIRED','PRIVACY_SUPPRESSED','ADMISSION_RETIRED','TIME_INVALID','UNKNOWN')),
 state_version bigint NOT NULL CHECK(state_version>0),
 claim_generation bigint NOT NULL CHECK(claim_generation>=0),
 owner_fence bigint NOT NULL CHECK(owner_fence>=0),
 lease_expires_at timestamptz,
 last_observed_at timestamptz NOT NULL,
 attempt_committed_at timestamptz,
 completion_upper_at timestamptz,
 terminal_receipt jsonb,
 updated_at timestamptz NOT NULL,
 CHECK(status<>'ATTEMPTING' OR attempt_committed_at IS NOT NULL),
 CHECK(status<>'WRITTEN_BEFORE_DEADLINE' OR completion_upper_at IS NOT NULL)
);
CREATE INDEX personal_dm_pending_idx ON personal_dm_delivery(operation_id) WHERE status IN('PENDING','CLAIMED','ATTEMPTING');

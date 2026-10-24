-- +goose Up
-- FriendDM owns immutable occurrences, delivery state and private projections.
-- Neutral upgrade: do not import client history or create any player owner rows.
CREATE TABLE friend_dm_roots (
 recipient_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
 state_version bigint NOT NULL CHECK(state_version>0),
 next_sequence bigint NOT NULL CHECK(next_sequence>0),
 last_decision_at timestamptz NOT NULL
);
CREATE TABLE friend_dm_occurrences (
 occurrence_id uuid PRIMARY KEY,
 operation_digest text NOT NULL CHECK(operation_digest ~ '^[0-9a-f]{64}$'),
 sender_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 recipient_id bigint NOT NULL REFERENCES friend_dm_roots(recipient_id) ON DELETE CASCADE,
 recipient_sequence bigint NOT NULL CHECK(recipient_sequence>0),
 accepted_at timestamptz NOT NULL,
 message text NOT NULL CHECK(octet_length(message)<=2048),
 friendship_generation bigint NOT NULL CHECK(friendship_generation>0),
 recipient_block_version bigint NOT NULL CHECK(recipient_block_version>=0),
 content_revision text NOT NULL,
 emoticon_id bigint NOT NULL CHECK(emoticon_id>=0),
 entitlement_version bigint NOT NULL CHECK(entitlement_version>=0),
 policy_id text NOT NULL CHECK(policy_id='FRIEND_DM_PENDING_V1'),
 UNIQUE(recipient_id,recipient_sequence),
 UNIQUE(occurrence_id,recipient_id),
 CHECK(sender_id<>recipient_id)
);
CREATE TABLE friend_dm_delivery (
 occurrence_id uuid PRIMARY KEY,
 recipient_id bigint NOT NULL REFERENCES friend_dm_roots(recipient_id) ON DELETE CASCADE,
 status text NOT NULL CHECK(status IN ('PENDING','TRANSPORT_WRITE_RECORDED','OFFLINE_PROJECTED','RETENTION_SUPPRESSED','PRIVACY_SUPPRESSED')),
 state_version bigint NOT NULL CHECK(state_version>0),
 claim_generation bigint NOT NULL CHECK(claim_generation>=0),
 owner_fence bigint NOT NULL CHECK(owner_fence>=0),
 expires_at timestamptz NULL,
 updated_at timestamptz NOT NULL,
 FOREIGN KEY(occurrence_id,recipient_id) REFERENCES friend_dm_occurrences(occurrence_id,recipient_id) ON DELETE CASCADE,
 CHECK((expires_at IS NULL AND owner_fence=0) OR (expires_at IS NOT NULL AND owner_fence>0 AND claim_generation>0 AND status='PENDING'))
);
CREATE INDEX friend_dm_pending_recipient_idx ON friend_dm_delivery(recipient_id,occurrence_id) WHERE status='PENDING';
CREATE TABLE friend_dm_projection_receipts (
 operation_id uuid PRIMARY KEY,
 recipient_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 manifest_digest text NOT NULL CHECK(manifest_digest ~ '^[0-9a-f]{64}$'),
 projected_at timestamptz NOT NULL,
 messages jsonb NOT NULL CHECK(jsonb_typeof(messages)='array')
);
CREATE TABLE content_emoticon_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 artifact jsonb NOT NULL CHECK(jsonb_typeof(artifact->'definitions')='array')
);

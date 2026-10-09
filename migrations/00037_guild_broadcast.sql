-- +goose Up
-- GUILD_BROADCAST_V1: neutral forward expansion after unchanged migration36.
-- No legacy broadcast reconstruction, recipient/Mail backfill or activation.
-- Immutable numeric identities intentionally have no live Guild/player FK:
-- deletion/retirement cannot cascade away an accepted delivery obligation.
CREATE TABLE content_guild_broadcast_policies (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);
CREATE TABLE guild_broadcast_sources (
 source_id uuid PRIMARY KEY,
 guild_id bigint NOT NULL CHECK(guild_id>0),
 logical_server_id bigint NOT NULL CHECK(logical_server_id>0),
 leader_player_id bigint NOT NULL CHECK(leader_player_id>0),
 leader_name text NOT NULL CHECK(octet_length(leader_name)>=0),
 name_snapshot_changed_at timestamptz NOT NULL,
 operation_started_at timestamptz NOT NULL,
 -- Exact Go context precision survives PostgreSQL microsecond projection.
 operation_started_at_exact text NOT NULL,
 entropy_seed bytea NOT NULL CHECK(octet_length(entropy_seed)=32),
 policy_refs jsonb NOT NULL CHECK(jsonb_typeof(policy_refs)='array'),
 decision_at timestamptz NOT NULL,
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 guild_core_revision text NOT NULL CHECK(guild_core_revision ~ '^[0-9a-f]{64}$'),
 policy_id text NOT NULL CHECK(policy_id='GUILD_BROADCAST_STOCK_TEXTLEN_V1'),
 title text NOT NULL CHECK(octet_length(title) BETWEEN 1 AND 80),
 body text NOT NULL CHECK(octet_length(body) BETWEEN 1 AND 800),
 source_fingerprint text NOT NULL CHECK(source_fingerprint ~ '^[0-9a-f]{64}$'),
 recipient_count integer NOT NULL CHECK(recipient_count BETWEEN 1 AND 50),
 source_receipt_id uuid NOT NULL UNIQUE REFERENCES gxb_operation_receipts(receipt_id) DEFERRABLE INITIALLY DEFERRED,
 CHECK(guild_id/1000000=logical_server_id),
 CHECK(name_snapshot_changed_at<=decision_at)
);
CREATE TABLE guild_broadcast_recipients (
 source_id uuid NOT NULL REFERENCES guild_broadcast_sources(source_id) ON DELETE RESTRICT,
 recipient_player_id bigint NOT NULL CHECK(recipient_player_id>0),
 join_event_id bigint NOT NULL CHECK(join_event_id>0),
 joined_at timestamptz NOT NULL,
 state text NOT NULL CHECK(state IN('PENDING','DELIVERED','RECIPIENT_GONE')),
 target_receipt_id uuid,
 mail_uuid uuid,
 wire_id bigint,
 acknowledged_at timestamptz,
 last_enqueue_at timestamptz NOT NULL,
 next_wakeup_at timestamptz NOT NULL CHECK(next_wakeup_at>=last_enqueue_at),
 PRIMARY KEY(source_id,recipient_player_id),
 CHECK((state='PENDING' AND target_receipt_id IS NULL AND mail_uuid IS NULL AND wire_id IS NULL AND acknowledged_at IS NULL)
 OR(state='DELIVERED' AND target_receipt_id IS NOT NULL AND mail_uuid IS NOT NULL AND wire_id IS NOT NULL AND wire_id BETWEEN 1 AND 9007199254740991 AND acknowledged_at IS NOT NULL)
 OR(state='RECIPIENT_GONE' AND target_receipt_id IS NOT NULL AND mail_uuid IS NULL AND wire_id IS NULL AND acknowledged_at IS NOT NULL))
);
-- Queue acceleration only: terminal rows are excluded from owner reconciliation.
CREATE INDEX guild_broadcast_pending_wakeup ON guild_broadcast_recipients(next_wakeup_at,source_id,recipient_player_id) WHERE state='PENDING';
-- Forward-only; source/recipient/Mail/receipt/sequence backups must be restored
-- together. Nonempty rollback is prohibited; partial restore requires repair.

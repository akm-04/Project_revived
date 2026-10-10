-- +goose Up
-- I7A-8B: retained Guild source facts and SocialInbox target proof.
-- No historical UPDATE/INSERT or projection backfill. Existing facts retain
-- their original columns/values; the two new legacy bindings begin NULL.

CREATE TABLE content_guild_invite_policies (
  revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
  payload jsonb NOT NULL CHECK (jsonb_typeof(payload)='object')
);

CREATE TABLE guild_invite_projection_cursors (
  guild_id bigint NOT NULL CHECK (guild_id > 0),
  recipient_player_id bigint NOT NULL CHECK (recipient_player_id > 0),
  last_generation bigint NOT NULL CHECK (last_generation > 0),
  state_version bigint NOT NULL CHECK (state_version > 0),
  updated_at timestamptz NOT NULL,
  PRIMARY KEY (guild_id,recipient_player_id)
);

CREATE TABLE guild_invite_projection_sources (
  source_id uuid PRIMARY KEY,
  source_serial bigserial NOT NULL UNIQUE,
  guild_id bigint NOT NULL CHECK (guild_id > 0),
  logical_server_id integer NOT NULL CHECK (logical_server_id > 0),
  recipient_player_id bigint NOT NULL CHECK (recipient_player_id > 0),
  inviter_player_id bigint NOT NULL CHECK (inviter_player_id > 0),
  invite_generation bigint NOT NULL CHECK (invite_generation > 0),
  source_payload jsonb NOT NULL CHECK (jsonb_typeof(source_payload)='object'),
  source_fingerprint text NOT NULL CHECK (source_fingerprint ~ '^[0-9a-f]{64}$'),
  core_receipt_id uuid NOT NULL REFERENCES gxb_operation_receipts(receipt_id) DEFERRABLE INITIALLY DEFERRED,
  decision_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL CHECK (expires_at > decision_at),
  last_join_event_id bigint NOT NULL CHECK (last_join_event_id >= 0),
  UNIQUE (guild_id,recipient_player_id,invite_generation),
  CHECK (guild_id / 1000000 = logical_server_id::bigint),
  CHECK (recipient_player_id / 100000 = logical_server_id::bigint),
  CHECK (inviter_player_id / 100000 = logical_server_id::bigint),
  CHECK (source_payload->'Operation'->>'ID'=source_id::text)
);
CREATE INDEX guild_invite_projection_sources_recipient_serial_idx
  ON guild_invite_projection_sources(recipient_player_id,source_serial);
CREATE INDEX guild_invite_projection_sources_guild_serial_idx
  ON guild_invite_projection_sources(guild_id,source_serial);

CREATE TABLE guild_invite_projection_deliveries (
  source_id uuid PRIMARY KEY REFERENCES guild_invite_projection_sources(source_id) ON DELETE RESTRICT,
  recipient_player_id bigint NOT NULL CHECK (recipient_player_id > 0),
  state text NOT NULL CHECK (state IN ('PENDING','MATERIALIZED','SUPPRESSED','RECIPIENT_GONE')),
  target_receipt_id uuid NULL,
  notice_id bigint NULL CHECK (notice_id BETWEEN 1 AND 9007199254740991),
  acknowledged_at timestamptz NULL,
  last_enqueue_at timestamptz NOT NULL,
  next_wakeup_at timestamptz NOT NULL CHECK (next_wakeup_at >= last_enqueue_at),
  CHECK ((state='PENDING' AND target_receipt_id IS NULL AND notice_id IS NULL AND acknowledged_at IS NULL)
      OR (state='MATERIALIZED' AND target_receipt_id IS NOT NULL AND notice_id IS NOT NULL AND acknowledged_at IS NOT NULL)
      OR (state IN ('SUPPRESSED','RECIPIENT_GONE') AND target_receipt_id IS NOT NULL AND notice_id IS NULL AND acknowledged_at IS NOT NULL))
);
CREATE INDEX guild_invite_projection_deliveries_due_idx
  ON guild_invite_projection_deliveries(next_wakeup_at,source_id) WHERE state='PENDING';

CREATE TABLE guild_invite_projection_markers (
  marker_id uuid PRIMARY KEY,
  marker_kind text NOT NULL CHECK (marker_kind IN ('JOIN','RETIRE')),
  guild_id bigint NOT NULL CHECK (guild_id > 0),
  subject_player_id bigint NOT NULL CHECK (subject_player_id > 0),
  event_id bigint NOT NULL UNIQUE CHECK (event_id > 0),
  max_issue_serial bigint NOT NULL CHECK (max_issue_serial >= 0),
  source_payload jsonb NOT NULL CHECK (jsonb_typeof(source_payload)='object'),
  source_fingerprint text NOT NULL CHECK (source_fingerprint ~ '^[0-9a-f]{64}$'),
  core_receipt_id uuid NOT NULL REFERENCES gxb_operation_receipts(receipt_id) DEFERRABLE INITIALLY DEFERRED,
  decision_at timestamptz NOT NULL,
  state text NOT NULL CHECK (state IN ('PENDING','COMPLETE')),
  cursor_serial bigint NOT NULL CHECK (cursor_serial >= 0 AND cursor_serial <= max_issue_serial),
  cursor_receipt_id uuid NULL REFERENCES gxb_operation_receipts(receipt_id) DEFERRABLE INITIALLY DEFERRED,
  cursor_proof jsonb NULL CHECK (cursor_proof IS NULL OR jsonb_typeof(cursor_proof)='object'),
  last_enqueue_at timestamptz NOT NULL,
  next_wakeup_at timestamptz NOT NULL CHECK (next_wakeup_at >= last_enqueue_at),
  completed_at timestamptz NULL,
  CHECK ((state='PENDING' AND completed_at IS NULL) OR (state='COMPLETE' AND completed_at IS NOT NULL AND cursor_serial=max_issue_serial)),
  CHECK ((cursor_serial=0 AND state='PENDING' AND cursor_receipt_id IS NULL AND cursor_proof IS NULL)
      OR (cursor_receipt_id IS NOT NULL AND cursor_proof IS NOT NULL)),
  CHECK (source_payload->'Operation'->>'ID'=marker_id::text)
);
CREATE INDEX guild_invite_projection_markers_due_idx
  ON guild_invite_projection_markers(next_wakeup_at,marker_id) WHERE state='PENDING';

CREATE TABLE social_guild_invite_materializations (
  source_id uuid PRIMARY KEY,
  recipient_player_id bigint NOT NULL CHECK (recipient_player_id > 0),
  source_fingerprint text NOT NULL CHECK (source_fingerprint ~ '^[0-9a-f]{64}$'),
  receipt_id uuid NOT NULL UNIQUE REFERENCES gxb_operation_receipts(receipt_id) DEFERRABLE INITIALLY DEFERRED,
  state text NOT NULL CHECK (state IN ('MATERIALIZED','SUPPRESSED','RECIPIENT_GONE')),
  notice_id bigint NULL CHECK (notice_id BETWEEN 1 AND 9007199254740991),
  root_version bigint NOT NULL CHECK (root_version >= 0),
  target_payload jsonb NOT NULL CHECK (jsonb_typeof(target_payload)='object'),
  decision_at timestamptz NOT NULL,
  CHECK ((state='MATERIALIZED' AND notice_id IS NOT NULL AND root_version > 0)
      OR (state IN ('SUPPRESSED','RECIPIENT_GONE') AND notice_id IS NULL))
);

CREATE TABLE social_guild_invite_invalidations (
  marker_id uuid NOT NULL,
  source_id uuid NOT NULL,
  source_serial bigint NOT NULL CHECK (source_serial > 0),
  source_key text NOT NULL CHECK (source_key <> ''),
  recipient_player_id bigint NOT NULL CHECK (recipient_player_id > 0),
  marker_fingerprint text NOT NULL CHECK (marker_fingerprint ~ '^[0-9a-f]{64}$'),
  source_fingerprint text NOT NULL CHECK (source_fingerprint ~ '^[0-9a-f]{64}$'),
  receipt_id uuid NOT NULL UNIQUE REFERENCES gxb_operation_receipts(receipt_id) DEFERRABLE INITIALLY DEFERRED,
  notice_id bigint NULL CHECK (notice_id BETWEEN 1 AND 9007199254740991),
  root_version bigint NOT NULL CHECK (root_version >= 0),
  consumed boolean NOT NULL,
  target_payload jsonb NOT NULL CHECK (jsonb_typeof(target_payload)='object'),
  decision_at timestamptz NOT NULL,
  PRIMARY KEY (marker_id,source_id),
  CHECK (NOT consumed OR notice_id IS NOT NULL)
);
CREATE INDEX social_guild_invite_invalidations_marker_serial_idx
  ON social_guild_invite_invalidations(marker_id,source_serial);

-- These optional same-owner links are created only by qualified new producer
-- transactions. They do not reinterpret or update historical Invite/events.
ALTER TABLE guild_invites ADD COLUMN projection_source_id uuid NULL
  REFERENCES guild_invite_projection_sources(source_id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE guild_membership_events ADD COLUMN projection_source_id uuid NULL
  REFERENCES guild_invite_projection_markers(marker_id) DEFERRABLE INITIALLY DEFERRED;

-- Forward-only. Recovery is a complete consistent backup restore/redeploy.

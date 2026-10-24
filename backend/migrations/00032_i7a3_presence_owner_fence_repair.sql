-- +goose Up
-- I7A-3 real-PostgreSQL repair: fence derived Presence writes across
-- realtime-owner handoff without changing R6 advisory-lock serving authority.
--
-- The Pass626 gate candidate already shipped/applied migration 00031 in test
-- infrastructure, so this repair is forward-only. Presence lease rows are
-- derived/recoverable and deliberately discarded rather than fabricating an
-- owner epoch for an unfenced prior process. Durable player last_seen roots are
-- preserved. Live admitted sockets rebuild leases through validated heartbeat.

CREATE SEQUENCE realtime_presence_owner_fence_seq AS bigint START WITH 1 INCREMENT BY 1 NO CYCLE;

CREATE TABLE realtime_presence_owner_state (
  singleton boolean PRIMARY KEY DEFAULT TRUE CHECK (singleton),
  owner_fence bigint NOT NULL CHECK (owner_fence > 0),
  activated_at timestamptz NOT NULL
);

DELETE FROM realtime_presence_leases;

ALTER TABLE realtime_presence_leases
  ADD COLUMN realtime_owner_fence bigint NOT NULL CHECK (realtime_owner_fence > 0);

-- +goose Up
-- Pass625/I7A-3: SocialPresence derived projection.
-- Presence never authorizes gameplay or Guild membership. No historical
-- backfill is fabricated; live lease truth is rebuilt from admitted realtime
-- sessions and converges through heartbeat/expiry reconciliation.

CREATE TABLE player_social_presence (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  last_seen_at timestamptz NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE realtime_presence_leases (
  gameplay_context_id uuid NOT NULL REFERENCES gameplay_contexts(context_id) ON DELETE CASCADE,
  physical_role text NOT NULL CHECK (physical_role IN ('WORLD','GUILD','SERVICE')),
  player_id bigint NOT NULL REFERENCES player_social_presence(player_id) ON DELETE CASCADE,
  realtime_instance_id uuid NOT NULL,
  connection_generation bigint NOT NULL CHECK (connection_generation > 0),
  connected_at timestamptz NOT NULL,
  last_renewed_at timestamptz NOT NULL,
  lease_expires_at timestamptz NOT NULL,
  PRIMARY KEY(gameplay_context_id,physical_role),
  CHECK (last_renewed_at >= connected_at),
  CHECK (lease_expires_at > connected_at)
);

CREATE INDEX realtime_presence_leases_player_expiry_idx
  ON realtime_presence_leases(player_id,lease_expires_at);
CREATE INDEX realtime_presence_leases_expiry_player_idx
  ON realtime_presence_leases(lease_expires_at,player_id);

-- Forward-only by project law. Rollback is restore/redeploy.

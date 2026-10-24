-- +goose Up
-- Pass631/I7A-4A: stock-invisible SocialRelation/SocialInbox durable foundation
-- plus the I4-owned exact-name discovery index selected by Pass630 research.
--
-- This migration deliberately creates no Social rows for existing players.
-- Friendship/request/block/inbox history cannot be reconstructed from unrelated
-- timestamps, Presence, client SQLite, or frozen V1 evidence. Canonical Social
-- facts begin only when later authorized Social commands create them.
--
-- Player names remain non-unique. The index below accelerates exact-name reads
-- owned by I4/player-directory; it does not transfer directory ownership to
-- Social and does not activate MID23 naming behavior.

CREATE INDEX player_directory_profiles_name_player_idx
  ON player_directory_profiles(name COLLATE "C",player_id);

CREATE TABLE player_social_roots (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  CHECK (updated_at >= created_at)
);

CREATE TABLE social_friendships (
  player_low_id bigint NOT NULL REFERENCES player_social_roots(player_id) ON DELETE CASCADE,
  player_high_id bigint NOT NULL REFERENCES player_social_roots(player_id) ON DELETE CASCADE,
  generation bigint NOT NULL CHECK (generation > 0),
  active boolean NOT NULL,
  activated_at timestamptz NOT NULL,
  ended_at timestamptz NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_low_id,player_high_id),
  CHECK (player_low_id < player_high_id),
  CHECK ((active AND ended_at IS NULL) OR (NOT active AND ended_at IS NOT NULL)),
  CHECK (updated_at >= activated_at),
  CHECK (ended_at IS NULL OR ended_at >= activated_at)
);

CREATE TABLE social_friend_requests (
  requester_player_id bigint NOT NULL REFERENCES player_social_roots(player_id) ON DELETE CASCADE,
  target_player_id bigint NOT NULL REFERENCES player_social_roots(player_id) ON DELETE CASCADE,
  generation bigint NOT NULL CHECK (generation > 0),
  status text NOT NULL CHECK (status IN ('PENDING','ACCEPTED','DENIED','IGNORED')),
  request_msg text NOT NULL DEFAULT '' CHECK (char_length(request_msg) <= 26),
  requested_at timestamptz NOT NULL,
  terminal_at timestamptz NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(requester_player_id,target_player_id),
  CHECK (requester_player_id <> target_player_id),
  CHECK ((status='PENDING' AND terminal_at IS NULL) OR (status<>'PENDING' AND terminal_at IS NOT NULL)),
  CHECK (updated_at >= requested_at),
  CHECK (terminal_at IS NULL OR terminal_at >= requested_at)
);

CREATE INDEX social_friend_requests_target_pending_idx
  ON social_friend_requests(target_player_id,requested_at DESC,requester_player_id)
  WHERE status='PENDING';
CREATE INDEX social_friend_requests_requester_pending_idx
  ON social_friend_requests(requester_player_id,requested_at DESC,target_player_id)
  WHERE status='PENDING';

CREATE TABLE social_blocks (
  blocker_player_id bigint NOT NULL REFERENCES player_social_roots(player_id) ON DELETE CASCADE,
  blocked_player_id bigint NOT NULL REFERENCES player_social_roots(player_id) ON DELETE CASCADE,
  generation bigint NOT NULL CHECK (generation > 0),
  active boolean NOT NULL,
  activated_at timestamptz NOT NULL,
  removed_at timestamptz NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(blocker_player_id,blocked_player_id),
  CHECK (blocker_player_id <> blocked_player_id),
  CHECK ((active AND removed_at IS NULL) OR (NOT active AND removed_at IS NOT NULL)),
  CHECK (updated_at >= activated_at),
  CHECK (removed_at IS NULL OR removed_at >= activated_at)
);

CREATE INDEX social_blocks_blocked_active_idx
  ON social_blocks(blocked_player_id,blocker_player_id)
  WHERE active;

CREATE TABLE social_request_epochs (
  player_id bigint NOT NULL REFERENCES player_social_roots(player_id) ON DELETE CASCADE,
  policy_id text NOT NULL CHECK (policy_id <> ''),
  epoch_generation bigint NOT NULL CHECK (epoch_generation >= 0),
  epoch_started_at timestamptz NOT NULL,
  successful_new_requests bigint NOT NULL DEFAULT 0 CHECK (successful_new_requests >= 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_id,policy_id),
  CHECK (updated_at >= epoch_started_at)
);

CREATE SEQUENCE social_notice_id_seq AS bigint START WITH 1 INCREMENT BY 1 NO CYCLE;

CREATE TABLE social_notices (
  recipient_player_id bigint NOT NULL REFERENCES player_social_roots(player_id) ON DELETE CASCADE,
  notice_id bigint NOT NULL DEFAULT nextval('social_notice_id_seq') CHECK (notice_id > 0),
  notice_type smallint NOT NULL CHECK (notice_type > 0),
  source_kind text NOT NULL CHECK (source_kind <> ''),
  source_key text NOT NULL CHECK (source_key <> ''),
  related_player_id bigint NULL REFERENCES players(player_id) ON DELETE SET NULL,
  active boolean NOT NULL DEFAULT TRUE,
  notice_time timestamptz NOT NULL,
  dismissed_at timestamptz NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(recipient_player_id,notice_id),
  UNIQUE(recipient_player_id,source_kind,source_key),
  CHECK ((active AND dismissed_at IS NULL) OR (NOT active AND dismissed_at IS NOT NULL)),
  CHECK (updated_at >= created_at),
  CHECK (dismissed_at IS NULL OR dismissed_at >= notice_time)
);

CREATE INDEX social_notices_active_newest_idx
  ON social_notices(recipient_player_id,notice_time DESC,notice_id DESC)
  WHERE active;

-- Forward-only by project law. Rollback is restore/redeploy.

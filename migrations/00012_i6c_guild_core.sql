-- +goose Up
-- Pass498/I6C: canonical Guild + GuildMembership authority.
-- No backfill exists because Pass497 contains no canonical Guild truth.

CREATE TABLE guild_server_allocators (
  logical_server_id integer PRIMARY KEY REFERENCES logical_servers(logical_server_id) ON DELETE RESTRICT,
  next_serial bigint NOT NULL DEFAULT 1 CHECK (next_serial BETWEEN 1 AND 1000000),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL
);

CREATE TABLE guilds (
  guild_id bigint PRIMARY KEY,
  logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id) ON DELETE RESTRICT,
  name text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 10),
  icon bigint NOT NULL CHECK (icon > 0),
  icon_frame bigint NOT NULL DEFAULT 0 CHECK (icon_frame >= 0),
  des text NOT NULL DEFAULT '' CHECK (char_length(des) <= 40),
  apply_type smallint NOT NULL CHECK (apply_type IN (0,1,2)),
  min_allow_level bigint NOT NULL CHECK (min_allow_level BETWEEN 1 AND 1000000),
  vitality bigint NOT NULL CHECK (vitality >= 0),
  policy_revision text NOT NULL CHECK (btrim(policy_revision) <> ''),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  retired_at timestamptz NULL,
  CHECK (guild_id / 1000000 = logical_server_id::bigint),
  CHECK ((guild_id % 1000000) BETWEEN 1 AND 999999)
);
CREATE INDEX guilds_server_active_idx ON guilds(logical_server_id,guild_id) WHERE retired_at IS NULL;
-- SOURCE_FACT: client message 30019 rejects duplicate Guild names.
-- IMPLEMENTATION_DECISION: I6C enforces active-name uniqueness per logical server
-- using exact C-collation text; source does not prove global scope or case folding.
CREATE UNIQUE INDEX guilds_server_active_name_uq ON guilds(logical_server_id, name COLLATE "C") WHERE retired_at IS NULL;

CREATE TABLE guild_memberships (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  guild_id bigint NOT NULL REFERENCES guilds(guild_id) ON DELETE RESTRICT,
  role smallint NOT NULL CHECK (role IN (0,1,2)),
  joined_at timestamptz NOT NULL,
  membership_version bigint NOT NULL DEFAULT 1 CHECK (membership_version > 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL
);
CREATE INDEX guild_memberships_guild_idx ON guild_memberships(guild_id,player_id);
CREATE UNIQUE INDEX guild_memberships_one_leader_per_guild_uq ON guild_memberships(guild_id) WHERE role=1;

CREATE TABLE guild_applications (
  guild_id bigint NOT NULL REFERENCES guilds(guild_id) ON DELETE CASCADE,
  player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  application_generation bigint NOT NULL CHECK (application_generation > 0),
  created_at timestamptz NOT NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  PRIMARY KEY(guild_id,player_id)
);
CREATE INDEX guild_applications_player_idx ON guild_applications(player_id,created_at,guild_id);

CREATE TABLE guild_invites (
  guild_id bigint NOT NULL REFERENCES guilds(guild_id) ON DELETE CASCADE,
  invited_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  invite_generation bigint NOT NULL CHECK (invite_generation > 0),
  inviter_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL CHECK (expires_at > created_at),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  PRIMARY KEY(guild_id,invited_player_id)
);
CREATE INDEX guild_invites_invited_idx ON guild_invites(invited_player_id,expires_at,guild_id);

CREATE TABLE guild_membership_events (
  event_id bigserial PRIMARY KEY,
  player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
  guild_id bigint NOT NULL REFERENCES guilds(guild_id) ON DELETE RESTRICT,
  event_kind text NOT NULL CHECK (event_kind IN ('JOIN','LEAVE','KICK','DISSOLVE')),
  actor_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
  occurred_at timestamptz NOT NULL,
  policy_revision text NOT NULL CHECK (btrim(policy_revision) <> ''),
  operation_id uuid NULL
);
CREATE INDEX guild_membership_events_player_time_idx ON guild_membership_events(player_id,occurred_at DESC,event_id DESC);

CREATE TABLE guild_invite_send_events (
  event_id bigserial PRIMARY KEY,
  guild_id bigint NOT NULL REFERENCES guilds(guild_id) ON DELETE RESTRICT,
  inviter_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
  invited_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
  occurred_at timestamptz NOT NULL,
  policy_revision text NOT NULL CHECK (btrim(policy_revision) <> ''),
  operation_id uuid NULL
);
CREATE INDEX guild_invite_send_events_inviter_time_idx ON guild_invite_send_events(inviter_player_id,occurred_at DESC,event_id DESC);

CREATE TABLE guild_audit_log (
  guild_id bigint NOT NULL REFERENCES guilds(guild_id) ON DELETE RESTRICT,
  sequence bigint NOT NULL CHECK (sequence > 0),
  event_kind text NOT NULL CHECK (btrim(event_kind) <> ''),
  actor_player_id bigint NULL REFERENCES players(player_id) ON DELETE RESTRICT,
  subject_player_id bigint NULL REFERENCES players(player_id) ON DELETE RESTRICT,
  occurred_at timestamptz NOT NULL,
  policy_revision text NOT NULL CHECK (btrim(policy_revision) <> ''),
  operation_id uuid NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY(guild_id,sequence)
);

-- Forward-only by project law. Rollback is restore/redeploy.

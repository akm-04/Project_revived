-- +goose Up
CREATE TABLE accounts (
  account_id uuid PRIMARY KEY,
  status text NOT NULL CHECK (status IN ('ACTIVE','DISABLED')),
  created_at timestamptz NOT NULL,
  disabled_at timestamptz NULL,
  liveness_version bigint NOT NULL DEFAULT 1 CHECK (liveness_version > 0)
);
CREATE TABLE account_provider_bindings (
  binding_id uuid PRIMARY KEY,
  account_id uuid NOT NULL REFERENCES accounts(account_id),
  provider_key text NOT NULL,
  subject_normalized text NOT NULL,
  linked_at timestamptz NOT NULL,
  disabled_at timestamptz NULL,
  provider_metadata jsonb NULL,
  UNIQUE(provider_key,subject_normalized)
);
CREATE TABLE account_sessions (
  session_id uuid PRIMARY KEY,
  account_id uuid NOT NULL REFERENCES accounts(account_id),
  auth_profile text NOT NULL,
  issued_at timestamptz NOT NULL,
  absolute_expires_at timestamptz NULL,
  idle_timeout_seconds bigint NULL CHECK (idle_timeout_seconds IS NULL OR idle_timeout_seconds > 0),
  last_activity_at timestamptz NOT NULL,
  revoked_at timestamptz NULL,
  revocation_reason text NULL,
  liveness_version bigint NOT NULL DEFAULT 1 CHECK (liveness_version > 0)
);
CREATE TABLE account_session_credentials (
  credential_id uuid PRIMARY KEY,
  session_id uuid NOT NULL REFERENCES account_sessions(session_id),
  kind text NOT NULL CHECK (kind IN ('SID','LOGIN_TOKEN')),
  digest bytea NOT NULL UNIQUE CHECK (octet_length(digest)=32),
  issued_at timestamptz NOT NULL,
  expires_at timestamptz NULL,
  revoked_at timestamptz NULL
);
CREATE UNIQUE INDEX account_session_one_live_credential_kind_uq ON account_session_credentials(session_id,kind) WHERE revoked_at IS NULL;
CREATE TABLE logical_servers (
  logical_server_id integer PRIMARY KEY CHECK (logical_server_id > 0),
  name text NOT NULL,
  first_opened_at timestamptz NULL,
  directory_visible boolean NOT NULL,
  existing_login_allowed boolean NOT NULL,
  new_character_allowed boolean NOT NULL,
  next_player_id bigint NOT NULL,
  max_player_id bigint NOT NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  retired_at timestamptz NULL,
  operator_metadata jsonb NULL,
  CHECK (next_player_id >= logical_server_id::bigint*100000 + 1),
  CHECK (max_player_id <= (logical_server_id::bigint+1)*100000 - 1),
  CHECK (next_player_id <= max_player_id + 1)
);
CREATE TABLE players (
  player_id bigint PRIMARY KEY,
  account_id uuid NOT NULL REFERENCES accounts(account_id),
  logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
  created_at timestamptz NOT NULL,
  bootstrap_profile_version text NOT NULL,
  first_entry_pending boolean NOT NULL DEFAULT true,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  UNIQUE(account_id,logical_server_id),
  CHECK (player_id > logical_server_id::bigint*100000),
  CHECK (player_id < (logical_server_id::bigint+1)*100000)
);
CREATE TABLE account_session_server_observations (
  session_id uuid NOT NULL REFERENCES account_sessions(session_id),
  logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
  observed_at timestamptz NOT NULL,
  PRIMARY KEY(session_id,logical_server_id)
);
CREATE TABLE gameplay_contexts (
  context_id uuid PRIMARY KEY,
  session_id uuid NOT NULL REFERENCES account_sessions(session_id),
  account_id uuid NOT NULL REFERENCES accounts(account_id),
  logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
  player_id bigint NOT NULL REFERENCES players(player_id),
  context_generation bigint NOT NULL CHECK (context_generation > 0),
  created_at timestamptz NOT NULL,
  ended_at timestamptz NULL,
  end_reason text NULL,
  liveness_version bigint NOT NULL DEFAULT 1 CHECK (liveness_version > 0)
);
CREATE UNIQUE INDEX gameplay_context_one_live_per_session_uq ON gameplay_contexts(session_id) WHERE ended_at IS NULL;
CREATE TABLE gameplay_context_credentials (
  credential_id uuid PRIMARY KEY,
  context_id uuid NOT NULL REFERENCES gameplay_contexts(context_id),
  session_id uuid NOT NULL REFERENCES account_sessions(session_id),
  digest bytea NOT NULL UNIQUE CHECK (octet_length(digest)=32),
  credential_generation integer NOT NULL CHECK (credential_generation > 0),
  derivation_key_id text NOT NULL,
  issued_at timestamptz NOT NULL,
  revoked_at timestamptz NULL
);
CREATE UNIQUE INDEX gameplay_context_one_live_credential_uq ON gameplay_context_credentials(context_id,credential_generation) WHERE revoked_at IS NULL;
INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES
 (1,'Server 1',CURRENT_TIMESTAMP,true,true,true,100001,199999,1,CURRENT_TIMESTAMP),
 (2,'Server 2',CURRENT_TIMESTAMP,true,true,true,200001,299999,1,CURRENT_TIMESTAMP)
ON CONFLICT (logical_server_id) DO NOTHING;

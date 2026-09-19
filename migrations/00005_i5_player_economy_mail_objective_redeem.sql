-- +goose Up
-- Pass446 / I5-A: canonical Player Core, TypedEconomy, Mail, Objective and Redeem owners.
--
-- This migration deliberately creates owner-scoped relational truth. Grant itself
-- remains orchestration over these owners plus the Wave-A semantic receipt store;
-- there is no grant mega-table and no generic gameplay outbox.
--
-- The I4 player_directory_profiles table remains a stock directory projection
-- seam. I5 backfills its source-proven profile/progression subset into canonical
-- owners below; future I5 mutations must update the directory projection from
-- canonical Player Core state in the same business transaction.

CREATE TABLE player_profiles (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  display_name text NOT NULL DEFAULT '',
  avatar_id bigint NOT NULL CHECK (avatar_id > 0),
  avatar_frame_id bigint NOT NULL DEFAULT 0 CHECK (avatar_frame_id >= 0),
  player_type bigint NOT NULL DEFAULT 0,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE player_progression (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  level bigint NOT NULL DEFAULT 1 CHECK (level >= 1),
  exp bigint NOT NULL DEFAULT 0 CHECK (exp >= 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL
);

CREATE TABLE player_story_cursors (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  story_id bigint NOT NULL DEFAULT 0 CHECK (story_id >= 0),
  story_state bigint NOT NULL DEFAULT 0 CHECK (story_state >= 0),
  guide_id bigint NOT NULL DEFAULT 0 CHECK (guide_id >= 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL
);

CREATE TABLE player_function_unlocks (
  player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  function_id bigint NOT NULL CHECK (function_id > 0),
  opened_at timestamptz NOT NULL,
  source_fact_key text NOT NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  PRIMARY KEY(player_id,function_id),
  UNIQUE(player_id,source_fact_key)
);

CREATE TABLE player_guide_return_state (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  guide_return_id bigint NOT NULL DEFAULT 0 CHECK (guide_return_id >= 0),
  guide_function_ids bigint[] NOT NULL DEFAULT '{}'::bigint[],
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL,
  CHECK (array_position(guide_function_ids,NULL) IS NULL)
);

-- Backfill only state that the sealed I4 projection actually persisted.
-- exp/player_type/story/guide values were not persisted by I4 and therefore use
-- the same bounded I4 compatibility defaults already sent to the stock client.
INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)
SELECT player_id,name,avatar_id,avatar_frame_id,0,state_version,created_at,updated_at
FROM player_directory_profiles;

INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)
SELECT player_id,lev,0,state_version,updated_at
FROM player_directory_profiles;

INSERT INTO player_story_cursors(player_id,story_id,story_state,guide_id,state_version,updated_at)
SELECT player_id,0,0,0,1,updated_at
FROM player_directory_profiles;

INSERT INTO player_guide_return_state(player_id,guide_return_id,guide_function_ids,state_version,updated_at)
SELECT player_id,0,'{}'::bigint[],1,updated_at
FROM player_directory_profiles;

-- TypedEconomy scalar owner. Absence means zero for registered scalar resources.
CREATE TABLE player_currency_balances (
  player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  resource_key text NOT NULL,
  amount bigint NOT NULL CHECK (amount >= 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_id,resource_key),
  CHECK (resource_key <> '')
);

-- Temporal resources are explicit rows once a versioned regeneration policy is
-- activated. I5-A does not fabricate fresh-player starting amounts/policy rows.
CREATE TABLE player_temporal_resources (
  player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  resource_key text NOT NULL,
  stored_amount bigint NOT NULL CHECK (stored_amount >= 0),
  regen_anchor_at timestamptz NOT NULL,
  policy_version text NOT NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_id,resource_key),
  CHECK (resource_key <> ''),
  CHECK (policy_version <> '')
);

CREATE TABLE player_item_stacks (
  player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  item_id bigint NOT NULL CHECK (item_id > 0),
  quantity bigint NOT NULL CHECK (quantity >= 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  acquired_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_id,item_id)
);

-- Mail preserves the stock compound identity (recipient,namespace,wire_id).
CREATE TABLE mail_namespace_counters (
  recipient_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  namespace text NOT NULL CHECK (namespace IN ('NORMAL','REGION')),
  next_wire_id bigint NOT NULL CHECK (next_wire_id > 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  PRIMARY KEY(recipient_player_id,namespace)
);

CREATE TABLE mail_records (
  mail_uuid uuid PRIMARY KEY,
  recipient_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  namespace text NOT NULL CHECK (namespace IN ('NORMAL','REGION')),
  wire_id bigint NOT NULL CHECK (wire_id > 0),
  source_kind text NOT NULL,
  source_key text NOT NULL,
  category bigint NOT NULL DEFAULT 0,
  title text NOT NULL DEFAULT '',
  sender text NOT NULL DEFAULT '',
  body text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL,
  expires_at timestamptz NULL,
  read_at timestamptz NULL,
  shown boolean NOT NULL DEFAULT true,
  claimed_at timestamptz NULL,
  platform_eligibility text NOT NULL DEFAULT 'ANY',
  compatibility_policy_version text NOT NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  UNIQUE(recipient_player_id,namespace,wire_id),
  UNIQUE(recipient_player_id,source_kind,source_key),
  CHECK (source_kind <> ''),
  CHECK (source_key <> ''),
  CHECK (compatibility_policy_version <> ''),
  CHECK (platform_eligibility IN ('ANY','ANDROID','IOS')),
  CHECK (expires_at IS NULL OR expires_at > created_at)
);
CREATE INDEX mail_records_player_created_idx ON mail_records(recipient_player_id,created_at DESC,wire_id DESC);
CREATE INDEX mail_records_player_unsettled_idx ON mail_records(recipient_player_id,claimed_at,expires_at);

CREATE TABLE mail_attachments (
  mail_uuid uuid NOT NULL REFERENCES mail_records(mail_uuid) ON DELETE CASCADE,
  ordinal integer NOT NULL CHECK (ordinal >= 0),
  grant_line_kind text NOT NULL,
  resource_key text NULL,
  item_id bigint NULL CHECK (item_id IS NULL OR item_id > 0),
  amount bigint NOT NULL CHECK (amount > 0),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY(mail_uuid,ordinal),
  CHECK (grant_line_kind IN ('SCALAR_CURRENCY','TEMPORAL','STACK_ITEM','PLAYER_EXP','PARTNER_ENTITY','SPECIALIZED_DOMAIN'))
);

-- Wave-E core mission family only. Other achievement/event/battle-pass families
-- retain their own later-domain ownership and must not be folded into this row.
CREATE TABLE player_mission_instances (
  player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
  program_id text NOT NULL,
  objective_id bigint NOT NULL CHECK (objective_id > 0),
  generation_id text NOT NULL DEFAULT '',
  definition_revision text NOT NULL,
  progress bigint NOT NULL DEFAULT 0 CHECK (progress >= 0),
  completed_at timestamptz NULL,
  claim_state text NOT NULL DEFAULT 'UNCLAIMED' CHECK (claim_state IN ('UNCLAIMED','CLAIMED')),
  claimed_at timestamptz NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  PRIMARY KEY(player_id,program_id,objective_id,generation_id),
  CHECK (program_id <> ''),
  CHECK (definition_revision <> ''),
  CHECK ((claim_state='CLAIMED') = (claimed_at IS NOT NULL))
);

-- Redeem is a direct entitlement path into Grant. These tables own campaign/code
-- truth only; they cannot own or mutate Commerce state.
CREATE TABLE redeem_reward_bundle_revisions (
  reward_bundle_revision_id uuid PRIMARY KEY,
  grant_plan jsonb NOT NULL,
  content_hash bytea NOT NULL CHECK (octet_length(content_hash)=32),
  created_by text NOT NULL,
  created_at timestamptz NOT NULL,
  immutable_after_issue boolean NOT NULL DEFAULT true
);

CREATE TABLE redeem_campaigns (
  campaign_id uuid PRIMARY KEY,
  name text NOT NULL,
  status text NOT NULL CHECK (status IN ('DRAFT','ACTIVE','DISABLED','EXPIRED')),
  redemption_subject text NOT NULL CHECK (redemption_subject IN ('PLAYER','ACCOUNT','PLAYER_ON_LOGICAL_SERVER','GLOBAL_SINGLE_USE')),
  starts_at timestamptz NULL,
  ends_at timestamptz NULL,
  audience_policy jsonb NOT NULL DEFAULT '{}'::jsonb,
  reward_bundle_revision_id uuid NOT NULL REFERENCES redeem_reward_bundle_revisions(reward_bundle_revision_id),
  total_cap bigint NULL CHECK (total_cap IS NULL OR total_cap > 0),
  per_subject_cap bigint NOT NULL DEFAULT 1 CHECK (per_subject_cap > 0),
  policy_version text NOT NULL,
  created_by text NOT NULL,
  created_at timestamptz NOT NULL,
  activated_at timestamptz NULL,
  disabled_at timestamptz NULL,
  CHECK (name <> ''),
  CHECK (policy_version <> ''),
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at)
);

CREATE TABLE redeem_codes (
  code_id uuid PRIMARY KEY,
  campaign_id uuid NOT NULL REFERENCES redeem_campaigns(campaign_id),
  lookup_digest bytea NOT NULL UNIQUE CHECK (octet_length(lookup_digest)=32),
  code_kind text NOT NULL CHECK (code_kind IN ('PUBLIC_CAMPAIGN_CODE','GENERATED_SINGLE_USE_TOKEN')),
  global_use_limit bigint NULL CHECK (global_use_limit IS NULL OR global_use_limit > 0),
  use_count bigint NOT NULL DEFAULT 0 CHECK (use_count >= 0),
  status text NOT NULL CHECK (status IN ('ACTIVE','DISABLED','EXHAUSTED','EXPIRED')),
  issued_batch_id uuid NULL,
  created_at timestamptz NOT NULL,
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  CHECK (global_use_limit IS NULL OR use_count <= global_use_limit)
);

CREATE TABLE redeem_redemptions (
  redemption_id uuid PRIMARY KEY,
  code_id uuid NOT NULL REFERENCES redeem_codes(code_id),
  subject_type text NOT NULL,
  subject_id text NOT NULL,
  redemption_slot bigint NOT NULL DEFAULT 1 CHECK (redemption_slot > 0),
  player_id bigint NOT NULL REFERENCES players(player_id),
  account_id uuid NOT NULL REFERENCES accounts(account_id),
  logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
  reward_bundle_revision_id uuid NOT NULL REFERENCES redeem_reward_bundle_revisions(reward_bundle_revision_id),
  grant_receipt_id uuid NOT NULL REFERENCES gxb_operation_receipts(receipt_id),
  redeemed_at timestamptz NOT NULL,
  request_platform_hint text NOT NULL DEFAULT '',
  policy_version text NOT NULL,
  UNIQUE(code_id,subject_type,subject_id,redemption_slot),
  CHECK (subject_type IN ('PLAYER','ACCOUNT','PLAYER_ON_LOGICAL_SERVER','GLOBAL_SINGLE_USE')),
  CHECK (subject_id <> ''),
  CHECK (policy_version <> '')
);

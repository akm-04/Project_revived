-- +goose Up
-- CA6-2: Practice/Alchemy canonical persistence and immutable content foundation.
-- Hero/Pet remain owners of applied Practice actor state. Character Practice owns
-- one permanent player-scoped rank-450 shared ledger and session+actor pending
-- proposal children. Content Registry owns revision-scoped Practice source facts.

ALTER TABLE player_heroes
  ADD COLUMN practice_str smallint NOT NULL DEFAULT 0 CHECK (practice_str BETWEEN 0 AND 200),
  ADD COLUMN practice_int smallint NOT NULL DEFAULT 0 CHECK (practice_int BETWEEN 0 AND 200),
  ADD COLUMN practice_agi smallint NOT NULL DEFAULT 0 CHECK (practice_agi BETWEEN 0 AND 200);

ALTER TABLE player_pets
  ADD COLUMN practice_str smallint NOT NULL DEFAULT 0 CHECK (practice_str BETWEEN 0 AND 200),
  ADD COLUMN practice_int smallint NOT NULL DEFAULT 0 CHECK (practice_int BETWEEN 0 AND 200),
  ADD COLUMN practice_agi smallint NOT NULL DEFAULT 0 CHECK (practice_agi BETWEEN 0 AND 200);

CREATE TABLE player_practice_roots (
  player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
  free_last_consumed_at timestamptz NULL,
  daily_epoch_start_at timestamptz NULL,
  daily_epoch_policy_version text NULL CHECK (daily_epoch_policy_version IS NULL OR btrim(daily_epoch_policy_version) <> ''),
  bless_remaining bigint NOT NULL DEFAULT 0 CHECK (bless_remaining >= 0),
  bless_capacity_at_epoch bigint NOT NULL DEFAULT 0 CHECK (bless_capacity_at_epoch >= 0),
  bless_vip_level_at_epoch bigint NULL CHECK (bless_vip_level_at_epoch IS NULL OR bless_vip_level_at_epoch >= 0),
  bless_privilege_provider_revision text NULL CHECK (bless_privilege_provider_revision IS NULL OR btrim(bless_privilege_provider_revision) <> ''),
  bless_content_revision text NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  base_mana bigint NOT NULL DEFAULT 0 CHECK (base_mana >= 0),
  base_crystal bigint NOT NULL DEFAULT 0 CHECK (base_crystal >= 0),
  state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  CHECK (bless_remaining <= bless_capacity_at_epoch),
  CHECK (
    (daily_epoch_start_at IS NULL AND daily_epoch_policy_version IS NULL AND bless_vip_level_at_epoch IS NULL AND bless_privilege_provider_revision IS NULL AND bless_content_revision IS NULL)
    OR
    (daily_epoch_start_at IS NOT NULL AND daily_epoch_policy_version IS NOT NULL AND bless_vip_level_at_epoch IS NOT NULL AND bless_privilege_provider_revision IS NOT NULL AND bless_content_revision IS NOT NULL)
  )
);

CREATE TABLE player_hero_practice_candidates (
  player_id bigint NOT NULL REFERENCES player_practice_roots(player_id) ON DELETE CASCADE,
  session_id uuid NOT NULL,
  partner_id bigint NOT NULL CHECK (partner_id > 0),
  actor_state_version bigint NOT NULL CHECK (actor_state_version > 0),
  proposed_str smallint NOT NULL CHECK (proposed_str BETWEEN 0 AND 200),
  proposed_int smallint NOT NULL CHECK (proposed_int BETWEEN 0 AND 200),
  proposed_agi smallint NOT NULL CHECK (proposed_agi BETWEEN 0 AND 200),
  generation_operation_id uuid NOT NULL,
  generation_context_id uuid NOT NULL,
  generation_kind text NOT NULL CHECK (generation_kind IN ('MANUAL','TICKET')),
  generation_content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  generation_policy_refs jsonb NOT NULL CHECK (jsonb_typeof(generation_policy_refs)='array'),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_id,session_id,partner_id)
);
CREATE INDEX player_hero_practice_candidates_actor_idx
  ON player_hero_practice_candidates(player_id,partner_id);

CREATE TABLE player_pet_practice_candidates (
  player_id bigint NOT NULL REFERENCES player_practice_roots(player_id) ON DELETE CASCADE,
  session_id uuid NOT NULL,
  pet_id bigint NOT NULL CHECK (pet_id > 0),
  actor_state_version bigint NOT NULL CHECK (actor_state_version > 0),
  proposed_str smallint NOT NULL CHECK (proposed_str BETWEEN 0 AND 200),
  proposed_int smallint NOT NULL CHECK (proposed_int BETWEEN 0 AND 200),
  proposed_agi smallint NOT NULL CHECK (proposed_agi BETWEEN 0 AND 200),
  generation_operation_id uuid NOT NULL,
  generation_context_id uuid NOT NULL,
  generation_kind text NOT NULL CHECK (generation_kind IN ('MANUAL','TICKET')),
  generation_content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  generation_policy_refs jsonb NOT NULL CHECK (jsonb_typeof(generation_policy_refs)='array'),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  PRIMARY KEY(player_id,session_id,pet_id)
);
CREATE INDEX player_pet_practice_candidates_actor_idx
  ON player_pet_practice_candidates(player_id,pet_id);

CREATE TABLE gxb_content_practice_methods (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  method_id smallint NOT NULL CHECK (method_id BETWEEN 1 AND 3),
  currency_type smallint NOT NULL CHECK (currency_type IN (1,2)),
  base_cost bigint NOT NULL CHECK (base_cost >= 0),
  vip_min bigint NOT NULL CHECK (vip_min >= 0),
  PRIMARY KEY(revision_id,method_id)
);

CREATE TABLE gxb_content_practice_locks (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  lock_count smallint NOT NULL CHECK (lock_count BETWEEN 1 AND 3),
  mana_step bigint NOT NULL CHECK (mana_step >= 0),
  crystal_step bigint NOT NULL CHECK (crystal_step >= 0),
  bless_cost bigint NOT NULL CHECK (bless_cost >= 0),
  source_up_limit bigint NOT NULL CHECK (source_up_limit >= 0),
  PRIMARY KEY(revision_id,lock_count)
);

CREATE TABLE gxb_content_practice_vip_bless (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  vip_level smallint NOT NULL CHECK (vip_level BETWEEN 0 AND 15),
  bless_value bigint NOT NULL CHECK (bless_value >= 0),
  PRIMARY KEY(revision_id,vip_level)
);

CREATE TABLE gxb_content_hero_practice_thresholds (
  revision_id text NOT NULL,
  hero_table_id bigint NOT NULL CHECK (hero_table_id > 0),
  ordinal smallint NOT NULL CHECK (ordinal BETWEEN 1 AND 3),
  need_value bigint NOT NULL CHECK (need_value >= 0),
  target_attr_type bigint NOT NULL CHECK (target_attr_type >= 0),
  bonus_value bigint NOT NULL CHECK (bonus_value >= 0),
  PRIMARY KEY(revision_id,hero_table_id,ordinal),
  FOREIGN KEY(revision_id,hero_table_id)
    REFERENCES gxb_content_hero_templates(revision_id,table_id) ON DELETE RESTRICT
);

CREATE TABLE gxb_content_pet_practice_thresholds (
  revision_id text NOT NULL,
  pet_table_id bigint NOT NULL CHECK (pet_table_id > 0),
  ordinal smallint NOT NULL CHECK (ordinal BETWEEN 1 AND 3),
  need_value bigint NOT NULL CHECK (need_value >= 0),
  target_attr_type bigint NOT NULL CHECK (target_attr_type >= 0),
  bonus_value bigint NOT NULL CHECK (bonus_value >= 0),
  PRIMARY KEY(revision_id,pet_table_id,ordinal),
  FOREIGN KEY(revision_id,pet_table_id)
    REFERENCES gxb_content_pet_templates(revision_id,table_id) ON DELETE RESTRICT
);

CREATE TABLE gxb_content_practice_policy_facts (
  revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  unlock_level bigint NOT NULL CHECK (unlock_level > 0),
  attr_cap bigint NOT NULL CHECK (attr_cap > 0),
  free_interval_seconds bigint NOT NULL CHECK (free_interval_seconds > 0),
  legendary_vip_min bigint NOT NULL CHECK (legendary_vip_min >= 0),
  ticket_item_id bigint NOT NULL CHECK (ticket_item_id > 0),
  ticket_add_str smallint NOT NULL CHECK (ticket_add_str >= 0),
  ticket_add_int smallint NOT NULL CHECK (ticket_add_int >= 0),
  ticket_add_agi smallint NOT NULL CHECK (ticket_add_agi >= 0)
);

-- Existing V2 players gain infrastructure only. No historical Practice state,
-- free-entitlement consumption, daily epoch, Bless capacity, base ledger or
-- pending proposal is fabricated.
INSERT INTO player_practice_roots(
  player_id,bless_remaining,bless_capacity_at_epoch,base_mana,base_crystal,
  state_version,created_at,updated_at
)
SELECT player_id,0,0,0,0,1,transaction_timestamp(),transaction_timestamp()
FROM players
ON CONFLICT (player_id) DO NOTHING;

-- Forward-only by project law. Rollback is restore/redeploy.

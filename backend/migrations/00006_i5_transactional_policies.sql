-- +goose Up
-- Pass446-Pass447 / I5: versioned source-backed policy registries needed by the
-- transactional Grant and Objective services. These rows describe compatibility
-- and content policy; player balances and progress remain in their owner tables.

CREATE TABLE i5_resource_registry (
  registry_key text PRIMARY KEY,
  class text NOT NULL CHECK (class IN ('SCALAR_CURRENCY','TEMPORAL','STACK_ITEM')),
  resource_key text NULL,
  item_id bigint NULL CHECK (item_id IS NULL OR item_id > 0),
  wire_table_id bigint NULL CHECK (wire_table_id IS NULL OR wire_table_id > 0),
  stack_cap bigint NULL CHECK (stack_cap IS NULL OR stack_cap > 0),
  overflow_to_mail boolean NOT NULL DEFAULT false,
  temporal_regen_seconds bigint NULL CHECK (temporal_regen_seconds IS NULL OR temporal_regen_seconds > 0),
  temporal_regen_amount bigint NULL CHECK (temporal_regen_amount IS NULL OR temporal_regen_amount > 0),
  temporal_natural_cap bigint NULL CHECK (temporal_natural_cap IS NULL OR temporal_natural_cap >= 0),
  temporal_allow_explicit_above_cap boolean NOT NULL DEFAULT false,
  policy_version text NOT NULL,
  source_evidence text NOT NULL,
  active boolean NOT NULL DEFAULT true,
  CHECK (registry_key <> ''),
  CHECK (policy_version <> ''),
  CHECK (source_evidence <> ''),
  CHECK ((class='STACK_ITEM') = (item_id IS NOT NULL)),
  CHECK ((class IN ('SCALAR_CURRENCY','TEMPORAL')) = (resource_key IS NOT NULL)),
  CHECK ((class='STACK_ITEM') = (stack_cap IS NOT NULL)),
  CHECK ((class='TEMPORAL') = (temporal_regen_seconds IS NOT NULL)),
  CHECK ((class='TEMPORAL') = (temporal_regen_amount IS NOT NULL)),
  CHECK ((class='TEMPORAL') = (temporal_natural_cap IS NOT NULL))
);
CREATE UNIQUE INDEX i5_resource_registry_resource_uq
  ON i5_resource_registry(class,resource_key) WHERE resource_key IS NOT NULL;
CREATE UNIQUE INDEX i5_resource_registry_item_uq
  ON i5_resource_registry(item_id) WHERE item_id IS NOT NULL;

CREATE TABLE objective_definitions (
  program_id text NOT NULL,
  stock_family bigint NOT NULL CHECK (stock_family BETWEEN 1 AND 7),
  objective_id bigint NOT NULL CHECK (objective_id > 0),
  definition_revision text NOT NULL,
  strategy text NOT NULL CHECK (strategy IN ('HIGH_WATER','COMMITTED_DELTA','TEMPORAL_ENTITLEMENT','DOMAIN_VALIDATED')),
  accepted_fact_kind text NOT NULL,
  target bigint NOT NULL CHECK (target > 0),
  generation_kind text NOT NULL DEFAULT 'STATIC',
  prerequisite_policy jsonb NOT NULL DEFAULT '{}'::jsonb,
  reward_plan jsonb NOT NULL,
  huoyue bigint NOT NULL DEFAULT 0 CHECK (huoyue >= 0),
  presentation jsonb NOT NULL DEFAULT '{}'::jsonb,
  content_policy_version text NOT NULL,
  active boolean NOT NULL DEFAULT true,
  PRIMARY KEY(program_id,objective_id,definition_revision),
  CHECK (program_id <> ''),
  CHECK (definition_revision <> ''),
  CHECK (accepted_fact_kind <> ''),
  CHECK (generation_kind <> ''),
  CHECK (content_policy_version <> '')
);
CREATE INDEX objective_definitions_family_active_idx
  ON objective_definitions(stock_family,active,objective_id);

-- Stock MID230 has no request nonce/slot. A retry is indistinguishable from an
-- intentional second use of the same public code by the same subject. V2 thus
-- permits only slot 1 through the stock route. Operator/API tooling in I11 may
-- issue multiple distinct generated codes when multiple entitlements are wanted.
ALTER TABLE redeem_redemptions
  ADD CONSTRAINT redeem_stock_slot_positive CHECK (redemption_slot >= 1);

-- Production migrations are forward-only by project law; rollback is restore.

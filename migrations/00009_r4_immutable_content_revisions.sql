-- +goose Up
-- R4B: expand-compatible immutable content revisions and durable operation-policy evidence.
-- This migration changes storage only. R4C owns content installation/activation and
-- R4D owns operation-time pinning/legacy exact-version behavior.

CREATE TABLE gxb_content_revisions (
  revision_id text PRIMARY KEY CHECK (revision_id ~ '^[0-9a-f]{64}$'),
  content_sha256 bytea NOT NULL UNIQUE CHECK (octet_length(content_sha256)=32),
  schema_version integer NOT NULL CHECK (schema_version > 0),
  compiler_version text NOT NULL CHECK (btrim(compiler_version) <> ''),
  parser_version text NOT NULL CHECK (btrim(parser_version) <> ''),
  manifest jsonb NOT NULL CHECK (jsonb_typeof(manifest)='object'),
  installed_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  CHECK (revision_id = encode(content_sha256,'hex')),
  CHECK (manifest ? 'revision_id' AND manifest->>'revision_id' = revision_id),
  CHECK (manifest ? 'schema_version' AND manifest->>'schema_version' = schema_version::text),
  CHECK (manifest ? 'compiler_version' AND manifest->>'compiler_version' = compiler_version),
  CHECK (manifest ? 'parser_version' AND manifest->>'parser_version' = parser_version)
);

CREATE TABLE gxb_content_activation (
  slot text PRIMARY KEY CHECK (slot='content'),
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  activation_version bigint NOT NULL CHECK (activation_version > 0),
  activated_at timestamptz NOT NULL,
  activated_by text NOT NULL CHECK (btrim(activated_by) <> '')
);

CREATE TABLE gxb_content_resource_definitions (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  definition_key text NOT NULL CHECK (btrim(definition_key) <> ''),
  class text NOT NULL CHECK (class IN ('SCALAR_CURRENCY','TEMPORAL','STACK_ITEM','PLAYER_EXP','SPECIALIZED_DOMAIN')),
  catalog_status text NOT NULL CHECK (catalog_status IN ('QUALIFIED','SOURCE_KNOWN','PARTIAL')),
  settlement_activation text NOT NULL CHECK (settlement_activation IN ('ENABLED_R4','OWNER_REQUIRED','R5_REQUIRED','FAIL_CLOSED')),
  resource_key text NULL CHECK (resource_key IS NULL OR btrim(resource_key) <> ''),
  item_id bigint NULL CHECK (item_id IS NULL OR item_id > 0),
  source_asset_id bigint NULL,
  item_type bigint NULL CHECK (item_type IS NULL OR item_type >= 0),
  partner_id bigint NULL CHECK (partner_id IS NULL OR partner_id > 0),
  stack_cap bigint NULL CHECK (stack_cap IS NULL OR stack_cap > 0),
  overflow_to_mail boolean NULL,
  regen_seconds bigint NULL CHECK (regen_seconds IS NULL OR regen_seconds > 0),
  regen_amount bigint NULL CHECK (regen_amount IS NULL OR regen_amount > 0),
  cap_rule text NULL CHECK (cap_rule IS NULL OR cap_rule IN ('STATIC','PLAYER_LEVEL_ENERGY','VIP_PLUS_MONTHLY_PRIVILEGE','UNRESOLVED')),
  static_cap bigint NULL CHECK (static_cap IS NULL OR static_cap >= 0),
  specialized_owner text NULL CHECK (specialized_owner IS NULL OR btrim(specialized_owner) <> ''),
  reason text NULL CHECK (reason IS NULL OR btrim(reason) <> ''),
  PRIMARY KEY(revision_id,definition_key),
  CHECK (
    (class IN ('SCALAR_CURRENCY','PLAYER_EXP') AND resource_key IS NOT NULL AND item_id IS NULL AND item_type IS NULL AND partner_id IS NULL AND stack_cap IS NULL AND overflow_to_mail IS NULL AND regen_seconds IS NULL AND regen_amount IS NULL AND cap_rule IS NULL AND static_cap IS NULL AND specialized_owner IS NULL)
    OR
    (class='TEMPORAL' AND resource_key IS NOT NULL AND item_id IS NULL AND item_type IS NULL AND partner_id IS NULL AND stack_cap IS NULL AND overflow_to_mail IS NULL AND regen_seconds IS NOT NULL AND regen_amount IS NOT NULL AND cap_rule IS NOT NULL AND specialized_owner IS NULL AND ((cap_rule='STATIC' AND static_cap IS NOT NULL) OR (cap_rule<>'STATIC' AND static_cap IS NULL)))
    OR
    (class='STACK_ITEM' AND resource_key IS NULL AND item_id IS NOT NULL AND item_type IS NOT NULL AND stack_cap IS NOT NULL AND overflow_to_mail IS NOT NULL AND regen_seconds IS NULL AND regen_amount IS NULL AND cap_rule IS NULL AND static_cap IS NULL AND specialized_owner IS NULL)
    OR
    (class='SPECIALIZED_DOMAIN' AND resource_key IS NULL AND item_id IS NOT NULL AND item_type IS NOT NULL AND partner_id IS NULL AND stack_cap IS NOT NULL AND overflow_to_mail IS NOT NULL AND regen_seconds IS NULL AND regen_amount IS NULL AND cap_rule IS NULL AND static_cap IS NULL AND specialized_owner IS NOT NULL)
  )
);
CREATE UNIQUE INDEX gxb_content_resource_definitions_resource_uq
  ON gxb_content_resource_definitions(revision_id,class,resource_key) WHERE resource_key IS NOT NULL;
CREATE UNIQUE INDEX gxb_content_resource_definitions_item_uq
  ON gxb_content_resource_definitions(revision_id,item_id) WHERE item_id IS NOT NULL;

CREATE TABLE gxb_content_player_progression (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  level bigint NOT NULL CHECK (level > 0),
  max_energy bigint NOT NULL CHECK (max_energy >= 0),
  exp_delta bigint NOT NULL CHECK (exp_delta >= 0),
  award_energy bigint NOT NULL CHECK (award_energy >= 0),
  total_exp bigint NOT NULL CHECK (total_exp >= 0),
  hero_max_level bigint NOT NULL CHECK (hero_max_level > 0),
  power bigint NOT NULL CHECK (power >= 0),
  expedition_mana bigint NOT NULL CHECK (expedition_mana >= 0),
  PRIMARY KEY(revision_id,level)
);

CREATE TABLE gxb_content_objective_definitions (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  program_id text NOT NULL CHECK (btrim(program_id) <> ''),
  stock_family bigint NOT NULL CHECK (stock_family BETWEEN 1 AND 7),
  objective_id bigint NOT NULL CHECK (objective_id > 0),
  definition_revision text NOT NULL CHECK (btrim(definition_revision) <> ''),
  strategy text NOT NULL CHECK (strategy IN ('HIGH_WATER','COMMITTED_DELTA','TEMPORAL_ENTITLEMENT','DOMAIN_VALIDATED')),
  accepted_fact_kind text NOT NULL CHECK (btrim(accepted_fact_kind) <> ''),
  target bigint NOT NULL CHECK (target > 0),
  generation_kind text NOT NULL DEFAULT 'STATIC' CHECK (btrim(generation_kind) <> ''),
  prerequisite_policy jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(prerequisite_policy)='object'),
  reward_plan jsonb NOT NULL CHECK (jsonb_typeof(reward_plan)='object'),
  huoyue bigint NOT NULL DEFAULT 0 CHECK (huoyue >= 0),
  presentation jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(presentation)='object'),
  PRIMARY KEY(revision_id,program_id,objective_id,definition_revision)
);

-- Expand-compatible receipt evidence. Pass468 inserts omit this column and
-- receive the empty policy set; R4B+ writes it explicitly through the kernel owner.
ALTER TABLE gxb_operation_receipts
  ADD COLUMN operation_policy_refs jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD CONSTRAINT gxb_operation_receipts_policy_refs_array_chk CHECK (jsonb_typeof(operation_policy_refs)='array');

-- NULL deliberately means legacy exact-version resolution, never "current".
ALTER TABLE player_temporal_resources
  ADD COLUMN content_revision text NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT;

ALTER TABLE player_mission_instances
  ADD COLUMN content_revision text NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT;

-- Production migrations are forward-only by project law; rollback is restore/redeploy.

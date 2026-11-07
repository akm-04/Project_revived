-- +goose Up
-- owner: socialrecall
CREATE TABLE social_recall_tasks (
 operation_id uuid PRIMARY KEY,
 caller_player_id bigint NOT NULL CHECK(caller_player_id > 0),
 target_player_id bigint NOT NULL CHECK(target_player_id > 0 AND target_player_id <> caller_player_id),
 logical_server_id integer NOT NULL CHECK(logical_server_id > 0),
 content_revision text NOT NULL CHECK(content_revision ~ '^[0-9a-f]{64}$'),
 policy_version text NOT NULL CHECK(length(policy_version) > 0),
 started_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL CHECK(expires_at > started_at),
 status text NOT NULL CHECK(status IN ('ACTIVE','COMPLETED','EXPIRED')),
 completed_at timestamptz,
 baseline_academy_level bigint NOT NULL CHECK(baseline_academy_level >= 0),
 baseline_owned_hero_count bigint NOT NULL CHECK(baseline_owned_hero_count >= 0),
 baseline_charge_total bigint NOT NULL CHECK(baseline_charge_total >= 0),
 state_version bigint NOT NULL CHECK(state_version > 0),
 updated_at timestamptz NOT NULL CHECK(updated_at >= started_at),
 CHECK(caller_player_id / 100000 = logical_server_id AND target_player_id / 100000 = logical_server_id),
 CHECK((status='COMPLETED' AND completed_at IS NOT NULL AND completed_at >= started_at AND completed_at < expires_at) OR (status <> 'COMPLETED' AND completed_at IS NULL))
);
CREATE UNIQUE INDEX social_recall_active_target ON social_recall_tasks(target_player_id) WHERE status='ACTIVE';
CREATE UNIQUE INDEX social_recall_completed_pair ON social_recall_tasks(caller_player_id,target_player_id) WHERE status='COMPLETED';
CREATE INDEX social_recall_active_caller ON social_recall_tasks(caller_player_id,expires_at) WHERE status='ACTIVE';

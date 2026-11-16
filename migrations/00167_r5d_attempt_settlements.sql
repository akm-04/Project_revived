-- +goose Up
-- owner: worldboss
-- R5D shared combat attempt record: the world boss's credited damage after its
-- RESULT, one append-only row per settled Combat attempt keyed by that attempt.
-- The old text-keyed worldboss_attempts table retires later; these rows never
-- say open, they only exist once the attempt is terminal.
CREATE TABLE worldboss_attempt_settlements (
 attempt_id uuid PRIMARY KEY REFERENCES combat_attempts(attempt_id),
 player_id bigint NOT NULL,
 damage bigint NOT NULL CHECK(damage>=0),
 settled_at timestamptz NOT NULL
);
CREATE INDEX worldboss_attempt_settlements_player_idx ON worldboss_attempt_settlements(player_id);
CREATE TRIGGER worldboss_attempt_settlements_append_only BEFORE UPDATE OR DELETE ON worldboss_attempt_settlements FOR EACH ROW EXECUTE FUNCTION combat_append_only();
-- owner: illusion
-- The illusion mode's credited damage, the same shape and append-only rule.
CREATE TABLE illusion_attempt_settlements (
 attempt_id uuid PRIMARY KEY REFERENCES combat_attempts(attempt_id),
 player_id bigint NOT NULL,
 damage bigint NOT NULL CHECK(damage>=0),
 settled_at timestamptz NOT NULL
);
CREATE INDEX illusion_attempt_settlements_player_idx ON illusion_attempt_settlements(player_id);
CREATE TRIGGER illusion_attempt_settlements_append_only BEFORE UPDATE OR DELETE ON illusion_attempt_settlements FOR EACH ROW EXECUTE FUNCTION combat_append_only();
-- owner: adventure
-- The adventure mode's credited damage, the same shape and append-only rule.
CREATE TABLE adventure_attempt_settlements (
 attempt_id uuid PRIMARY KEY REFERENCES combat_attempts(attempt_id),
 player_id bigint NOT NULL,
 damage bigint NOT NULL CHECK(damage>=0),
 settled_at timestamptz NOT NULL
);
CREATE INDEX adventure_attempt_settlements_player_idx ON adventure_attempt_settlements(player_id);
CREATE TRIGGER adventure_attempt_settlements_append_only BEFORE UPDATE OR DELETE ON adventure_attempt_settlements FOR EACH ROW EXECUTE FUNCTION combat_append_only();

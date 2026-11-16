-- +goose Up
-- owner: operator control (I11A)
-- AC397-25: privileged operator mutations are attributable after restart.
-- OPERATIONAL audit data, not a player table. R8 adds the retention rule.
CREATE TABLE operator_audit_events(
 id bigserial PRIMARY KEY,
 occurred_at timestamptz NOT NULL,
 actor_kind text NOT NULL CHECK(actor_kind <> ''),
 actor_id text NOT NULL CHECK(actor_id <> ''),
 action text NOT NULL CHECK(action <> ''),
 target_kind text NOT NULL,
 target_key text NOT NULL,
 outcome text NOT NULL CHECK(outcome <> ''),
 reason_code text NOT NULL DEFAULT '',
 correlation_id text NOT NULL DEFAULT '',
 policy_version text NOT NULL DEFAULT '',
 recorded_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX operator_audit_events_recorded_idx ON operator_audit_events(recorded_at);
-- +goose StatementBegin
CREATE FUNCTION operator_audit_events_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 RAISE EXCEPTION 'operator_audit_events is append-only: % refused', TG_OP;
END $$;
-- +goose StatementEnd
CREATE TRIGGER operator_audit_events_append_only BEFORE UPDATE OR DELETE ON operator_audit_events FOR EACH ROW EXECUTE FUNCTION operator_audit_events_append_only();

-- +goose Up
-- owner: Combat
-- C5A_COMBAT_INPUT_ATTEMPT_RESULT_FOUNDATION_V1. Empty on upgrade; no mode,
-- reward or ranking state. Snapshots, resolutions and report blobs are
-- append-only; an attempt row never changes its frozen identity.
CREATE TABLE combat_locator_roots (
 domain_kind text NOT NULL CHECK(length(domain_kind) BETWEEN 1 AND 128),
 authority_scope text NOT NULL CHECK(length(authority_scope) BETWEEN 1 AND 256),
 domain_locator text NOT NULL CHECK(length(domain_locator) BETWEEN 1 AND 512),
 PRIMARY KEY(domain_kind,authority_scope,domain_locator)
);
CREATE TABLE combat_snapshots (
 snapshot_hash text PRIMARY KEY CHECK(snapshot_hash ~ '^[0-9a-f]{64}$'),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 rules_corpus_id text NOT NULL CHECK(rules_corpus_id ~ '^[0-9a-f]{64}$'),
 canonical bytea NOT NULL CHECK(octet_length(canonical) BETWEEN 2 AND 8388608)
);
CREATE TABLE combat_report_blobs (
 report_sha256 text PRIMARY KEY CHECK(report_sha256 ~ '^[0-9a-f]{64}$'),
 encoding text NOT NULL CHECK(length(encoding)>0),
 byte_length bigint NOT NULL CHECK(byte_length>0),
 report bytea NOT NULL,
 CHECK(octet_length(report)=byte_length)
);
CREATE TABLE combat_resolutions (
 resolution_hash text PRIMARY KEY CHECK(resolution_hash ~ '^[0-9a-f]{64}$'),
 attempt_id uuid NOT NULL UNIQUE,
 report_sha256 text NOT NULL REFERENCES combat_report_blobs(report_sha256),
 canonical bytea NOT NULL CHECK(octet_length(canonical)>0)
);
CREATE TABLE combat_attempts (
 attempt_id uuid PRIMARY KEY,
 domain_kind text NOT NULL,
 authority_scope text NOT NULL,
 domain_locator text NOT NULL,
 actor_player_id bigint NOT NULL REFERENCES players(player_id),
 gameplay_context_id uuid NOT NULL,
 generation_ref text NOT NULL CHECK(length(generation_ref) BETWEEN 1 AND 256),
 start_fingerprint text NOT NULL CHECK(start_fingerprint ~ '^[0-9a-f]{64}$'),
 trust_profile_id text NOT NULL CHECK(trust_profile_id='SERVER_REPORT_AUTHORITATIVE_V1'),
 trust_profile_version integer NOT NULL CHECK(trust_profile_version=1),
 snapshot_hash text NOT NULL REFERENCES combat_snapshots(snapshot_hash),
 rules_corpus_version text NOT NULL CHECK(rules_corpus_version ~ '^[0-9a-f]{64}$'),
 entropy_policy_version text NOT NULL CHECK(entropy_policy_version='HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1'),
 entropy_key_version text NOT NULL CHECK(length(entropy_key_version) BETWEEN 1 AND 64),
 resolver_status text NOT NULL CHECK(resolver_status IN ('PENDING','READY','RETRYABLE_FAILED','PERMANENT_FAILED')),
 resolver_failure text CHECK(resolver_failure IS NULL OR length(resolver_failure) BETWEEN 1 AND 512),
 state text NOT NULL CHECK(state IN ('STAGED','RESOLUTION_READY','TERMINAL')),
 started_at timestamptz NOT NULL,
 result_deadline timestamptz NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 resolution_hash text REFERENCES combat_resolutions(resolution_hash),
 terminal_kind text CHECK(terminal_kind IS NULL OR length(terminal_kind) BETWEEN 1 AND 128),
 terminal_at timestamptz,
 semantic_receipt_id text CHECK(semantic_receipt_id IS NULL OR length(semantic_receipt_id) BETWEEN 1 AND 256),
 FOREIGN KEY(domain_kind,authority_scope,domain_locator) REFERENCES combat_locator_roots(domain_kind,authority_scope,domain_locator),
 CHECK(result_deadline>started_at),
 CHECK((state='STAGED')=(resolution_hash IS NULL)),
 CHECK((state='STAGED')=(resolver_status<>'READY')),
 CHECK((state='TERMINAL')=(terminal_kind IS NOT NULL AND terminal_at IS NOT NULL AND semantic_receipt_id IS NOT NULL)),
 CHECK(state='TERMINAL' OR (terminal_kind IS NULL AND terminal_at IS NULL AND semantic_receipt_id IS NULL))
);
CREATE UNIQUE INDEX combat_attempts_one_unresolved ON combat_attempts(domain_kind,authority_scope,domain_locator) WHERE state<>'TERMINAL';
CREATE UNIQUE INDEX combat_attempts_terminal_receipt ON combat_attempts(domain_kind,authority_scope,domain_locator,semantic_receipt_id) WHERE state='TERMINAL';
-- +goose StatementBegin
CREATE FUNCTION combat_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 RAISE EXCEPTION 'combat: % rows are immutable', TG_TABLE_NAME;
END $$;
-- +goose StatementEnd
CREATE TRIGGER combat_snapshots_append_only BEFORE UPDATE OR DELETE ON combat_snapshots FOR EACH ROW EXECUTE FUNCTION combat_append_only();
CREATE TRIGGER combat_report_blobs_append_only BEFORE UPDATE OR DELETE ON combat_report_blobs FOR EACH ROW EXECUTE FUNCTION combat_append_only();
CREATE TRIGGER combat_resolutions_append_only BEFORE UPDATE OR DELETE ON combat_resolutions FOR EACH ROW EXECUTE FUNCTION combat_append_only();
-- +goose StatementBegin
CREATE FUNCTION combat_attempt_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='DELETE' OR OLD.state='TERMINAL' OR NEW.state_version<>OLD.state_version+1
  OR (OLD.state='RESOLUTION_READY' AND NEW.state='STAGED')
  OR (OLD.resolution_hash IS NOT NULL AND NEW.resolution_hash IS DISTINCT FROM OLD.resolution_hash)
  OR (NEW.attempt_id,NEW.domain_kind,NEW.authority_scope,NEW.domain_locator,NEW.actor_player_id,NEW.gameplay_context_id,NEW.generation_ref,NEW.start_fingerprint,NEW.snapshot_hash,NEW.rules_corpus_version,NEW.entropy_key_version,NEW.started_at,NEW.result_deadline)
     IS DISTINCT FROM (OLD.attempt_id,OLD.domain_kind,OLD.authority_scope,OLD.domain_locator,OLD.actor_player_id,OLD.gameplay_context_id,OLD.generation_ref,OLD.start_fingerprint,OLD.snapshot_hash,OLD.rules_corpus_version,OLD.entropy_key_version,OLD.started_at,OLD.result_deadline) THEN
  RAISE EXCEPTION 'combat: attempt % transition refused', OLD.attempt_id;
 END IF;
 RETURN NEW;
END $$;
-- +goose StatementEnd
CREATE TRIGGER combat_attempts_guard BEFORE UPDATE OR DELETE ON combat_attempts FOR EACH ROW EXECUTE FUNCTION combat_attempt_guard();

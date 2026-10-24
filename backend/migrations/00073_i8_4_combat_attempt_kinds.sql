-- +goose Up
-- owner: Combat
-- I8-4 attempt kinds over the I7C-5A envelope (PASS748): the registered trust
-- profiles, NOT_REQUIRED resolution for client-run attempts, the family's
-- pinned duplicate-terminal answer (PASS418 FightExist), the supersede chain
-- (PASS120), START packages and attestations. Existing attempts keep their
-- rows and become server-report attempts answering a duplicate with the stored
-- report; the defaults keep that true for a rolled-back product writing here.
-- Every new record is attempt-scoped under the rank-609 locator fence.
ALTER TABLE combat_attempts DROP CONSTRAINT combat_attempts_trust_profile_id_check;
ALTER TABLE combat_attempts ADD CONSTRAINT combat_attempts_trust_profile_id_check CHECK(trust_profile_id IN ('SERVER_REPORT_AUTHORITATIVE_V1','CLIENT_SUMMARY_ATTESTED_V1','CLIENT_FULL_REPORT_ATTESTED_V1','SERVER_ENTROPY_CLIENT_DERIVED_V1','PRACTICE_NO_VALUE_V1'));
ALTER TABLE combat_attempts DROP CONSTRAINT combat_attempts_resolver_status_check;
ALTER TABLE combat_attempts ADD CONSTRAINT combat_attempts_resolver_status_check CHECK(resolver_status IN ('PENDING','READY','RETRYABLE_FAILED','PERMANENT_FAILED','NOT_REQUIRED'));
ALTER TABLE combat_attempts ADD CONSTRAINT combat_attempts_server_resolution CHECK((trust_profile_id='SERVER_REPORT_AUTHORITATIVE_V1')=(resolver_status<>'NOT_REQUIRED'));
ALTER TABLE combat_attempts
 ADD COLUMN replay_response text NOT NULL DEFAULT 'STORED_REPORT' CHECK(replay_response IN ('OK','FIGHT_EXIST','CURRENT_PROJECTION','STORED_REPORT','SEMANTIC_ERROR')),
 ADD COLUMN replay_error_code integer NOT NULL DEFAULT 0 CHECK(replay_error_code>=0),
 ADD COLUMN supersedes_attempt_id uuid UNIQUE REFERENCES combat_attempts(attempt_id),
 ADD CONSTRAINT combat_attempts_replay_code CHECK((replay_response IN ('FIGHT_EXIST','SEMANTIC_ERROR'))=(replay_error_code>0)),
 ADD CONSTRAINT combat_attempts_replay_report CHECK(replay_response<>'STORED_REPORT' OR resolver_status<>'NOT_REQUIRED'),
 ADD CONSTRAINT combat_attempts_supersede_chain CHECK(supersedes_attempt_id IS NULL OR (supersedes_attempt_id<>attempt_id AND trust_profile_id<>'SERVER_REPORT_AUTHORITATIVE_V1')),
 ADD CONSTRAINT combat_attempts_superseded_kind CHECK(terminal_kind IS DISTINCT FROM 'SUPERSEDED' OR trust_profile_id<>'SERVER_REPORT_AUTHORITATIVE_V1');
CREATE TABLE combat_start_packages (
 attempt_id uuid PRIMARY KEY REFERENCES combat_attempts(attempt_id),
 package_policy text NOT NULL CHECK(package_policy='HMAC_SHA256_COUNTER_START_PACKAGE_V1'),
 package_sha256 text NOT NULL CHECK(package_sha256 ~ '^[0-9a-f]{64}$'),
 draws bigint NOT NULL CHECK(draws>=0),
 canonical bytea NOT NULL CHECK(octet_length(canonical) BETWEEN 1 AND 1048576)
);
CREATE TABLE combat_attestations (
 attempt_id uuid PRIMARY KEY REFERENCES combat_attempts(attempt_id),
 validator_id text NOT NULL CHECK(validator_id ~ '^[A-Z][A-Z0-9_]*_V[1-9][0-9]*$'),
 validator_version integer NOT NULL CHECK(validator_version>0),
 verdict text NOT NULL CHECK(verdict IN ('ACCEPTED','REJECTED')),
 summary_sha256 text NOT NULL CHECK(summary_sha256 ~ '^[0-9a-f]{64}$'),
 summary bytea NOT NULL CHECK(octet_length(summary) BETWEEN 2 AND 1048576),
 recorded_at timestamptz NOT NULL
);
CREATE TRIGGER combat_start_packages_append_only BEFORE UPDATE OR DELETE ON combat_start_packages FOR EACH ROW EXECUTE FUNCTION combat_append_only();
CREATE TRIGGER combat_attestations_append_only BEFORE UPDATE OR DELETE ON combat_attestations FOR EACH ROW EXECUTE FUNCTION combat_append_only();
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION combat_attempt_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='DELETE' OR OLD.state='TERMINAL' OR NEW.state_version<>OLD.state_version+1
  OR (OLD.state='RESOLUTION_READY' AND NEW.state='STAGED')
  OR (OLD.resolution_hash IS NOT NULL AND NEW.resolution_hash IS DISTINCT FROM OLD.resolution_hash)
  OR ((OLD.resolver_status='NOT_REQUIRED')<>(NEW.resolver_status='NOT_REQUIRED'))
  OR (NEW.attempt_id,NEW.domain_kind,NEW.authority_scope,NEW.domain_locator,NEW.actor_player_id,NEW.gameplay_context_id,NEW.generation_ref,NEW.start_fingerprint,NEW.snapshot_hash,NEW.rules_corpus_version,NEW.entropy_key_version,NEW.started_at,NEW.result_deadline,
      NEW.trust_profile_id,NEW.trust_profile_version,NEW.entropy_policy_version,NEW.replay_response,NEW.replay_error_code,NEW.supersedes_attempt_id)
     IS DISTINCT FROM (OLD.attempt_id,OLD.domain_kind,OLD.authority_scope,OLD.domain_locator,OLD.actor_player_id,OLD.gameplay_context_id,OLD.generation_ref,OLD.start_fingerprint,OLD.snapshot_hash,OLD.rules_corpus_version,OLD.entropy_key_version,OLD.started_at,OLD.result_deadline,
      OLD.trust_profile_id,OLD.trust_profile_version,OLD.entropy_policy_version,OLD.replay_response,OLD.replay_error_code,OLD.supersedes_attempt_id) THEN
  RAISE EXCEPTION 'combat: attempt % transition refused', OLD.attempt_id;
 END IF;
 RETURN NEW;
END $$;
-- +goose StatementEnd

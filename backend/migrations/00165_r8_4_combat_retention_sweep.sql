-- +goose Up
-- owner: R8 retention (R8_PLAYER_DATA_DESIGN U4, R8_4_RETENTION_TASKS Amendment 1 A)
-- Combat rows stay immutable: every UPDATE still raises. A DELETE passes only
-- inside the retention sweep (its transaction sets gxb.retention_sweep to on),
-- and an attempt additionally has to be TERMINAL. No Down section (PASS628).
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION combat_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='DELETE' AND current_setting('gxb.retention_sweep', true) = 'on' THEN
  RETURN OLD;
 END IF;
 RAISE EXCEPTION 'combat: % rows are immutable', TG_TABLE_NAME;
END $$;
-- +goose StatementEnd
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION combat_attempt_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='DELETE' THEN
  IF current_setting('gxb.retention_sweep', true) = 'on' AND OLD.state='TERMINAL' THEN
   RETURN OLD;
  END IF;
  RAISE EXCEPTION 'combat: attempt % transition refused', OLD.attempt_id;
 END IF;
 IF OLD.state='TERMINAL' OR NEW.state_version<>OLD.state_version+1
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

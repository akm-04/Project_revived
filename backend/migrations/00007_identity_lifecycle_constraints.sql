-- +goose Up
-- R2A: express identity relationships already frozen by Wave-C. This migration
-- adds no new product policy and remains forward-only.

CREATE UNIQUE INDEX account_sessions_session_account_uq
  ON account_sessions(session_id, account_id);

CREATE UNIQUE INDEX players_player_account_server_uq
  ON players(player_id, account_id, logical_server_id);

CREATE UNIQUE INDEX gameplay_contexts_context_session_uq
  ON gameplay_contexts(context_id, session_id);

ALTER TABLE accounts
  ADD CONSTRAINT accounts_status_disabled_at_consistent_chk CHECK (
    (status='ACTIVE' AND disabled_at IS NULL)
    OR (status='DISABLED' AND disabled_at IS NOT NULL)
  );

ALTER TABLE account_sessions
  ADD CONSTRAINT account_sessions_revocation_consistent_chk CHECK (
    (revoked_at IS NULL AND revocation_reason IS NULL)
    OR (revoked_at IS NOT NULL AND revocation_reason IS NOT NULL AND btrim(revocation_reason) <> '')
  );

ALTER TABLE gameplay_contexts
  ADD CONSTRAINT gameplay_contexts_end_consistent_chk CHECK (
    (ended_at IS NULL AND end_reason IS NULL)
    OR (ended_at IS NOT NULL AND end_reason IS NOT NULL AND btrim(end_reason) <> '')
  );

ALTER TABLE gameplay_contexts
  ADD CONSTRAINT gameplay_context_session_account_fk
  FOREIGN KEY(session_id, account_id)
  REFERENCES account_sessions(session_id, account_id);

ALTER TABLE gameplay_contexts
  ADD CONSTRAINT gameplay_context_player_account_server_fk
  FOREIGN KEY(player_id, account_id, logical_server_id)
  REFERENCES players(player_id, account_id, logical_server_id);

ALTER TABLE gameplay_context_credentials
  ADD CONSTRAINT gameplay_context_credential_parent_fk
  FOREIGN KEY(context_id, session_id)
  REFERENCES gameplay_contexts(context_id, session_id);

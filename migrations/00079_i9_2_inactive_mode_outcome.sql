-- +goose Up
-- owner: ClientLog
-- I9-2 MF2 (I9_MODE_FRAMEWORK_V1 F5, D83): a request answered by the shared inactive mode dispatcher journals INACTIVE_MODE.
ALTER TABLE request_journal DROP CONSTRAINT request_journal_outcome_check;
ALTER TABLE request_journal ADD CONSTRAINT request_journal_outcome_check
  CHECK (outcome IN ('OK','CLIENT_ERROR','SERVER_ERROR','UNKNOWN_MID','UNDECODABLE','INACTIVE_MODE'));

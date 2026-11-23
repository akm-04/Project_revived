-- +goose Up
-- owner: identity/logicalserver/bootstrap (account_sessions idle expiry)
UPDATE account_sessions SET idle_timeout_seconds = 86400
WHERE revoked_at IS NULL AND idle_timeout_seconds IS NULL;
CREATE INDEX account_sessions_idle_expiry_idx ON account_sessions(last_activity_at)
WHERE revoked_at IS NULL AND idle_timeout_seconds IS NOT NULL;

-- +goose Up
-- owner: mail
-- I9-10 D468: both mail lifetimes are tunable. One row; absent or rejected keeps
-- the built-in 3600 s overflow / 604800 s ordinary durations (mail.Tuning).
CREATE TABLE mail_tuning(
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 updated_at timestamptz NOT NULL
);
INSERT INTO mail_tuning(singleton,payload,updated_at)
VALUES(true,'{"version":1,"overflow_after_login_seconds":3600,"ordinary_seconds":604800}'::jsonb,CURRENT_TIMESTAMP)
ON CONFLICT (singleton) DO NOTHING;
-- The MID1 reconciler stamps a bounded backlog per login.
CREATE INDEX mail_records_overflow_unstamped_idx ON mail_records(recipient_player_id)
  WHERE source_kind='GRANT_OVERFLOW' AND claimed_at IS NULL AND expires_at IS NULL;

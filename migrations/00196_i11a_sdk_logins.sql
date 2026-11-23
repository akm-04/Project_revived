-- +goose Up
-- I11A G51-F product SDK login ingress: logins, their password records and
-- the device bindings the anonymous login path reads. Accounts stay canonical;
-- account kind and the SDK display name live on the account row (G51F F2).
ALTER TABLE accounts ADD COLUMN account_kind text NOT NULL DEFAULT 'normal' CHECK (account_kind IN ('normal','guest'));
ALTER TABLE accounts ADD COLUMN display_username text NOT NULL DEFAULT '';
CREATE TABLE sdk_logins (
  login_normalized text PRIMARY KEY,
  login_display text NOT NULL,
  account_id uuid NOT NULL REFERENCES accounts(account_id),
  password_algorithm text NOT NULL,
  password_iterations integer NOT NULL CHECK (password_iterations > 0),
  password_salt text NOT NULL,
  password_hash text NOT NULL,
  created_at timestamptz NOT NULL,
  password_changed_at timestamptz NOT NULL
);
CREATE INDEX sdk_logins_account_id_idx ON sdk_logins(account_id);
CREATE TABLE sdk_devices (
  device_id text PRIMARY KEY,
  account_id uuid NOT NULL REFERENCES accounts(account_id)
);
CREATE INDEX sdk_devices_account_id_idx ON sdk_devices(account_id);

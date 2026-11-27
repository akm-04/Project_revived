-- +goose Up
-- owner: i5
-- I11A-2 O3 (I11A_OPERATOR_COMMANDS_V1 M1/M11/M4, CPO-09/CPO-10).
-- Mail read-based expiry (C8): a mail row may carry a delay after which it
-- expires once MID 369/370 marks it read. 0 means "when opened"; NULL keeps the
-- existing absolute expiry behaviour.
ALTER TABLE mail_records
  ADD COLUMN expire_after_read_seconds bigint NULL
  CHECK (expire_after_read_seconds IS NULL OR expire_after_read_seconds >= 0);

-- Operator-issued redeem codes: the raw code is kept only for the operator read
-- (redeem.list) and for the operator who distributes it. MID 230 still looks a
-- code up by its HMAC lookup_digest, so a player-submitted code never becomes
-- the durable lookup key.
ALTER TABLE redeem_codes
  ADD COLUMN code_display text NULL
  CHECK (code_display IS NULL OR code_display <> '');

-- owner: operator
-- The last transient error a bulk row hit while its state stays PENDING, shown
-- by operator.bulk.show and cleared when the target moves on.
ALTER TABLE operator_bulk_targets
  ADD COLUMN last_error text NOT NULL DEFAULT '';

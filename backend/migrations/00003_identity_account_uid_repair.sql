-- +goose Up
-- Pass438 targeted source-reality repair: stock MID1/MID17 distinguish account uid from player_id.
-- No canonical mapping can be reconstructed from the I3 UUID surrogate alone. Fail closed if
-- an operator has populated an I3 database before applying this pre-W1 repair.
-- +goose StatementBegin
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM accounts) THEN
    RAISE EXCEPTION '00003 identity repair requires explicit account_uid backfill for pre-existing accounts; refusing to invent stock account identity';
  END IF;
END $$;
-- +goose StatementEnd
ALTER TABLE accounts ADD COLUMN account_uid text NOT NULL;
ALTER TABLE accounts ADD CONSTRAINT accounts_account_uid_uq UNIQUE(account_uid);
-- owner: identity/account-root

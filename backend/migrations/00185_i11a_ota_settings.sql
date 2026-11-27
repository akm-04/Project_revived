-- +goose Up
-- owner: otarelease
-- I11A-1 OTA_AMENDMENTS OA-6: the committed OTA settings. `ota.settings.set`
-- writes this row inside its command transaction; settings.json and the live
-- value are copies made after commit. One row; revision orders the commits.
CREATE TABLE ota_settings (
 singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
 settings jsonb NOT NULL,
 revision bigint NOT NULL CHECK (revision >= 0),
 command_key text REFERENCES operator_commands (semantic_key),
 updated_at timestamptz NOT NULL,
 CHECK ((revision = 0) = (command_key IS NULL))
);

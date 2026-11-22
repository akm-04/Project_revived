-- +goose Up
-- owner: R8 retention (A-039, A-050)
-- R8-4b: a replay-only receipt can only be identified in SQL once the receipt stores the operation id it was written
-- with (A-050: its semantic key is that operation id). Rows written before this column keep NULL and are never purged.
-- The two scans of the retention rules order by these time columns.
-- No attempt-id column lacks a key: every uuid attempt-id column already references combat_attempts or its fight
-- table (docs/data/RETENTION_REFERENCES.json), and the lead's text attempt ids cannot reference a uuid key.
ALTER TABLE gxb_operation_receipts ADD COLUMN operation_id uuid NULL;
CREATE INDEX gxb_operation_receipts_recorded_at_idx ON gxb_operation_receipts(recorded_at);
CREATE INDEX combat_attempts_terminal_at_idx ON combat_attempts(terminal_at);

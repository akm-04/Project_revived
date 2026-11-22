-- +goose Up
-- owner: operations recovery (I11A)
-- D13: a whole-database restore records a history epoch and stays closed to
-- writes until external payments are reconciled. OPERATIONAL data.
CREATE TABLE restore_epochs(
 epoch bigserial PRIMARY KEY,
 restored_at timestamptz NOT NULL DEFAULT now(),
 backup_label text NOT NULL CHECK(backup_label <> ''),
 operator text NOT NULL CHECK(operator <> ''),
 reconciled_at timestamptz,
 reconciliation_note text,
 CHECK(reconciled_at >= restored_at)
);

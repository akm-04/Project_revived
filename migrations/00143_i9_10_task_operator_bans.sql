-- +goose Up
-- owner: TopFloor
-- Operator hook for I11 (D476).
-- PRIVATE_POLICY D512: the per-rotation overlay adds to source bans; absent rows add no restrictions.
CREATE TABLE top_floor_task_bans(
 mode_id bigint NOT NULL CHECK(mode_id BETWEEN 1 AND 6),
 rotation_number bigint NOT NULL CHECK(rotation_number>0),
 banned_table_id bigint NOT NULL CHECK(banned_table_id>0),
 PRIMARY KEY(mode_id,rotation_number,banned_table_id)
);

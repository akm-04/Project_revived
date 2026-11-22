-- +goose Up
-- owner: player-core
-- R3: per-player marker of the last game day whose reset signal a reply carried. The canonical game day is
-- modes.Day (05:00 GMT+8, I9_MODE_FRAMEWORK_V1 F7); one row per player, advanced by a single conditional UPDATE.
CREATE TABLE player_daily_reset_marks(
 player_id bigint PRIMARY KEY,
 last_day bigint NOT NULL,
 updated_at timestamptz NOT NULL
);

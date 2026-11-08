-- +goose Up
-- owner: TopFloor
-- I9-10 lobby broadcast 3002: consecutive Top Floor attack wins. An attack loss
-- or forfeit resets the streak; defence results leave it unchanged.
ALTER TABLE top_floor_players ADD COLUMN win_streak bigint NOT NULL DEFAULT 0 CHECK(win_streak>=0);

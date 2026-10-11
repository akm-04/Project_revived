-- +goose Up
ALTER TABLE player_heroes ADD COLUMN is_like smallint NOT NULL DEFAULT 0 CHECK (is_like IN (0,1));

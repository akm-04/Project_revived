-- +goose Up
-- owner: illusion
-- D428: every Fantasy attempt fights a fresh boss, so no pool persists. A
-- personal best records whether that run killed the boss.
ALTER TABLE illusion_occurrences DROP COLUMN pool_hp, DROP COLUMN pool_hurt;
ALTER TABLE illusion_occurrence_results ADD COLUMN killed boolean NOT NULL DEFAULT false;

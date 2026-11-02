-- +goose Up
-- owner: objective-core
-- Unique insertion serializes first materialization; subsequent objective operations lock this root before I5 value locks.
CREATE TABLE player_mission_roots (
 player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
 day bigint NOT NULL,
 week bigint NOT NULL,
 day_huoyue bigint NOT NULL DEFAULT 0 CHECK(day_huoyue >= 0),
 week_huoyue bigint NOT NULL DEFAULT 0 CHECK(week_huoyue >= 0),
 day_award bigint[] NOT NULL DEFAULT '{}',
 week_award bigint[] NOT NULL DEFAULT '{}',
 battlepass_score bigint NOT NULL DEFAULT 0 CHECK(battlepass_score >= 0),
 state_version bigint NOT NULL DEFAULT 1 CHECK(state_version > 0)
);

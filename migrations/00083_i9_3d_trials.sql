-- +goose Up
-- Owners: Campaign group wins and DailyConsumption purchase counters (D125).
ALTER TABLE campaign_players ADD COLUMN trial_wins jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(trial_wins)='object');
CREATE TABLE daily_consumption_players (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 counts jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(counts)='object'),
 updated_at timestamptz NOT NULL
);

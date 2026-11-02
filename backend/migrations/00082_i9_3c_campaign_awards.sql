-- +goose Up
-- owner: Campaign. Auxiliary claims preserve the active battle and terminal receipt.
ALTER TABLE campaign_players ADD COLUMN chapter_claims jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(chapter_claims)='object');
ALTER TABLE campaign_players ADD COLUMN story_claims jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(story_claims)='object');

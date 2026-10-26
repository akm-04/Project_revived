-- +goose Up
-- owner: Campaign
-- Retained stars and Super allowance counters prove only a lower bound for pre-cutover nodes.
ALTER TABLE campaign_nodes ADD COLUMN clear_count_floor bigint NOT NULL DEFAULT 0 CHECK(clear_count_floor >= 0);
ALTER TABLE campaign_nodes ADD COLUMN clear_count_exact boolean NOT NULL DEFAULT true;
UPDATE campaign_nodes SET clear_count_floor=GREATEST(wins,CASE WHEN star>0 THEN 1 ELSE 0 END),clear_count_exact=false;

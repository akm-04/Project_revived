-- +goose Up
-- owner: library-local-progression
-- I9-11 G2 (A-124): durable per-hero battle counts behind Girls Log type-6
-- milestones 60001-60004 (library_hero_log.lua rows 36-39: 1/50/100/1000).
-- Counts start at 0 at deploy; no history is invented.
CREATE TABLE library_hero_battle_counts (
 player_id bigint NOT NULL REFERENCES players(player_id),
 partner_id bigint NOT NULL CHECK (partner_id > 0),
 count bigint NOT NULL DEFAULT 0 CHECK (count >= 0),
 payload_version smallint NOT NULL DEFAULT 0 CHECK (payload_version >= 0),
 PRIMARY KEY (player_id, partner_id)
);

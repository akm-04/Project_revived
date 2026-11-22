-- +goose Up
-- owner: library-local-progression
-- I9-11 T34 S16 (A-168): durable per-hero completed-dialogue counts behind
-- Girls Log type-7 milestones 70001-70004 (library_hero_log.lua:423-441,
-- 1/10/30/50 dialogues; repeats count). A completed talk increments the
-- counter in its own transaction.
CREATE TABLE library_hero_dialogue_counts (
 player_id bigint NOT NULL REFERENCES players(player_id),
 partner_id bigint NOT NULL CHECK (partner_id > 0),
 count bigint NOT NULL DEFAULT 0 CHECK (count >= 0),
 payload_version smallint NOT NULL DEFAULT 0 CHECK (payload_version >= 0),
 PRIMARY KEY (player_id, partner_id)
);
-- Backfill: the existing distinct awarded dialogue rows are the only recorded
-- lower bound for an existing player.
INSERT INTO library_hero_dialogue_counts(player_id, partner_id, count, payload_version)
SELECT player_id, partner_id, count(*), 0
FROM player_library_dialogs
WHERE is_awarded
GROUP BY player_id, partner_id;

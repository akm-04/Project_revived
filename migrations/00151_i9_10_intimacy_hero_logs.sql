-- +goose Up
-- owner: library-local-progression
-- I9-10 bug 53: the Girls Log milestones the stock table defines. One row per
-- (player, hero, log id); 836 serves partner_logs as map log id -> {time}
-- (TuJianHeroDetailWindow.lua:1548-1559).
CREATE TABLE player_library_hero_logs (
 player_id bigint NOT NULL,
 partner_id bigint NOT NULL CHECK (partner_id > 0),
 log_id bigint NOT NULL CHECK (log_id > 0),
 occurred_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, partner_id, log_id),
 FOREIGN KEY (player_id, partner_id) REFERENCES player_library_heroes(player_id, partner_id)
);

-- +goose Up
-- owner: typed-economy
-- I9-2 MF4 (D92): crystals spent per game day (05:00 GMT+8), accrued where crystal balances are saved; daily missions
-- 126/127 read it as high water (I9-4).
CREATE TABLE player_crystal_spend_days (
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 game_day bigint NOT NULL,
 spent bigint NOT NULL CHECK(spent > 0),
 PRIMARY KEY(player_id, game_day)
);

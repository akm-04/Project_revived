-- +goose Up
-- owner: guild
-- I9_GUILD_ACTIVITY_V1. Lock rank 723, a leaf above I5 temporal 721 and stack 722:
-- the energy debit only upserts here, and a guild fold waits on nothing after it.
CREATE TABLE player_guild_activity_days (
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 game_day bigint NOT NULL,
 amount bigint NOT NULL CHECK(amount > 0),
 folded_amount bigint NOT NULL DEFAULT 0 CHECK(folded_amount >= 0),
 PRIMARY KEY(player_id, game_day)
);

CREATE TABLE player_guild_activity_totals (
 player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
 forfeited bigint NOT NULL CHECK(forfeited >= 0)
);

CREATE TABLE guild_activity_awards (
 -- No FK: it would take a key-share lock on guild 310 inside a settlement (C9).
 guild_id bigint NOT NULL,
 source_key text NOT NULL CHECK(source_key <> ''),
 amount bigint NOT NULL CHECK(amount > 0),
 folded boolean NOT NULL DEFAULT false,
 PRIMARY KEY(guild_id, source_key)
);

-- owner: guild
-- I9_GUILD_ACTIVITY_V1 C13-C15, family player rows at rank 605 in player_id order.
CREATE TABLE guild_tea_wishes (
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 game_day bigint NOT NULL,
 item_id bigint NOT NULL CHECK(item_id > 0),
 need_num bigint NOT NULL CHECK(need_num > 0),
 current_num bigint NOT NULL DEFAULT 0 CHECK(current_num >= 0 AND current_num <= need_num),
 PRIMARY KEY(player_id, game_day)
);

CREATE TABLE guild_tea_gifts (
 receiver_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 donor_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 game_day bigint NOT NULL,
 item_id bigint NOT NULL CHECK(item_id > 0),
 claimed_at timestamptz,
 PRIMARY KEY(receiver_id, donor_id, game_day)
);

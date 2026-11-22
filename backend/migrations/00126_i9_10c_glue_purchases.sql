-- +goose Up
CREATE TABLE player_dorm_glue_purchases (
 player_id bigint PRIMARY KEY REFERENCES player_dorm_roots(player_id) ON DELETE CASCADE,
 game_day bigint NOT NULL,
 purchase_count bigint NOT NULL CHECK(purchase_count>0 AND purchase_count<=9007199254740991),
 state_version bigint NOT NULL CHECK(state_version>0),
 updated_at timestamptz NOT NULL
);

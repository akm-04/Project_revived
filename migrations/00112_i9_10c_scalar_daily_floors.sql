-- +goose Up
CREATE TABLE player_scalar_daily_floors (
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 resource_key text NOT NULL CHECK(resource_key='glue'),
 game_day bigint NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,resource_key),
 FOREIGN KEY(player_id,resource_key) REFERENCES player_currency_balances(player_id,resource_key) ON DELETE CASCADE
);

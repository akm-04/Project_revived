-- +goose Up
-- owner: guild
-- I9_GUILD_RENTAL_V1 C2. Rank 609b, after the Combat locator 609 and before I5 610.
-- Within it: HERO before PET, then lender, then unit. A live row is an open offer;
-- closing one deletes it. No guild FK: it would take a key-share lock on guild 310
-- from a transaction that does not lock the guild.
CREATE TABLE guild_rental_offers (
 lender_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 kind text NOT NULL CHECK(kind IN ('HERO','PET')),
 unit_id bigint NOT NULL CHECK(unit_id > 0),
 guild_id bigint NOT NULL CHECK(guild_id > 0),
 force bigint NOT NULL CHECK(force > 0),
 rent_award bigint NOT NULL DEFAULT 0 CHECK(rent_award >= 0),
 rent_time timestamptz NOT NULL,
 PRIMARY KEY(lender_id, kind, unit_id)
);
CREATE INDEX guild_rental_offers_by_guild ON guild_rental_offers(guild_id, kind, lender_id, unit_id);

-- C10: one unit per borrower, lender and day. Older days are deleted on the borrower's next paid borrow.
CREATE TABLE guild_rental_uses (
 borrower_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 lender_id bigint NOT NULL,
 game_day bigint NOT NULL,
 kind text NOT NULL CHECK(kind IN ('HERO','PET')),
 unit_id bigint NOT NULL CHECK(unit_id > 0),
 campaign_type bigint NOT NULL,
 cost_mana bigint NOT NULL CHECK(cost_mana > 0),
 used_at timestamptz NOT NULL,
 PRIMARY KEY(borrower_id, lender_id, game_day)
);

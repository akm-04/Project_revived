-- +goose Up
-- owner: Content
CREATE TABLE content_charge_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: commerce-privilege
-- I9_COMMERCE_CHARGE_V1. A tap is PRIVATE_POLICY, not a payment (D455). Card truth lives here; monthly_state keeps its old value.
ALTER TABLE commerce_privilege_roots DROP CONSTRAINT commerce_privilege_roots_policy_version_check;
ALTER TABLE commerce_privilege_roots DROP CONSTRAINT commerce_privilege_roots_origin_class_check;
ALTER TABLE commerce_privilege_roots ADD CONSTRAINT commerce_privilege_roots_origin_pair_check CHECK(
 (policy_version='C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1' AND origin_class='MANUAL_PRESERVATION') OR
 (policy_version='I10_CHARGE_TAP_V1' AND origin_class='PLAYER_TAP_PRESERVATION'));
CREATE TABLE commerce_charge_purchases(
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 charge_id bigint NOT NULL CHECK(charge_id>0),
 charge_count bigint NOT NULL CHECK(charge_count>0),
 first_buy_time bigint NOT NULL CHECK(first_buy_time>0),
 last_buy_time bigint NOT NULL CHECK(last_buy_time>=first_buy_time),
 PRIMARY KEY(player_id,charge_id)
);
-- Epoch seconds, 0 = never held. Expiry is lazy. Week and energy cards have no product (D461).
CREATE TABLE commerce_charge_cards(
 player_id bigint PRIMARY KEY REFERENCES players(player_id) ON DELETE CASCADE,
 month_card_start bigint NOT NULL CHECK(month_card_start>=0),
 month_card_end bigint NOT NULL CHECK(month_card_end>=0),
 week_card_end bigint NOT NULL DEFAULT 0 CHECK(week_card_end=0),
 energy_card_end bigint NOT NULL DEFAULT 0 CHECK(energy_card_end=0),
 privilege_card_end bigint NOT NULL CHECK(privilege_card_end>=0),
 updated_at timestamptz NOT NULL
);
CREATE TABLE commerce_vip_awards(
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 level bigint NOT NULL CHECK(level BETWEEN 1 AND 15),
 claimed_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,level)
);
-- Operator overlay (I11): one row; absent or invalid = source policy.
CREATE TABLE commerce_recharge_tuning(
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 updated_at timestamptz NOT NULL
);

-- +goose Up
CREATE TABLE player_public_profile_showcase_slots (
 player_id bigint NOT NULL REFERENCES player_public_profile_roots(player_id),
 slot_ordinal smallint NOT NULL CHECK(slot_ordinal BETWEEN 1 AND 6),
 hero_partner_id bigint CHECK(hero_partner_id BETWEEN 1 AND 9007199254740991),
 pet_id bigint CHECK(pet_id BETWEEN 1 AND 9007199254740991),
 PRIMARY KEY(player_id,slot_ordinal),
 CHECK((hero_partner_id IS NOT NULL)::integer+(pet_id IS NOT NULL)::integer=1)
);
-- References to Character-owned assets are protected by typed reference guards.
-- No foreign-owner cascade or copied template authority.
CREATE TABLE content_public_showcase_policies (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);

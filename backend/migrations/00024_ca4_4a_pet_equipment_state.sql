-- +goose Up
-- CA4-4A-I2: CharacterPet-owned durable three-slot equipment collection state.
-- Raw Pet Fumo remains intentionally absent until CA4-4B.

ALTER TABLE player_pets
  ADD COLUMN equip_1 bigint NOT NULL DEFAULT 0 CHECK (equip_1 BETWEEN 0 AND 1),
  ADD COLUMN equip_2 bigint NOT NULL DEFAULT 0 CHECK (equip_2 BETWEEN 0 AND 1),
  ADD COLUMN equip_3 bigint NOT NULL DEFAULT 0 CHECK (equip_3 BETWEEN 0 AND 1);

-- Forward-only by project law. Rollback is restore/redeploy.

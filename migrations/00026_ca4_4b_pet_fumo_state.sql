-- +goose Up
-- CA4-4B-I2: CharacterPet-owned durable raw Fumo state recovered from the
-- stock private Pet payload. Values are slot-local and independent of equip bits.
-- No Pet fumo-level vector, threshold or cap is inferred.
ALTER TABLE player_pets
  ADD COLUMN fumo_1 bigint NOT NULL DEFAULT 0 CHECK (fumo_1 >= 0),
  ADD COLUMN fumo_2 bigint NOT NULL DEFAULT 0 CHECK (fumo_2 >= 0),
  ADD COLUMN fumo_3 bigint NOT NULL DEFAULT 0 CHECK (fumo_3 >= 0);
-- Forward-only by project law. Rollback is restore/redeploy.

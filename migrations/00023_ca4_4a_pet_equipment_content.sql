-- +goose Up
-- CA4-4A-I1: immutable Pet equipment topology only. Durable player_pets
-- equipment state is intentionally deferred to CA4-4A-I2.

CREATE TABLE gxb_content_pet_equipment (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  pet_table_id bigint NOT NULL CHECK (pet_table_id > 0),
  color smallint NOT NULL CHECK (color BETWEEN 1 AND 16),
  slot smallint NOT NULL CHECK (slot BETWEEN 1 AND 3),
  item_id bigint NOT NULL CHECK (item_id >= 0),
  classification text NOT NULL CHECK (classification IN ('EMPTY','ORDINARY','AWAKENING')),
  CHECK ((classification='EMPTY') = (item_id=0)),
  PRIMARY KEY(revision_id,pet_table_id,color,slot)
);
CREATE INDEX gxb_content_pet_equipment_item_idx
  ON gxb_content_pet_equipment(revision_id,item_id)
  WHERE item_id > 0;

-- Forward-only by project law. Rollback is restore/redeploy.

-- +goose Up
-- CA4-2A: Normal-Hero equipment reachability content plus Hero-owned durable
-- six-slot state. No MID54/MID62 route or gameplay mutation is activated here.

CREATE TABLE gxb_content_hero_equipment (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  hero_table_id bigint NOT NULL CHECK (hero_table_id > 0),
  color smallint NOT NULL CHECK (color BETWEEN 1 AND 16),
  slot smallint NOT NULL CHECK (slot BETWEEN 1 AND 6),
  item_id bigint NOT NULL CHECK (item_id >= 0),
  ordinary_eligible boolean NOT NULL,
  CHECK (item_id <> 0 OR ordinary_eligible = false),
  PRIMARY KEY(revision_id, hero_table_id, color, slot)
);
CREATE INDEX gxb_content_hero_equipment_item_idx
  ON gxb_content_hero_equipment(revision_id, item_id)
  WHERE item_id > 0;

ALTER TABLE player_heroes
  ADD COLUMN equip_1 bigint NOT NULL DEFAULT 0 CHECK (equip_1 >= 0),
  ADD COLUMN equip_2 bigint NOT NULL DEFAULT 0 CHECK (equip_2 >= 0),
  ADD COLUMN equip_3 bigint NOT NULL DEFAULT 0 CHECK (equip_3 >= 0),
  ADD COLUMN equip_4 bigint NOT NULL DEFAULT 0 CHECK (equip_4 >= 0),
  ADD COLUMN equip_5 bigint NOT NULL DEFAULT 0 CHECK (equip_5 >= 0),
  ADD COLUMN equip_6 bigint NOT NULL DEFAULT 0 CHECK (equip_6 >= 0);

-- Forward-only by project law. Rollback is restore/redeploy.

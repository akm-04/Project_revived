-- +goose Up
-- CA4-1: immutable shared equipment/item composition primitives only.
-- No mutable Character equipment/Fumo owner state is introduced here.

CREATE TABLE gxb_content_equipment_primitives (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  item_id bigint NOT NULL CHECK (item_id > 0),
  resource_definition_key text NOT NULL CHECK (btrim(resource_definition_key) <> ''),
  source_item_type bigint NOT NULL,
  required_level bigint NOT NULL CHECK (required_level >= 0),
  compose_mana bigint NOT NULL CHECK (compose_mana >= 0),
  PRIMARY KEY(revision_id, item_id),
  FOREIGN KEY(revision_id, resource_definition_key)
    REFERENCES gxb_content_resource_definitions(revision_id, definition_key) ON DELETE RESTRICT
);

CREATE TABLE gxb_content_equipment_recipe_edges (
  revision_id text NOT NULL,
  parent_item_id bigint NOT NULL CHECK (parent_item_id > 0),
  ordinal bigint NOT NULL CHECK (ordinal > 0),
  component_item_id bigint NOT NULL CHECK (component_item_id > 0),
  component_count bigint NOT NULL CHECK (component_count > 0),
  PRIMARY KEY(revision_id, parent_item_id, ordinal),
  FOREIGN KEY(revision_id, parent_item_id)
    REFERENCES gxb_content_equipment_primitives(revision_id, item_id) ON DELETE RESTRICT,
  FOREIGN KEY(revision_id, component_item_id)
    REFERENCES gxb_content_equipment_primitives(revision_id, item_id) ON DELETE RESTRICT
);
CREATE INDEX gxb_content_equipment_recipe_component_idx
  ON gxb_content_equipment_recipe_edges(revision_id, component_item_id);

-- Forward-only by project law. Rollback is restore/redeploy.

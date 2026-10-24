-- +goose Up
-- CA7-2: Character appearance persistence + immutable revision-scoped content
-- foundation. Hero/Pet remain the canonical durable owners. Child entitlement
-- rows have no independent state version: every observable mutation is fenced
-- by and advances the owning player_heroes/player_pets state_version in the
-- caller-owned transaction. CA7-2 does NOT activate appearance mutation MIDs.

ALTER TABLE player_heroes
  ADD COLUMN current_skin_id bigint NOT NULL DEFAULT 0 CHECK (current_skin_id >= 0),
  ADD COLUMN illusion_skin_id bigint NOT NULL DEFAULT -1 CHECK (illusion_skin_id >= -1);

ALTER TABLE player_pets
  ADD COLUMN active_style bigint NOT NULL DEFAULT 0 CHECK (active_style >= 0);

CREATE TABLE player_hero_skin_entitlements (
  player_id bigint NOT NULL,
  partner_id bigint NOT NULL,
  model_id bigint NOT NULL CHECK (model_id > 0),
  expires_at timestamptz NULL,
  PRIMARY KEY(player_id,partner_id,model_id),
  FOREIGN KEY(player_id,partner_id)
    REFERENCES player_heroes(player_id,partner_id) ON DELETE CASCADE
);
CREATE INDEX player_hero_skin_entitlements_expiry_idx
  ON player_hero_skin_entitlements(player_id,expires_at)
  WHERE expires_at IS NOT NULL;

CREATE TABLE player_hero_live_entitlements (
  player_id bigint NOT NULL,
  partner_id bigint NOT NULL,
  model_id bigint NOT NULL CHECK (model_id > 0),
  is_show boolean NOT NULL,
  PRIMARY KEY(player_id,partner_id,model_id),
  FOREIGN KEY(player_id,partner_id)
    REFERENCES player_heroes(player_id,partner_id) ON DELETE CASCADE
);

CREATE TABLE player_pet_style_entitlements (
  player_id bigint NOT NULL,
  pet_id bigint NOT NULL,
  style_item_id bigint NOT NULL CHECK (style_item_id > 0),
  PRIMARY KEY(player_id,pet_id,style_item_id),
  FOREIGN KEY(player_id,pet_id)
    REFERENCES player_pets(player_id,pet_id) ON DELETE CASCADE
);

-- CHARACTER_APPEARANCE_CA7 immutable content capability. Canonical family
-- identity is origin_table_id; the origin row itself is a qualified base
-- Hero/Pet template in the same immutable revision.
CREATE TABLE gxb_content_appearance_skins (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  model_id bigint NOT NULL CHECK (model_id > 0),
  hero_origin_table_id bigint NOT NULL CHECK (hero_origin_table_id > 0),
  skin_skill_id bigint NOT NULL CHECK (skin_skill_id >= 0),
  PRIMARY KEY(revision_id,model_id),
  UNIQUE(revision_id,model_id,hero_origin_table_id),
  FOREIGN KEY(revision_id,hero_origin_table_id)
    REFERENCES gxb_content_hero_templates(revision_id,table_id) ON DELETE RESTRICT
);
CREATE INDEX gxb_content_appearance_skins_hero_idx
  ON gxb_content_appearance_skins(revision_id,hero_origin_table_id);

CREATE TABLE gxb_content_appearance_skin_items (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  item_id bigint NOT NULL CHECK (item_id > 0),
  model_id bigint NOT NULL CHECK (model_id > 0),
  hero_origin_table_id bigint NOT NULL CHECK (hero_origin_table_id > 0),
  duration_seconds bigint NULL CHECK (duration_seconds IS NULL OR duration_seconds > 0),
  PRIMARY KEY(revision_id,item_id),
  FOREIGN KEY(revision_id,model_id,hero_origin_table_id)
    REFERENCES gxb_content_appearance_skins(revision_id,model_id,hero_origin_table_id) ON DELETE RESTRICT
);
CREATE INDEX gxb_content_appearance_skin_items_model_idx
  ON gxb_content_appearance_skin_items(revision_id,model_id);

CREATE TABLE gxb_content_appearance_live (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  model_id bigint NOT NULL CHECK (model_id > 0),
  hero_origin_table_id bigint NOT NULL CHECK (hero_origin_table_id > 0),
  crystal_cost bigint NOT NULL CHECK (crystal_cost > 0),
  activation_item_id bigint NOT NULL CHECK (activation_item_id > 0),
  activation_item_count bigint NOT NULL CHECK (activation_item_count > 0),
  PRIMARY KEY(revision_id,model_id),
  UNIQUE(revision_id,model_id,hero_origin_table_id),
  FOREIGN KEY(revision_id,hero_origin_table_id)
    REFERENCES gxb_content_hero_templates(revision_id,table_id) ON DELETE RESTRICT
);
CREATE INDEX gxb_content_appearance_live_hero_idx
  ON gxb_content_appearance_live(revision_id,hero_origin_table_id);

CREATE TABLE gxb_content_appearance_pet_styles (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  style_item_id bigint NOT NULL CHECK (style_item_id > 0),
  pet_origin_table_id bigint NOT NULL CHECK (pet_origin_table_id > 0),
  PRIMARY KEY(revision_id,style_item_id),
  FOREIGN KEY(revision_id,pet_origin_table_id)
    REFERENCES gxb_content_pet_templates(revision_id,table_id) ON DELETE RESTRICT
);
CREATE INDEX gxb_content_appearance_pet_styles_pet_idx
  ON gxb_content_appearance_pet_styles(revision_id,pet_origin_table_id);

-- Existing V2 actors receive only neutral/inherit scalar defaults and empty
-- entitlement collections. No historical cosmetic entitlement is fabricated.
-- Forward-only by project law. Rollback is restore/redeploy.

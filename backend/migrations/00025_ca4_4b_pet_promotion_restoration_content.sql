-- +goose Up
-- CA4-4B-I1: immutable Pet ordinary promotion-restoration eligibility/quality.
-- Global refund fractions/denominations remain single-owned by the existing
-- source-qualified restoration policy tables introduced in CA4-3B.
CREATE TABLE gxb_content_pet_promotion_restoration_equipment (
  revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT,
  equipment_item_id bigint NOT NULL CHECK (equipment_item_id > 0),
  source_quality smallint NOT NULL CHECK (source_quality BETWEEN 1 AND 6),
  PRIMARY KEY(revision_id,equipment_item_id),
  FOREIGN KEY(revision_id,equipment_item_id)
    REFERENCES gxb_content_equipment_primitives(revision_id,item_id) ON DELETE RESTRICT
);
-- Forward-only by project law. Rollback is restore/redeploy.

-- +goose Up
-- owner: character/hero-core
-- Empty on upgrade: legacy missing raw facts remain unknown. Only genuine
-- unpublished Character creation initializes the named birth-state policy.
CREATE TABLE player_hero_raw_awakening (
 player_id bigint NOT NULL REFERENCES player_hero_roots(player_id),
 partner_id bigint NOT NULL CHECK(partner_id>0),
 state_version bigint NOT NULL CHECK(state_version>0),
 raw_stage smallint NOT NULL CHECK(raw_stage BETWEEN 0 AND 3),
 birth_policy text NOT NULL CHECK(length(birth_policy)>0),
 creation_content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 birth_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,partner_id),
 CHECK(created_at=birth_at AND updated_at>=created_at)
);

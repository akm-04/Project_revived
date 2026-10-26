-- +goose Up
-- owner: content-registry
CREATE TABLE content_monthly_signin_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);
-- owner: objective-core
CREATE TABLE player_signin_roots (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 month bigint NOT NULL CHECK(month>=197001 AND month%100 BETWEEN 1 AND 12),
 day bigint NOT NULL,
 sign_times bigint NOT NULL DEFAULT 0 CHECK(sign_times BETWEEN 0 AND 31),
 is_signed bigint NOT NULL DEFAULT 0 CHECK(is_signed BETWEEN 0 AND 2),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 state_version bigint NOT NULL DEFAULT 1 CHECK(state_version>=1),
 CHECK(is_signed=0 OR sign_times>0)
);

-- +goose Up
-- owner: Content
CREATE TABLE content_privilege_catalogs(revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'));
-- owner: CommercePrivilege
CREATE TABLE commerce_privilege_roots(
 player_id bigint PRIMARY KEY REFERENCES players(player_id),logical_server_id bigint NOT NULL,
 qualifying_charge bigint NOT NULL CHECK(qualifying_charge BETWEEN 0 AND 9007199254740991),vip_level bigint NOT NULL CHECK(vip_level BETWEEN 0 AND 15),
 monthly_state text NOT NULL CHECK(monthly_state='QUALIFIED_ABSENT'),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),policy_version text NOT NULL CHECK(policy_version='C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1'),
 origin_class text NOT NULL CHECK(origin_class='MANUAL_PRESERVATION'),issuer text NOT NULL CHECK(length(issuer)>0),reason text NOT NULL CHECK(length(reason)>0),
 state_version bigint NOT NULL CHECK(state_version>0),created_at timestamptz NOT NULL,updated_at timestamptz NOT NULL CHECK(updated_at>=created_at));

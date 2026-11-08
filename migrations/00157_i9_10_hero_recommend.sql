-- +goose Up
-- owner: HeroRecommend
-- I9-10: derived weekly Hero Recommendation snapshot. The six mode owners are
-- the only gameplay authority; this table stores only their bounded projection
-- for one logical server and one generation.
CREATE TABLE hero_recommend_snapshots(
 logical_server_id bigint NOT NULL REFERENCES logical_servers(logical_server_id),
 generation bigint NOT NULL CHECK(generation > 0),
 content_revision text NOT NULL,
 observed_at timestamptz NOT NULL,
 digest text NOT NULL CHECK(digest ~ '^[0-9a-f]{64}$'),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 PRIMARY KEY(logical_server_id,generation)
);

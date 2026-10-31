-- +goose Up
-- owner: content-registry
CREATE TABLE content_adventure_catalogs (
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);

-- owner: adventure
-- lock rank 750 (D369): above every I5 rank (the frozen maximum is the
-- directory rank 740). The trigger observer only inserts these rows, for one
-- player and event type, and never waits on another family lock.
CREATE TABLE adventure_occurrences (
 player_id bigint NOT NULL REFERENCES players(player_id),
 event_type integer NOT NULL CHECK(event_type BETWEEN 10001 AND 10006),
 occurred_at timestamptz NOT NULL,
 end_time timestamptz NOT NULL,
 source_key text NOT NULL,
 PRIMARY KEY(player_id,event_type,occurred_at),
 CHECK(end_time>occurred_at)
);
CREATE UNIQUE INDEX adventure_occurrences_source_idx ON adventure_occurrences(player_id,event_type,source_key);
CREATE INDEX adventure_occurrences_active_idx ON adventure_occurrences(player_id,event_type,end_time);

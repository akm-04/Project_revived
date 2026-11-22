-- +goose Up
-- owner: events
-- I11A-2 E6 (EA-13): the last shipped definition sha that conflicted with a
-- stored revision. A conflict never overwrites the stored body; the row lets
-- events.definition.list report SYNC_CONFLICT until a later sync matches.
CREATE TABLE event_definition_sync_conflicts (
 activity_id bigint NOT NULL CHECK (activity_id > 0 AND activity_id <= 2147483647),
 revision bigint NOT NULL CHECK (revision > 0),
 shipped_sha256 text NOT NULL CHECK (shipped_sha256 ~ '^[0-9a-f]{64}$'),
 recorded_at timestamptz NOT NULL,
 PRIMARY KEY (activity_id, revision),
 FOREIGN KEY (activity_id, revision) REFERENCES event_definitions (activity_id, revision)
);

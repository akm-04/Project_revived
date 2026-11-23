-- +goose Up
-- owner: events
-- EA-15 global event scope (GUI_REVIEW_2026-11-23B): one group scheduled across
-- every current and future logical server. An occurrence belongs to at most one
-- group; server-only rows keep global_group_id NULL. The unique pair makes the
-- maintenance join idempotent; an ended group stops joining (ended_at).

CREATE TABLE event_global_groups (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 activity_id bigint NOT NULL,
 definition_revision bigint NOT NULL,
 starts_at timestamptz NOT NULL,
 ends_at timestamptz,
 state text NOT NULL CHECK (state IN ('SCHEDULED', 'RUNNING', 'ENDED')),
 revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
 created_at timestamptz NOT NULL,
 ended_at timestamptz,
 created_by_command text REFERENCES operator_commands (semantic_key),
 FOREIGN KEY (activity_id, definition_revision) REFERENCES event_definitions (activity_id, revision),
 CHECK (ends_at IS NULL OR ends_at > starts_at),
 CHECK ((state = 'ENDED') = (ended_at IS NOT NULL))
);
CREATE INDEX event_global_groups_started ON event_global_groups (starts_at DESC, id DESC);

ALTER TABLE event_occurrences
 ADD COLUMN global_group_id bigint REFERENCES event_global_groups (id);

-- One occurrence per (group, server): the maintenance join inserts with
-- ON CONFLICT DO NOTHING. NULL group ids stay distinct, so server-only rows are
-- unaffected.
CREATE UNIQUE INDEX event_occurrences_global_group_server
 ON event_occurrences (global_group_id, logical_server_id);
CREATE INDEX event_occurrences_global_group
 ON event_occurrences (global_group_id) WHERE global_group_id IS NOT NULL;

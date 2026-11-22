-- +goose Up
-- owner: events
-- I11A-2 E4 cycle materialiser idempotency (I11A_EVENTS_V1 ruling 8, EA-9).
-- One CYCLE row per (server, activity, starts_at). Cancelled rows stay in the
-- index, so an operator cancel is never undone by a later materialiser run;
-- two concurrent runs insert each slot once.

CREATE UNIQUE INDEX event_occurrences_cycle_slot
 ON event_occurrences (logical_server_id, activity_id, starts_at)
 WHERE source = 'CYCLE';

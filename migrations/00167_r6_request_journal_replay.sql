-- +goose Up
-- R6: the request journal marks a reply that was answered from an undelivered-reply mark instead of a dispatch,
-- so a replay is visible as its own line beside the ordinary dispatch lines.
ALTER TABLE request_journal ADD COLUMN replay boolean NOT NULL DEFAULT false;

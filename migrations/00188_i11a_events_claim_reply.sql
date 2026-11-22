-- +goose Up
-- owner: events
-- I11A-2 E3: the MID 231 claim stores the reply it granted, so a repeat of the
-- same command re-answers exactly those awards without a second grant (EA-7).
ALTER TABLE player_event_claims
 ADD COLUMN award_body jsonb CHECK (award_body IS NULL OR jsonb_typeof(award_body) = 'object');

-- +goose Up
-- I9-10 bugs 38: a seat still occupied when the room ended is CLOSED, distinct
-- from the voluntary LEFT that must not send a removal frame.
ALTER TABLE shared_room_seats DROP CONSTRAINT shared_room_seats_stage_check;
ALTER TABLE shared_room_seats ADD CONSTRAINT shared_room_seats_stage_check
 CHECK(stage IN ('SEATED','LEFT','KICKED','CLOSED'));

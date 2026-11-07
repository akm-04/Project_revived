-- +goose Up
-- owner: EventCentre
CREATE TABLE player_event_centre_board_reports (player_id bigint NOT NULL REFERENCES players(player_id), report_id bigint NOT NULL CHECK(report_id>0), content text NOT NULL CHECK(content<>''), created_at timestamptz NOT NULL, PRIMARY KEY(player_id,report_id));

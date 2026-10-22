-- +goose Up
-- owner: Combat
-- I8-6C multi-participant attempts (D24 private policy, original bookkeeping
-- UNKNOWN): a START admitted by the shared-room capability stores its member
-- roster (the convener at seat 0, at most 8 seats), and the mode settles each
-- member once after the attempt's single terminal. Both records are append-only
-- and attempt-scoped under the rank-609 locator fence. Existing attempts have
-- no roster and stay single-member.
CREATE TABLE combat_attempt_members (
 attempt_id uuid NOT NULL REFERENCES combat_attempts(attempt_id),
 seat smallint NOT NULL CHECK(seat BETWEEN 0 AND 7),
 member_player_id bigint NOT NULL REFERENCES players(player_id),
 PRIMARY KEY(attempt_id, member_player_id),
 UNIQUE(attempt_id, seat)
);
CREATE TABLE combat_member_settlements (
 attempt_id uuid NOT NULL,
 member_player_id bigint NOT NULL,
 semantic_receipt_id text NOT NULL CHECK(semantic_receipt_id<>'' AND length(semantic_receipt_id)<=256),
 settled_at timestamptz NOT NULL,
 PRIMARY KEY(attempt_id, member_player_id),
 FOREIGN KEY(attempt_id, member_player_id) REFERENCES combat_attempt_members(attempt_id, member_player_id)
);
CREATE TRIGGER combat_attempt_members_append_only BEFORE UPDATE OR DELETE ON combat_attempt_members FOR EACH ROW EXECUTE FUNCTION combat_append_only();
CREATE TRIGGER combat_member_settlements_append_only BEFORE UPDATE OR DELETE ON combat_member_settlements FOR EACH ROW EXECUTE FUNCTION combat_append_only();

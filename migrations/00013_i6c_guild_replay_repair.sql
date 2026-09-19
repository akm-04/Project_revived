-- +goose Up
-- F2/I6C replay repair: clean contradictory legacy V2 application rows.
-- Canonical GuildMembership makes every outgoing Guild application obsolete.
-- Data cleanup only: no schema, owner, timing, or stock-wire change.

DELETE FROM guild_applications ga
USING guild_memberships gm
WHERE gm.player_id = ga.player_id;

-- Forward-only by project law. Rollback is restore/redeploy.

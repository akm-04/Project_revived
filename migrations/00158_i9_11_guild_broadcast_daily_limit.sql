-- +goose Up
-- GUILD_BROADCAST_DAILY_LIMIT_V1: the per-guild game-day count reads only one
-- guild's decision window, so its scan stays on an index page set rather than
-- the whole source history.
CREATE INDEX guild_broadcast_sources_guild_day ON guild_broadcast_sources(guild_id,decision_at);

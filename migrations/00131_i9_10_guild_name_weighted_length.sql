-- +goose Up
-- The application owns the stock weighted length (GUILD_NAME_LENGTH_POLICY_V1); half-width names reach 20 characters.
ALTER TABLE guilds DROP CONSTRAINT guilds_name_check;
ALTER TABLE guilds ADD CONSTRAINT guilds_name_check CHECK (char_length(name) BETWEEN 1 AND 20);

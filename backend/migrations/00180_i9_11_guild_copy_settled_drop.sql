-- +goose Up
-- owner: guildcampaign
-- A-134 (I9_GUILD_CAMPAIGN_V1 C8): replay is per member, so the copy-level
-- settled slot is unwritten and unread. Dropping settled_by also drops its
-- 00161 foreign key.
ALTER TABLE guild_campaign_copies
 DROP COLUMN settled_by,
 DROP COLUMN settled_index,
 DROP COLUMN settled_body;

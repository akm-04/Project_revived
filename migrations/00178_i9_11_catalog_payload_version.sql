-- +goose Up
-- owner: Content
-- R8-2 (A-037): the I9-11 content catalogs decode their jsonb payload into a Go
-- value, so each carries the same payload_version column as every catalog in
-- 00163. Existing rows are version 0 (lenient decode); writers store
-- foundation/payload.Current and payload bytes and digests do not change.
ALTER TABLE content_daily_buy_input_catalogs ADD COLUMN payload_version smallint NOT NULL DEFAULT 0 CHECK (payload_version >= 0);
ALTER TABLE content_compat_catalogs ADD COLUMN payload_version smallint NOT NULL DEFAULT 0 CHECK (payload_version >= 0);
ALTER TABLE content_shop_catalogs ADD COLUMN payload_version smallint NOT NULL DEFAULT 0 CHECK (payload_version >= 0);

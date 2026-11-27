-- +goose Up
-- owner: otarelease (I11A_OTA_RELEASE_V1 amendment OA-10, 2026-11-23)
-- A rollback build may reuse a used release number whose release is neither
-- ACTIVE nor BUILT. Releases get a surrogate id; the old row stays as REPLACED
-- (replaced_at, replaced_by) for the audit trail, while version stays unique
-- among non-REPLACED rows. Activations refer to the release id.
ALTER TABLE ota_activations DROP CONSTRAINT ota_activations_version_fkey;
ALTER TABLE ota_releases DROP CONSTRAINT ota_releases_pkey;
ALTER TABLE ota_releases ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE ota_releases ADD PRIMARY KEY (id);
CREATE UNIQUE INDEX ota_releases_version_live ON ota_releases (version) WHERE state <> 'REPLACED';

ALTER TABLE ota_releases DROP CONSTRAINT ota_releases_state_check;
ALTER TABLE ota_releases ADD CONSTRAINT ota_releases_state_check
	CHECK (state IN ('BUILT', 'ACTIVE', 'SUPERSEDED', 'WITHDRAWN', 'REPLACED'));
-- A REPLACED row keeps the lifecycle timestamp it earned (SUPERSEDED/WITHDRAWN).
ALTER TABLE ota_releases DROP CONSTRAINT ota_releases_check2;
ALTER TABLE ota_releases ADD CONSTRAINT ota_releases_check2
	CHECK (state <> 'SUPERSEDED' OR superseded_at IS NOT NULL);
ALTER TABLE ota_releases DROP CONSTRAINT ota_releases_check3;
ALTER TABLE ota_releases ADD CONSTRAINT ota_releases_check3
	CHECK (state <> 'WITHDRAWN' OR withdrawn_at IS NOT NULL);
ALTER TABLE ota_releases ADD COLUMN replaced_at timestamptz;
ALTER TABLE ota_releases ADD COLUMN replaced_by bigint REFERENCES ota_releases (id);
ALTER TABLE ota_releases ADD CONSTRAINT ota_releases_replaced_check
	CHECK ((state = 'REPLACED') = (replaced_at IS NOT NULL));

ALTER TABLE ota_activations ADD COLUMN release_id bigint;
UPDATE ota_activations activation SET release_id = release.id
FROM ota_releases release WHERE release.version = activation.version;
ALTER TABLE ota_activations ALTER COLUMN release_id SET NOT NULL;
ALTER TABLE ota_activations ADD CONSTRAINT ota_activations_release_fkey
	FOREIGN KEY (release_id) REFERENCES ota_releases (id);
CREATE INDEX ota_activations_release ON ota_activations (release_id);

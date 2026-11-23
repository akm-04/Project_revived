// OTA write side (I11A_OTA_RELEASE_V1 commands) and the ota.status read. L3
// owns this file; L2 owns serving.go.
package otastore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const selectRelease = `SELECT id,version,lane,state,package_files::text,total_size,md5,sha256,manifest::text
FROM ota_releases WHERE version=$1 AND state <> 'REPLACED'`

const selectReleaseStatus = `SELECT lane,state FROM ota_releases WHERE version=$1 AND state <> 'REPLACED'`

// ReleaseStatusTx is the exact-version read in every live state (BUILT, ACTIVE,
// SUPERSEDED or WITHDRAWN), with the row's lane and state; a REPLACED row whose
// number a rollback reuse took over is never reported (OA-10).
func (Store) ReleaseStatusTx(ctx context.Context, query tx.Queryer, version string) (bool, string, string, error) {
	if query == nil || version == "" {
		return false, "", "", errInvalid
	}
	var lane, state string
	err := query.QueryRow(ctx, selectReleaseStatus, version).Scan(&lane, &state)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return false, "", "", nil
	}
	if err != nil {
		return false, "", "", err
	}
	return true, lane, state, nil
}

// ReleaseTx reads one live release row, unlocked; lockTarget then locks its
// lane. A REPLACED row is invisible here (OA-10).
func (Store) ReleaseTx(ctx context.Context, query tx.Queryer, version string) (*otarelease.RawRelease, error) {
	if query == nil || version == "" {
		return nil, errInvalid
	}
	var row otarelease.RawRelease
	var packageFiles, manifest string
	err := query.QueryRow(ctx, selectRelease, version).Scan(&row.ID, &row.Version, &row.Lane, &row.State, &packageFiles, &row.TotalSize, &row.MD5, &row.SHA256, &manifest)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	row.PackageFiles = json.RawMessage(packageFiles)
	row.Manifest = json.RawMessage(manifest)
	return &row, nil
}

const lockLane = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'id',id,'version',version,'lane',lane,'state',state,'package_files',package_files,
	'total_size',total_size,'md5',md5,'sha256',sha256) ORDER BY version_key),'[]'::jsonb)::text
FROM (
	SELECT id,version,lane,state,package_files,total_size,md5,sha256,
		string_to_array(version,'.')::bigint[] AS version_key
	FROM ota_releases
	WHERE lane=$1 AND state <> 'REPLACED' AND (state IN ('ACTIVE','BUILT') OR version=$2)
	ORDER BY version_key FOR UPDATE
) locked`

// LockLaneTx locks the lane's ACTIVE and BUILT rows and the target version row,
// ordered by version (the plan's lock order after the bus row). The BUILT rows
// carry the lane's line when nothing is active (G23); REPLACED rows are neither
// locked nor returned (OA-10).
func (Store) LockLaneTx(ctx context.Context, transaction tx.Tx, lane otarelease.Lane, version string) ([]otarelease.RawRelease, error) {
	if transaction == nil || lane == "" || version == "" {
		return nil, errInvalid
	}
	var raw string
	if err := transaction.QueryRow(ctx, lockLane, string(lane), version).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []otarelease.RawRelease
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (Store) ActiveRevisionTx(ctx context.Context, query tx.Queryer) (int64, error) {
	if query == nil {
		return 0, errInvalid
	}
	var revision int64
	if err := query.QueryRow(ctx, `SELECT COALESCE(max(id),0) FROM ota_activations`).Scan(&revision); err != nil {
		return 0, err
	}
	return revision, nil
}

const insertBuildRow = `INSERT INTO ota_releases(version,lane,state,package_files,total_size,md5,sha256,manifest,built_by_command,built_at)
VALUES($1,$2,'BUILT',$3::jsonb,$4,$5,$6,$7::jsonb,$8,$9) RETURNING id`

func (Store) InsertBuildTx(ctx context.Context, transaction tx.Tx, release otarelease.Release, commandKey string, at time.Time) error {
	if transaction == nil || commandKey == "" || at.IsZero() {
		return errInvalid
	}
	packageFiles, err := json.Marshal(release.Volumes)
	if err != nil {
		return err
	}
	manifest, err := json.Marshal(map[string]any{"files": release.Manifest})
	if err != nil {
		return err
	}
	effect, err := transaction.Exec(ctx, insertBuildRow, release.Version.String(), string(release.Lane), string(packageFiles), release.TotalSize, release.MD5, release.SHA256, string(manifest), commandKey, at.UTC())
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("otastore: build insert wrote no row")
	}
	return nil
}

// ReuseBuildTx takes over a used release number for a rollback: the old row
// becomes REPLACED in the same transaction, then the new BUILT row is inserted
// and linked back as replaced_by (OA-10 clause 2). Files are never rewritten;
// the new build carries its own <version>-<sha256> names.
func (Store) ReuseBuildTx(ctx context.Context, transaction tx.Tx, replacedID int64, release otarelease.Release, commandKey string, at time.Time) error {
	if transaction == nil || replacedID <= 0 || commandKey == "" || at.IsZero() {
		return errInvalid
	}
	packageFiles, err := json.Marshal(release.Volumes)
	if err != nil {
		return err
	}
	manifest, err := json.Marshal(map[string]any{"files": release.Manifest})
	if err != nil {
		return err
	}
	effect, err := transaction.Exec(ctx, `UPDATE ota_releases SET state='REPLACED',replaced_at=$2 WHERE id=$1 AND state <> 'REPLACED'`, replacedID, at.UTC())
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("otastore: the reused release is already replaced")
	}
	var newID int64
	if err := transaction.QueryRow(ctx, insertBuildRow, release.Version.String(), string(release.Lane), string(packageFiles), release.TotalSize, release.MD5, release.SHA256, string(manifest), commandKey, at.UTC()).Scan(&newID); err != nil {
		return err
	}
	effect, err = transaction.Exec(ctx, `UPDATE ota_releases SET replaced_by=$1 WHERE id=$2`, newID, replacedID)
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("otastore: the replaced release was not linked")
	}
	return nil
}

const supersedeLane = `WITH superseded AS (
	UPDATE ota_releases SET state='SUPERSEDED', superseded_at=$2
	WHERE lane=$1 AND state='ACTIVE' RETURNING version
)
SELECT COALESCE(jsonb_agg(version ORDER BY string_to_array(version,'.')::bigint[]),'[]'::jsonb)::text FROM superseded`

func (Store) SupersedeLaneTx(ctx context.Context, transaction tx.Tx, lane otarelease.Lane, at time.Time) ([]string, error) {
	if transaction == nil || lane == "" || at.IsZero() {
		return nil, errInvalid
	}
	var raw string
	if err := transaction.QueryRow(ctx, supersedeLane, string(lane), at.UTC()).Scan(&raw); err != nil {
		return nil, err
	}
	var versions []string
	if err := json.Unmarshal([]byte(raw), &versions); err != nil {
		return nil, err
	}
	return versions, nil
}

func (Store) ActivateTx(ctx context.Context, transaction tx.Tx, version, commandKey string, at time.Time) error {
	if transaction == nil || version == "" || commandKey == "" || at.IsZero() {
		return errInvalid
	}
	effect, err := transaction.Exec(ctx, `UPDATE ota_releases SET state='ACTIVE',published_by_command=$2,published_at=$3 WHERE version=$1 AND state='BUILT'`, version, commandKey, at.UTC())
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("otastore: release is not BUILT")
	}
	return nil
}

func (Store) WithdrawTx(ctx context.Context, transaction tx.Tx, version string, at time.Time) error {
	if transaction == nil || version == "" || at.IsZero() {
		return errInvalid
	}
	effect, err := transaction.Exec(ctx, `UPDATE ota_releases SET state='WITHDRAWN',withdrawn_at=$2 WHERE version=$1 AND state='ACTIVE'`, version, at.UTC())
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("otastore: release is not ACTIVE")
	}
	return nil
}

func (Store) InsertActivationTx(ctx context.Context, transaction tx.Tx, activation appota.ActivationRow) (int64, error) {
	if transaction == nil || activation.ReleaseID <= 0 || activation.Version == "" || activation.Action == "" || activation.CommandKey == "" || activation.At.IsZero() {
		return 0, errInvalid
	}
	var id int64
	if err := transaction.QueryRow(ctx, `INSERT INTO ota_activations(release_id,version,action,command_key,at) VALUES($1,$2,$3,$4,$5) RETURNING id`,
		activation.ReleaseID, activation.Version, activation.Action, activation.CommandKey, activation.At.UTC()).Scan(&id); err != nil {
		return 0, err
	}
	return id, nil
}

const readStatus = `SELECT jsonb_build_object(
	'revision',(SELECT COALESCE(max(id),0) FROM ota_activations),
	'active',(SELECT COALESCE(jsonb_agg(jsonb_build_object('version',version,'lane',lane,'total_size',total_size,'published_at',published_at) ORDER BY version_key),'[]'::jsonb)
		FROM (SELECT version,lane,total_size,published_at,string_to_array(version,'.')::bigint[] AS version_key FROM ota_releases WHERE state='ACTIVE' ORDER BY version_key LIMIT $1) active),
	'built',(SELECT COALESCE(jsonb_agg(jsonb_build_object('version',version,'lane',lane,'total_size',total_size,'built_at',built_at) ORDER BY version_key),'[]'::jsonb)
		FROM (SELECT version,lane,total_size,built_at,string_to_array(version,'.')::bigint[] AS version_key FROM ota_releases WHERE state='BUILT' ORDER BY version_key LIMIT $2) built),
	'activations',(SELECT COALESCE(jsonb_agg(jsonb_build_object('id',id,'version',version,'action',action,'command_key',command_key,'at',at) ORDER BY id DESC),'[]'::jsonb)
		FROM (SELECT id,version,action,command_key,at FROM ota_activations ORDER BY id DESC LIMIT $3) recent),
	'served',(SELECT COALESCE(jsonb_agg(jsonb_build_object('path',path,'hits',hits) ORDER BY hits DESC, path),'[]'::jsonb)
		FROM (SELECT path,sum(hits) AS hits FROM ota_asset_served_daily GROUP BY path ORDER BY hits DESC, path LIMIT $4) served),
	'misses',(SELECT COALESCE(jsonb_agg(jsonb_build_object('path',path,'md5',md5,'first_seen',first_seen,'last_seen',last_seen,'hits',hits,'first_uid',first_uid) ORDER BY hits DESC, path),'[]'::jsonb)
		FROM (SELECT path,md5,first_seen,last_seen,hits,first_uid FROM ota_asset_misses ORDER BY hits DESC, path LIMIT $5) misses),
	'versions',(SELECT COALESCE(jsonb_agg(version ORDER BY version_key DESC),'[]'::jsonb)
		FROM (SELECT version,string_to_array(version,'.')::bigint[] AS version_key FROM ota_releases ORDER BY version_key DESC LIMIT $6) releases)
)::text`

// ReadStatusTx reads the bounded ota.status snapshot; each list is asked for
// its bound plus one row so the fold can report truncation. The version list
// comes newest first, so the fold can derive next_version across every lane and
// state. The miss and counter tables are only read, never seeded here.
func (Store) ReadStatusTx(ctx context.Context, query tx.Queryer) (appota.StatusSnapshot, error) {
	if query == nil {
		return appota.StatusSnapshot{}, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, readStatus,
		appota.StatusActiveLimit+1, appota.StatusBuiltLimit+1, appota.StatusActivationLimit+1,
		appota.StatusServedLimit+1, appota.StatusMissesLimit+1, appota.StatusVersionLimit,
	).Scan(&raw); err != nil {
		return appota.StatusSnapshot{}, err
	}
	var snapshot appota.StatusSnapshot
	if err := json.Unmarshal([]byte(raw), &snapshot); err != nil {
		return appota.StatusSnapshot{}, err
	}
	return snapshot, nil
}

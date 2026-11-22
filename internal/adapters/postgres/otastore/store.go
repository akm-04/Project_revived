// Package otastore owns ota_releases reads (migration 00184). L3 adds the
// write side; this file exposes only the bounded ACTIVE read.
package otastore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var errInvalid = errors.New("otastore: invalid input")

// maxActiveReleases bounds one read; the version line has one active release
// per lane.
const maxActiveReleases = 16

const selectActiveReleases = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'version',version,'lane',lane,'state',state,'package_files',package_files,
	'total_size',total_size,'md5',md5,'sha256',sha256,'manifest',manifest
) ORDER BY version),'[]'::jsonb)::text FROM (
	SELECT version,lane,state,package_files,total_size,md5,sha256,manifest
	FROM ota_releases WHERE state='ACTIVE' ORDER BY version LIMIT $1
) active`

const selectActiveDescriptors = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'version',version,'lane',lane,'state',state,'package_files',package_files,
	'total_size',total_size,'md5',md5,'sha256',sha256
) ORDER BY version),'[]'::jsonb)::text FROM (
	SELECT version,lane,state,package_files,total_size,md5,sha256
	FROM ota_releases WHERE state='ACTIVE' ORDER BY version LIMIT $1
) active`

// Store reads ota_releases rows.
type Store struct{}

// ListActiveTx reads every ACTIVE release of every lane through the caller's
// read-only transaction, including manifests.
func (Store) ListActiveTx(ctx context.Context, query tx.Queryer) ([]otarelease.RawRelease, error) {
	return listActive(ctx, query, selectActiveReleases)
}

// ListActiveDescriptorsTx reads every ACTIVE release of every lane without the
// manifest column, which the MID 2 plan never uses.
func (Store) ListActiveDescriptorsTx(ctx context.Context, query tx.Queryer) ([]otarelease.RawRelease, error) {
	return listActive(ctx, query, selectActiveDescriptors)
}

func listActive(ctx context.Context, query tx.Queryer, statement string) ([]otarelease.RawRelease, error) {
	if query == nil {
		return nil, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, statement, maxActiveReleases).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []otarelease.RawRelease
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	if len(rows) > maxActiveReleases {
		return nil, errInvalid
	}
	return rows, nil
}

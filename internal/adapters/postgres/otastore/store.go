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

// maxActiveReleases bounds one read: one code, one assets and at most 14
// catalog releases (OTA_AMENDMENTS OA-1). A read asks for one row more and
// fails closed rather than silently drop a live release.
const maxActiveReleases = 16

// Every order over a release number sorts the dotted components as numbers:
// text order would put 1.631.10 below 1.631.9 (G44).
const versionOrder = `string_to_array(version,'.')::bigint[]`

const selectActiveReleases = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'version',version,'lane',lane,'state',state,'package_files',package_files,
	'total_size',total_size,'md5',md5,'sha256',sha256,'manifest',manifest
) ORDER BY version_key),'[]'::jsonb)::text FROM (
	SELECT version,lane,state,package_files,total_size,md5,sha256,manifest,
		string_to_array(version,'.')::bigint[] AS version_key
	FROM ota_releases WHERE state='ACTIVE' ORDER BY version_key LIMIT $1
) active`

const selectActiveDescriptors = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'version',version,'lane',lane,'state',state,'package_files',package_files,
	'total_size',total_size,'md5',md5,'sha256',sha256
) ORDER BY version_key),'[]'::jsonb)::text FROM (
	SELECT version,lane,state,package_files,total_size,md5,sha256,
		string_to_array(version,'.')::bigint[] AS version_key
	FROM ota_releases WHERE state='ACTIVE' ORDER BY version_key LIMIT $1
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
	if err := query.QueryRow(ctx, statement, maxActiveReleases+1).Scan(&raw); err != nil {
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

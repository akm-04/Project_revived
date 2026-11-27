package otastore

import (
	"context"
	"encoding/json"

	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// The ota.status ledger reads live here, beside the tables' writer, so the
// application layer owns no SQL.

const readServedCounters = `SELECT COALESCE(jsonb_agg(jsonb_build_object('path',path,'hits',hits) ORDER BY hits DESC, path),'[]'::jsonb)::text
FROM (SELECT path,sum(hits) AS hits FROM ota_asset_served_daily GROUP BY path ORDER BY hits DESC, path LIMIT $1) served`

const readAssetMisses = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'path',path,'md5',md5,'first_seen',first_seen,'last_seen',last_seen,'hits',hits,'first_uid',first_uid) ORDER BY hits DESC, path),'[]'::jsonb)::text
FROM (SELECT path,md5,first_seen,last_seen,hits,first_uid FROM ota_asset_misses ORDER BY hits DESC, path LIMIT $1) misses`

// ReadLedgerTx reads the top served paths and asset misses in the caller's
// read-only status transaction.
func (Store) ReadLedgerTx(ctx context.Context, query tx.Queryer, servedLimit, missLimit int) (appota.LedgerStatus, error) {
	if query == nil || servedLimit <= 0 || missLimit <= 0 {
		return appota.LedgerStatus{}, errInvalid
	}
	var status appota.LedgerStatus
	var raw string
	if err := query.QueryRow(ctx, readServedCounters, servedLimit).Scan(&raw); err != nil {
		return appota.LedgerStatus{}, err
	}
	if err := json.Unmarshal([]byte(raw), &status.Served); err != nil {
		return appota.LedgerStatus{}, err
	}
	if err := query.QueryRow(ctx, readAssetMisses, missLimit).Scan(&raw); err != nil {
		return appota.LedgerStatus{}, err
	}
	if err := json.Unmarshal([]byte(raw), &status.Misses); err != nil {
		return appota.LedgerStatus{}, err
	}
	return status, nil
}

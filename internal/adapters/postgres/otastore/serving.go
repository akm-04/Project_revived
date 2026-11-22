package otastore

import (
	"context"
	"encoding/hex"
	"strings"
	"time"

	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LedgerStore writes the OTA asset-miss ledger and the daily served counters
// (migration 00184). One flush is one transaction with two array upserts; no
// other lock is held.
type LedgerStore struct{}

const insertServedDaily = `INSERT INTO ota_asset_served_daily (path,day,hits)
SELECT served.path, served.day::date, served.hits
FROM unnest($1::text[], $2::text[], $3::bigint[]) AS served(path, day, hits)
ON CONFLICT (path, day) DO UPDATE SET hits = ota_asset_served_daily.hits + EXCLUDED.hits`

const insertAssetMisses = `INSERT INTO ota_asset_misses (path,md5,first_seen,last_seen,hits,first_uid)
SELECT missed.path, missed.md5, missed.first_seen, missed.last_seen, missed.hits, NULL
FROM unnest($1::text[], $2::text[], $3::timestamptz[], $4::timestamptz[], $5::bigint[])
	AS missed(path, md5, first_seen, last_seen, hits)
ON CONFLICT (path, md5) DO UPDATE SET
	first_seen = LEAST(ota_asset_misses.first_seen, EXCLUDED.first_seen),
	last_seen = GREATEST(ota_asset_misses.last_seen, EXCLUDED.last_seen),
	hits = ota_asset_misses.hits + EXCLUDED.hits`

func (LedgerStore) FlushTx(ctx context.Context, transaction tx.Tx, served []appotarelease.ServedCount, misses []appotarelease.MissRecord) error {
	if transaction == nil {
		return errInvalid
	}
	servedValues, err := servedColumns(served)
	if err != nil {
		return err
	}
	missValues, err := missColumns(misses)
	if err != nil {
		return err
	}
	if len(servedValues.paths) > 0 {
		if _, err := transaction.Exec(ctx, insertServedDaily, servedValues.paths, servedValues.days, servedValues.hits); err != nil {
			return err
		}
	}
	if len(missValues.paths) > 0 {
		if _, err := transaction.Exec(ctx, insertAssetMisses, missValues.paths, missValues.md5s, missValues.firstSeen, missValues.lastSeen, missValues.hits); err != nil {
			return err
		}
	}
	return nil
}

type servedColumnsValue struct {
	paths []string
	days  []string
	hits  []int64
}

type missColumnsValue struct {
	paths     []string
	md5s      []string
	firstSeen []time.Time
	lastSeen  []time.Time
	hits      []int64
}

func servedColumns(rows []appotarelease.ServedCount) (servedColumnsValue, error) {
	columns := servedColumnsValue{paths: make([]string, 0, len(rows)), days: make([]string, 0, len(rows)), hits: make([]int64, 0, len(rows))}
	for _, row := range rows {
		if row.Path == "" || len(row.Path) > maxLedgerPathBytes || row.Hits <= 0 {
			return servedColumnsValue{}, errInvalid
		}
		if _, err := time.Parse("2006-01-02", row.Day); err != nil {
			return servedColumnsValue{}, errInvalid
		}
		columns.paths = append(columns.paths, row.Path)
		columns.days = append(columns.days, row.Day)
		columns.hits = append(columns.hits, row.Hits)
	}
	return columns, nil
}

func missColumns(rows []appotarelease.MissRecord) (missColumnsValue, error) {
	columns := missColumnsValue{
		paths: make([]string, 0, len(rows)), md5s: make([]string, 0, len(rows)),
		firstSeen: make([]time.Time, 0, len(rows)), lastSeen: make([]time.Time, 0, len(rows)),
		hits: make([]int64, 0, len(rows)),
	}
	for _, row := range rows {
		if row.Path == "" || len(row.Path) > maxLedgerPathBytes || row.Hits <= 0 {
			return missColumnsValue{}, errInvalid
		}
		if !validLedgerMD5(row.MD5) {
			return missColumnsValue{}, errInvalid
		}
		if row.FirstSeen.IsZero() || row.LastSeen.Before(row.FirstSeen) {
			return missColumnsValue{}, errInvalid
		}
		columns.paths = append(columns.paths, row.Path)
		columns.md5s = append(columns.md5s, row.MD5)
		columns.firstSeen = append(columns.firstSeen, row.FirstSeen.UTC())
		columns.lastSeen = append(columns.lastSeen, row.LastSeen.UTC())
		columns.hits = append(columns.hits, row.Hits)
	}
	return columns, nil
}

const maxLedgerPathBytes = 512

func validLedgerMD5(text string) bool {
	if text == "" {
		return true
	}
	if len(text) != 32 || strings.ToLower(text) != text {
		return false
	}
	_, err := hex.DecodeString(text)
	return err == nil
}

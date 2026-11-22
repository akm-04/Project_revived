//go:build postgres

package otastore_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/otastore"
	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const nativeLedgerPath = "i11a_l2_native/res/web/a.png"

func ledgerPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_L2_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_L2_DSN required (ops/testing/fresh_db.sh i11a_l2_serving)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func runTransaction(t *testing.T, pool *pg.Pool, body func(tx.Tx) error) {
	t.Helper()
	current, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	profile := tx.Profile{Name: "i11a-l2-native", AcquireTimeout: 5 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 15 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: time.Minute}
	_, err = (tx.Runner{DB: pool}).Run(context.Background(), current, profile, tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(_ context.Context, scope tx.Scope) error {
		return body(scope.Tx)
	})
	if err != nil {
		t.Fatal(err)
	}
}

func cleanLedger(t *testing.T, pool *pg.Pool) {
	t.Helper()
	ctx := context.Background()
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_asset_misses WHERE path LIKE 'i11a_l2_native_%'`); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_asset_served_daily WHERE path LIKE 'i11a_l2_native_%'`); err != nil {
		t.Fatal(err)
	}
}

func TestNativeLedgerFlushUpserts(t *testing.T) {
	pool := ledgerPool(t)
	cleanLedger(t, pool)
	t.Cleanup(func() { cleanLedger(t, pool) })
	ctx := context.Background()
	at := time.Date(2026, 11, 20, 12, 0, 0, 0, time.UTC)
	ledger := appotarelease.NewLedger(tx.Runner{DB: pool}, operation.Factory{Clock: clock.System{}}, otastore.LedgerStore{})
	ledger.Now = func() time.Time { return at }

	ledger.RecordServed(nativeLedgerPath, at)
	ledger.RecordServed(nativeLedgerPath, at)
	ledger.RecordMiss(nativeLedgerPath, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", at)
	ledger.RecordMiss(nativeLedgerPath, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", at.Add(time.Minute))
	if err := ledger.Flush(ctx); err != nil {
		t.Fatal(err)
	}
	var servedHits, missHits int64
	var firstSeen time.Time
	if err := pool.Raw().QueryRow(ctx, `SELECT hits FROM ota_asset_served_daily WHERE path=$1 AND day=$2::date`, nativeLedgerPath, "2026-11-20").Scan(&servedHits); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT hits, first_seen FROM ota_asset_misses WHERE path=$1 AND md5=$2`, nativeLedgerPath, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb").Scan(&missHits, &firstSeen); err != nil {
		t.Fatal(err)
	}
	if servedHits != 2 || missHits != 2 || !firstSeen.Equal(at) {
		t.Fatalf("served=%d miss=%d first_seen=%s", servedHits, missHits, firstSeen)
	}

	ledger.RecordServed(nativeLedgerPath, at)
	ledger.RecordMiss(nativeLedgerPath, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", at.Add(2*time.Minute))
	if err := ledger.Flush(ctx); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT hits FROM ota_asset_served_daily WHERE path=$1 AND day=$2::date`, nativeLedgerPath, "2026-11-20").Scan(&servedHits); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT hits FROM ota_asset_misses WHERE path=$1 AND md5=$2`, nativeLedgerPath, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb").Scan(&missHits); err != nil {
		t.Fatal(err)
	}
	if servedHits != 3 || missHits != 3 {
		t.Fatalf("after second flush served=%d miss=%d", servedHits, missHits)
	}
}

func TestNativeLedgerPurgeKeepsTheFifteenDayWindow(t *testing.T) {
	pool := ledgerPool(t)
	cleanLedger(t, pool)
	t.Cleanup(func() { cleanLedger(t, pool) })
	ctx := context.Background()
	now := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	oldMiss := "i11a_l2_native/old.png"
	newMiss := "i11a_l2_native/new.png"
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ota_asset_misses(path,md5,first_seen,last_seen,hits) VALUES
($1,'', $2, $2, 1), ($3,'', $4, $4, 1)`, oldMiss, now.Add(-20*24*time.Hour), newMiss, now.Add(-2*24*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ota_asset_served_daily(path,day,hits) VALUES
($1, ($2::timestamptz - interval '20 days')::date, 1), ($1, $2::timestamptz::date, 1)`, nativeLedgerPath, now); err != nil {
		t.Fatal(err)
	}
	cutoff := now.Add(-15 * 24 * time.Hour)
	store := retentionstore.Store{}
	var deletedMisses, deletedServed int64
	runTransaction(t, pool, func(transaction tx.Tx) error {
		var err error
		deletedMisses, err = store.DeleteExpiredOTAAssetMisses(ctx, transaction, cutoff)
		if err != nil {
			return err
		}
		deletedServed, err = store.DeleteExpiredOTAAssetServedDaily(ctx, transaction, cutoff)
		return err
	})
	if deletedMisses != 1 || deletedServed != 1 {
		t.Fatalf("deleted misses=%d served=%d", deletedMisses, deletedServed)
	}
	var oldCount, newCount, servedCount int64
	if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM ota_asset_misses WHERE path=$1`, oldMiss).Scan(&oldCount); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM ota_asset_misses WHERE path=$1`, newMiss).Scan(&newCount); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM ota_asset_served_daily WHERE path=$1`, nativeLedgerPath).Scan(&servedCount); err != nil {
		t.Fatal(err)
	}
	if oldCount != 0 || newCount != 1 || servedCount != 1 {
		t.Fatalf("old=%d new=%d served=%d", oldCount, newCount, servedCount)
	}
}

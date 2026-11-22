//go:build postgres && river

package retentionworker

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/testsupport/latency"
)

// TestNativeOTAPurgeUsesFixedFifteenDayWindow runs the production rules with a
// 7-day GXB_RETENTION_DAYS equivalent: a 10-day-old OTA row must survive,
// because OA-5 fixes the two OTA observability tables at 15 days.
func TestNativeOTAPurgeUsesFixedFifteenDayWindow(t *testing.T) {
	dsn := os.Getenv("GXB_I11A_L2_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_L2_DSN required (ops/testing/fresh_db.sh i11a_l2_ota_purge)")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "i11a-l2-ota-purge"})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	prefix := "i11a_l2_purge_"
	clean := func() {
		_, _ = pool.Raw().Exec(ctx, `DELETE FROM ota_asset_misses WHERE path LIKE $1`, prefix+"%")
		_, _ = pool.Raw().Exec(ctx, `DELETE FROM ota_asset_served_daily WHERE path LIKE $1`, prefix+"%")
	}
	clean()
	t.Cleanup(clean)
	now := time.Now().UTC()
	oldPath := prefix + "old.png"
	middlePath := prefix + "middle.png"
	newPath := prefix + "new.png"
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ota_asset_misses(path,md5,first_seen,last_seen,hits) VALUES
($1,'',$2,$2,1),($3,'',$4,$4,1),($5,'',$6,$6,1)`,
		oldPath, now.Add(-20*24*time.Hour), middlePath, now.Add(-10*24*time.Hour), newPath, now.Add(-2*24*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ota_asset_served_daily(path,day,hits) VALUES
($1,($2::timestamptz - interval '20 days')::date,1),
($3,($2::timestamptz - interval '10 days')::date,1),
($4,($2::timestamptz - interval '2 days')::date,1)`, oldPath, now, middlePath, newPath); err != nil {
		t.Fatal(err)
	}
	policies := retentionstore.Policies{RetentionDays: 7, CacheRetentionDays: 7, RunBudget: time.Minute, ProfileMediaHistoryDays: 7}
	sweeper := Sweeper{Begin: pool.Begin, Rules: NewRules(policies), Budget: time.Minute, Now: func() time.Time { return now }, Logf: t.Logf}
	sweeper.Run(ctx)

	countRows := func(query string) (oldCount, middleCount, newCount int64) {
		for path, count := range map[string]*int64{oldPath: &oldCount, middlePath: &middleCount, newPath: &newCount} {
			if err := pool.Raw().QueryRow(ctx, query, path).Scan(count); err != nil {
				t.Fatal(err)
			}
		}
		return oldCount, middleCount, newCount
	}
	oldMisses, middleMisses, newMisses := countRows(`SELECT count(*) FROM ota_asset_misses WHERE path=$1`)
	if oldMisses != 0 || middleMisses != 1 || newMisses != 1 {
		t.Fatalf("misses old=%d middle=%d new=%d want 0/1/1", oldMisses, middleMisses, newMisses)
	}
	oldServed, middleServed, newServed := countRows(`SELECT count(*) FROM ota_asset_served_daily WHERE path=$1`)
	if oldServed != 0 || middleServed != 1 || newServed != 1 {
		t.Fatalf("served old=%d middle=%d new=%d want 0/1/1", oldServed, middleServed, newServed)
	}
}

// U2/A-039: the sweep must delete replay-only receipts faster than the 200 per
// second the API can create at full load. Seed 50 000 aged receipts and require
// at least 400 deletes per second.
func TestRetentionSweepReceiptThroughput(t *testing.T) {
	latency.Require(t, latency.Dedicated)
	dsn := os.Getenv("GXB_R8_4C_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_4C_DSN with a migrated disposable database is required")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Minute)
	defer cancel()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-4d-throughput"})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	owner, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	ownerKey := "r8-4d-throughput-" + owner.String()
	recordedAt := time.Now().Add(-48 * time.Hour).UTC()
	if _, err = pool.Raw().Exec(ctx, `INSERT INTO gxb_operation_receipts(receipt_id,operation_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,recorded_at,operation_policy_refs)
SELECT gen_random_uuid(),o.operation_id,'player',$1,'r8-4d-throughput','probe','R8_4D_PROBE',o.operation_id::text,decode(repeat('00',32),'hex'),'gxb.r8-4d.probe.v1','{}'::jsonb,$2,$2,'[]'::jsonb
FROM (SELECT gen_random_uuid() AS operation_id FROM generate_series(1,50000)) o`, ownerKey, recordedAt); err != nil {
		t.Fatal(err)
	}
	var before int64
	if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1`, ownerKey).Scan(&before); err != nil {
		t.Fatal(err)
	}
	if before != 50000 {
		t.Fatalf("seeded receipts=%d want 50000", before)
	}

	policies := retentionstore.Policies{RetentionDays: 1, CacheRetentionDays: 1, RunBudget: 5 * time.Minute, ProfileMediaHistoryDays: 1}
	sweeper := Sweeper{Begin: pool.Begin, Rules: NewRules(policies), Budget: policies.RunBudget, Now: time.Now, Logf: t.Logf}
	started := time.Now()
	sweeper.Run(ctx)
	elapsed := time.Since(started)

	var after int64
	if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1`, ownerKey).Scan(&after); err != nil {
		t.Fatal(err)
	}
	deleted := before - after
	seconds := elapsed.Seconds()
	rate := float64(deleted) / seconds
	t.Logf("deleted %d receipts in %s: %.0f receipts per second", deleted, elapsed, rate)
	if deleted != before {
		t.Fatalf("deleted %d of %d seeded receipts", deleted, before)
	}
	latency.EnforceRate(t, latency.Dedicated, rate, 400)
}

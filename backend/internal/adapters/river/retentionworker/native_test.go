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

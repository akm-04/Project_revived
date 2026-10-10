//go:build postgres && river

package guildinvite_test

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

func TestWorkingP3PartialCleanupContinuationRollback(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8B_PARTIAL_DSN")
	if dsn == "" {
		t.Skip("fresh disposable populated mixed/lifecycle fixture")
	}
	c, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	runner := tx.Runner{DB: p}
	rev, e := (contentstore.Store{}).ActiveRevision(c, p)
	if e != nil {
		t.Fatal(e)
	}
	bundle, e := guildinvitebundle.Prepare(c, p, runner, rev)
	if e != nil {
		t.Fatal(e)
	}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	var raw string
	if e = p.QueryRow(c, `SELECT marker_id::text FROM guild_invite_projection_markers ORDER BY event_id DESC LIMIT 1`).Scan(&raw); e != nil {
		t.Fatal(e)
	}
	id, _ := ids.ParseUUID(raw)
	store := guildinvitestore.Store{}
	cleanup := app.Cleanup{Timed: bundle.Target.Timed, Reads: runner, Sources: bundle.Source, Store: store, Players: i4store.PlayerRootLocker{}, Target: bundle.Target, Receipts: kernelstore.Store{}, Enqueue: queue}
	bad := cleanup
	bad.Enqueue = failAfterEnqueue{Queue: queue}
	if e = bad.RunBatch(c, id, 1); e == nil {
		t.Fatal("continuation enqueue failure hid source cursor effect")
	}
	_, before, ok, e := store.ReadMarkerTx(c, p, id)
	if e != nil || !ok || before.CursorSerial != 0 || before.CursorProof != nil || before.Complete {
		t.Fatal(before, ok, e)
	}
	if e = cleanup.RunBatch(c, id, 1); e != nil {
		t.Fatal(e)
	}
	m, partial, ok, e := store.ReadMarkerTx(c, p, id)
	if e != nil || !ok || partial.CursorSerial == 0 || partial.Complete || partial.CursorProof == nil {
		t.Fatal(partial, ok, e)
	}
	if e = bundle.Source.ValidateCoveredEvidenceTx(c, p, bundle.Target, m, partial); e != nil {
		t.Fatal(e)
	}
	t.Log("REAL_PG target page persists independently while continuation enqueue rollback preserves cursor0; replay ACKs retained page proof and leaves partial cursor for whole backup recovery")
}

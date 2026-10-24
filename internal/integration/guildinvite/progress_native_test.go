//go:build postgres && river

package guildinvite_test

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	target "gxb.local/backend/v2/internal/application/guildinvitetarget"
	"gxb.local/backend/v2/internal/application/socialrelation"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

func TestWorkingP3SourceACKAndProvenCleanupCursor(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8B_PROGRESS_DSN")
	if dsn == "" {
		t.Skip("fresh target/cleanup working fixture required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	w, _ := joinedTargets(t, c, p)
	guilds := []int64{int64(w.guildA), int64(w.guildB), int64(w.guildC)}
	store := guildinvitestore.Store{}
	kernel := kernelstore.Store{}
	roots := i4store.PlayerRootLocker{}
	reader := app.SourceReader{Store: store, Bindings: guildstore.Store{Queryer: p}, Receipts: kernel, Content: contentstore.Store{}}
	timed := gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}
	service := target.Service{Timed: timed, Reads: tx.Runner{DB: p}, Sources: reader, Players: roots, Roots: socialrelation.RootService{Store: socialrelationstore.Store{}}, Store: socialinboxstore.Store{}, Receipts: kernel}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	// Only derivative wakeups are aged in this disposable scheduling fixture.
	if _, e = p.Raw().Exec(c, `UPDATE guild_invite_projection_deliveries SET next_wakeup_at=last_enqueue_at WHERE state='PENDING'`); e != nil {
		t.Fatal(e)
	}
	if _, e = p.Raw().Exec(c, `UPDATE guild_invite_projection_markers SET next_wakeup_at=last_enqueue_at WHERE state='PENDING'`); e != nil {
		t.Fatal(e)
	}
	provider := app.Reconciler{Runner: tx.Runner{DB: p}, Store: store, Sources: reader, Target: service, Enqueue: queue}
	timedOp, e := timed.Binder.Bind(c, mustOp(t, policy.Set{}))
	if e != nil {
		t.Fatal(e)
	}
	var beforeJobs int64
	p.QueryRow(c, `SELECT count(*) FROM river_job`).Scan(&beforeJobs)
	bad := provider
	bad.Enqueue = failAfterEnqueue{Queue: queue}
	if _, e = bad.Reconcile(c, timedOp, 2); e == nil {
		t.Fatal("failed enqueue advanced pending scheduling")
	}
	var afterJobs int64
	p.QueryRow(c, `SELECT count(*) FROM river_job`).Scan(&afterJobs)
	if beforeJobs != afterJobs {
		t.Fatal("enqueue rollback leaked")
	}
	scanned := 0
	for attempts := 0; attempts < 30; attempts++ {
		r, e := provider.Reconcile(c, timedOp, 2)
		if e != nil || r.Scanned > 2 || r.Scanned != r.Wakeups {
			t.Fatal(r, e)
		}
		scanned += r.Scanned
		if r.Scanned == 0 {
			break
		}
	}
	if scanned < 2 {
		t.Fatal("canonical pending fallback scanned no work", scanned)
	}
	delivery := app.Delivery{Timed: timed, Reads: tx.Runner{DB: p}, Store: store, Sources: reader, Players: roots, Target: service}
	rows, e := p.Raw().Query(c, `SELECT source_id::text FROM guild_invite_projection_sources WHERE guild_id=ANY($1) ORDER BY source_serial`, guilds)
	if e != nil {
		t.Fatal(e)
	}
	var sources []ids.UUID
	for rows.Next() {
		var raw string
		if e = rows.Scan(&raw); e != nil {
			t.Fatal(e)
		}
		id, _ := ids.ParseUUID(raw)
		sources = append(sources, id)
	}
	rows.Close()
	if e = rows.Err(); e != nil {
		t.Fatal(e)
	}
	for i, id := range sources {
		proof, e := service.Materialize(c, id)
		if e != nil {
			t.Fatal(e)
		}
		if i == 0 {
			wrong := proof
			wrong.ReceiptID, _ = ids.NewUUID()
			if e = delivery.Acknowledge(c, id, wrong); e == nil {
				t.Fatal("accepted caller-only proof")
			}
			absent := delivery
			absent.Timed.Runner.DB = uncertainDB{Pool: p, Committed: false}
			e = absent.Acknowledge(c, id, proof)
			var unknown *tx.UnknownCommitError
			if !errors.As(e, &unknown) {
				t.Fatal("missing ACK UNKNOWN granted", e)
			}
			positive := delivery
			positive.Timed.Runner.DB = uncertainDB{Pool: p, Committed: true}
			if e = positive.Acknowledge(c, id, proof); e != nil {
				t.Fatal("positive ACK UNKNOWN", e)
			}
		}
		if e = delivery.Acknowledge(c, id, proof); e != nil {
			t.Fatal(e)
		}
		d, ok, e := store.ReadDeliveryTx(c, p, id)
		if e != nil || !ok || d.State == gi.Pending || d.Matches(proof) != nil {
			t.Fatal(d, ok, e)
		}
	}
	cleanup := app.Cleanup{Timed: timed, Reads: tx.Runner{DB: p}, Sources: reader, Store: store, Players: roots, Target: service, Receipts: kernel, Enqueue: queue}
	rows, e = p.Raw().Query(c, `SELECT marker_id::text FROM guild_invite_projection_markers WHERE guild_id=ANY($1) ORDER BY event_id`, guilds)
	if e != nil {
		t.Fatal(e)
	}
	var markers []ids.UUID
	for rows.Next() {
		var raw string
		if e = rows.Scan(&raw); e != nil {
			t.Fatal(e)
		}
		id, _ := ids.ParseUUID(raw)
		markers = append(markers, id)
	}
	rows.Close()
	if e = rows.Err(); e != nil {
		t.Fatal(e)
	}
	var covered ids.UUID
	for _, id := range markers {
		for attempts := 0; attempts < 100; attempts++ {
			if e = cleanup.RunBatch(c, id, 1); e != nil {
				t.Fatal("cleanup", id, e)
			}
			m, progress, ok, e := store.ReadMarkerTx(c, p, id)
			if e != nil || !ok {
				t.Fatal(e)
			}
			if e = reader.ValidateCursorEvidenceTx(c, p, m, progress); e != nil {
				t.Fatal(e)
			}
			if progress.Complete {
				if progress.CursorProof == nil {
					t.Fatal("completion has no retained Foundation witness")
				}
				if progress.CursorProof.Request.Covered.Count > 0 {
					covered = id
				}
				break
			}
			if attempts == 99 {
				t.Fatal("cleanup failed to converge")
			}
		}
		if e = cleanup.RunBatch(c, id, 1); e != nil {
			t.Fatal("complete replay", e)
		}
	}
	if covered.IsZero() {
		t.Fatal("no populated cleanup coverage")
	}
	corrupt, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer corrupt.Rollback(c)
	m, progress, ok, e := store.ReadMarkerTx(c, corrupt, covered)
	if e != nil || !ok {
		t.Fatal(e)
	}
	if _, e = corrupt.Exec(c, `DELETE FROM social_guild_invite_invalidations WHERE marker_id=$1::uuid AND source_id=(SELECT source_id FROM social_guild_invite_invalidations WHERE marker_id=$1::uuid LIMIT 1)`, covered.String()); e != nil {
		t.Fatal(e)
	}
	if e = service.ValidateCoveredInviteInvalidationsTx(c, corrupt, m, progress.CursorSerial, progress.CursorProof.Request.Covered); e == nil {
		t.Fatal("complete cursor hid missing earlier-page target proof")
	}
	if e = corrupt.Rollback(c); e != nil {
		t.Fatal(e)
	}
	corrupt, e = p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer corrupt.Rollback(c)
	if _, e = corrupt.Exec(c, `UPDATE gxb_operation_receipts SET operation_class='WRONG' WHERE receipt_id=$1::uuid`, progress.CursorProof.ReceiptID.String()); e != nil {
		t.Fatal(e)
	}
	if e = reader.ValidateCursorEvidenceTx(c, corrupt, m, progress); e == nil {
		t.Fatal("cursor accepted wrong Foundation witness")
	}
	if e = corrupt.Rollback(c); e != nil {
		t.Fatal(e)
	}
	for _, sql := range []string{
		`UPDATE guild_invite_projection_sources SET source_payload=jsonb_set(source_payload,'{GuildName}','"tampered"'::jsonb) WHERE source_id=(SELECT source_id FROM social_guild_invite_invalidations WHERE marker_id=$1::uuid LIMIT 1)`,
		`UPDATE gxb_operation_receipts SET operation_class='WRONG' WHERE receipt_id=(SELECT receipt_id FROM social_guild_invite_invalidations WHERE marker_id=$1::uuid LIMIT 1)`,
		`UPDATE social_guild_invite_materializations SET target_payload=jsonb_set(target_payload,'{RootVersion}','9999'::jsonb) WHERE source_id=(SELECT source_id FROM social_guild_invite_invalidations WHERE marker_id=$1::uuid AND notice_id IS NOT NULL LIMIT 1)`,
	} {
		corrupt, e = p.Begin(c, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		defer corrupt.Rollback(c)
		tag, e := corrupt.Exec(c, sql, covered.String())
		if e != nil || tag.RowsAffected() != 1 {
			t.Fatal("populated corrupt fixture", e)
		}
		if e = reader.ValidateCoveredEvidenceTx(c, corrupt, service, m, progress); e == nil {
			t.Fatal("completed earlier-page witness accepted mutated retained payload/Foundation")
		}
		if e = corrupt.Rollback(c); e != nil {
			t.Fatal(e)
		}
	}
	// Foundation witness canonicalization does not depend on connection timezone.
	original, e := reader.CoveredEvidenceTx(c, p, service, m, progress.CursorSerial, progress.CursorProof.Request.Covered)
	if e != nil {
		t.Fatal(e)
	}
	zone, e := p.Begin(c, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer zone.Rollback(c)
	if _, e = zone.Exec(c, `SET LOCAL TIME ZONE 'Asia/Tokyo'`); e != nil {
		t.Fatal(e)
	}
	changed, e := reader.CoveredEvidenceTx(c, zone, service, m, progress.CursorSerial, progress.CursorProof.Request.Covered)
	if e != nil || changed != original {
		t.Fatal("timezone changed immutable witness", e)
	}

}

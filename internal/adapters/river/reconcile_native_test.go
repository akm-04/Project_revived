//go:build postgres && river

package riveradapter

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildbroadcaststore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/content/registry"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"strconv"
	"testing"
	"time"
)

func TestRealPendingReconciliationBoundsAndBackwardsClock(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8_RECONCILE_DSN")
	if dsn == "" {
		t.Skip("explicit healthy disposable native fixture DSN required")
	}
	c, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	// A source of its own under a fresh occurrence, so no prior guild broadcast must exist. It deliberately has no job rows.
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	install, e := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = (registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}).EnsureBuiltinInstalled(c, install, bundle); e != nil {
		t.Fatal(e)
	}
	broadcast, e := (contentstore.Store{}).ReadBroadcastPolicy(c, p, bundle.RevisionID())
	if e != nil {
		t.Fatal(e)
	}
	now, e := (postgres.AuthoritativeTime{Queryer: p}).Now(c)
	if e != nil {
		t.Fatal(e)
	}
	now = now.UTC()
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: bundle.RevisionID()}, policy.Ref{Name: "guild-core", Version: broadcast.GuildCoreRevision}, policy.Ref{Name: "guild-broadcast", Version: gb.PolicyID})
	if e != nil {
		t.Fatal(e)
	}
	occurrence, e := (operation.Factory{Clock: clock.Fixed{T: now}}).New(refs)
	if e != nil {
		t.Fatal(e)
	}
	joined := now.Add(-time.Hour)
	leader := identity.PlayerID(100001)
	source := gb.Source{Operation: occurrence, GuildID: 1000001, Server: 1, LeaderID: leader, LeaderName: "leader", NameSnapshotChangedAt: joined, DecisionAt: now, ContentRevision: bundle.RevisionID(), GuildCoreRevision: broadcast.GuildCoreRevision, PolicyID: gb.PolicyID, Request: gb.Request{Title: "title", Content: "body"},
		Recipients: []gb.Member{{PlayerID: leader, JoinEventID: 1, JoinedAt: joined}, {PlayerID: leader + 1, JoinEventID: 2, JoinedAt: joined}}}
	due := now.Add(-2 * time.Minute)
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	result, _ := json.Marshal(app.SubmitResult{SourceID: source.Operation.ID, RecipientCount: 2})
	fp, _ := receipt.FingerprintRequest(source.Request)
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(source.LeaderID), 10), Domain: "guild-broadcast", Operation: "submit", SemanticKey: source.Operation.ID.String()}
	rr, e := receipt.New(source.Operation, id, "I7A8A_GUILD_SOURCE", "gxb.guild-broadcast.submit.v1", result, fp)
	if e != nil {
		t.Fatal(e)
	}
	rr.PolicyVersion = source.PolicyID
	if e = (guildbroadcaststore.Store{}).InsertSourceTx(c, x, source, rr.ID); e != nil {
		t.Fatal(e)
	}
	for _, m := range source.Recipients {
		b := gb.Binding{SourceID: source.Operation.ID, RecipientID: m.PlayerID, State: gb.Pending, LastEnqueueAt: due, NextWakeupAt: due.Add(time.Minute)}
		if e = (guildbroadcaststore.Store{}).InsertBindingTx(c, x, b, m); e != nil {
			t.Fatal(e)
		}
	}
	if _, e = (kernelstore.Store{}).PutTx(c, x, rr); e != nil {
		t.Fatal(e)
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	queue, e := NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	provider := app.Reconciler{Runner: tx.Runner{DB: p}, Store: guildbroadcaststore.Store{}, Sources: app.ImmutableSourceReader{Store: guildbroadcaststore.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}}, Enqueue: queue}
	factory := operation.Factory{Clock: clock.Fixed{T: now}}
	op, e := factory.New(policy.Set{})
	if e != nil {
		t.Fatal(e)
	}
	timed, e := gen.NewTimedOperation(op, now)
	if e != nil {
		t.Fatal(e)
	}
	for _, limit := range []int{0, 1001} {
		if _, e = provider.Reconcile(c, timed, limit); e == nil {
			t.Fatal("unbounded reconciliation", limit)
		}
	}
	first, e := provider.Reconcile(c, timed, 1)
	if e != nil || first.Scanned != 1 || first.Wakeups != 1 || first.Settled != 0 {
		t.Fatal(first, e)
	}
	second, e := provider.Reconcile(c, timed, 1)
	if e != nil || second.Scanned != 1 || second.Wakeups != 1 {
		t.Fatal("next due recipient starvation", second, e)
	}
	third, e := provider.Reconcile(c, timed, 1)
	if e != nil || third.Scanned != 0 || third.Wakeups != 0 {
		t.Fatal("not-before metadata ignored", third, e)
	}
	backwards, e := gen.NewTimedOperation(op, now.Add(-time.Hour))
	if e != nil {
		t.Fatal(e)
	}
	noWake, e := provider.Reconcile(c, backwards, 32)
	if e != nil || noWake.Wakeups != 0 {
		t.Fatal("backwards clock requeued", noWake, e)
	}
	var count int
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'semantic_key' LIKE $1`, source.Operation.ID.String()+":%").Scan(&count); e != nil || count != 2 {
		t.Fatal("missing jobs not rebuilt exactly", count, e)
	}
	for _, m := range source.Recipients {
		b, ok, e := (guildbroadcaststore.Store{}).ReadBindingTx(c, p, source.Operation.ID, m.PlayerID)
		if e != nil || !ok || b.State != gb.Pending || !b.LastEnqueueAt.Equal(now) || !b.NextWakeupAt.Equal(now.Add(time.Minute)) {
			t.Fatal("reconciliation falsely settled or changed deadline", b, ok, e)
		}
	}
	t.Log("REAL missing-job recovery, batch1 progress across recipients, limit bounds, UTC not-before60s and backwards clock; enqueue never settles recipient")
}

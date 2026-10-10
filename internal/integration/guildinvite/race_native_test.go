//go:build postgres && river

package guildinvite_test

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	"gxb.local/backend/v2/internal/application/guildcore"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"sync"
	"testing"
	"time"
)

func TestWorkingP3ConcurrentMaterializeJOINLeaveRetirement(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8B_RACE_DSN")
	if dsn == "" {
		t.Skip("fresh source3 disposable database")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 12, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	runner := tx.Runner{DB: p}
	content := contentstore.Store{Queryer: p}
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		t.Fatal(e)
	}
	bundle, e := guildinvitebundle.Prepare(c, p, runner, rev)
	if e != nil {
		t.Fatal(e)
	}
	artifact, e := guildpolicy.LoadBuiltin()
	if e != nil {
		t.Fatal(e)
	}
	binding, e := guildpolicybridge.FromBuiltin(artifact)
	if e != nil {
		t.Fatal(e)
	}
	gs := guildstore.Store{Queryer: p}
	store := guildinvitestore.Store{}
	kernel := kernelstore.Store{}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	projection := app.SourceService{Reads: runner, Store: store, Bindings: gs, History: kernel, Reader: bundle.Source, Content: content, Queryer: p, Enqueue: queue}
	i5db := i5store.Store{Queryer: p}
	cross := i5.CrossOwner{Store: i5db}
	core := guildcore.Service{Timed: bundle.Target.Timed, Store: gs, Fencer: i5db, PlayerRoots: i4store.PlayerRootLocker{}, Level: cross, Scalar: cross, LevelAndScalar: cross, Receipts: kernel, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding, InviteProjection: &projection}
	cleanup := app.Cleanup{Timed: core.Timed, Reads: runner, Sources: bundle.Source, Store: store, Players: i4store.PlayerRootLocker{}, Target: bundle.Target, Receipts: kernel, Enqueue: queue}
	var pid int64
	p.QueryRow(c, `SELECT max(player_id) FROM players`).Scan(&pid)
	leader := savedActor(t, c, p, identity.PlayerID(pid))
	recipient := savedActor(t, c, p, identity.PlayerID(pid-1))
	for iteration := 0; iteration < 4; iteration++ {
		created, e := core.Create(c, leader, guildcore.CreateRequest{Name: fmt.Sprintf("race%d", iteration), Icon: binding.Policy.GuildIcons[0]}, mustOp(t, policy.Set{}))
		if e != nil {
			t.Fatal(e)
		}
		invite := mustOp(t, policy.Set{})
		if _, e = core.Invite(c, leader, recipient.PlayerID, invite); e != nil {
			t.Fatal(e)
		}
		source, e := bundle.Source.ReadIssueEvidenceTx(c, p, invite.ID)
		if e != nil {
			t.Fatal(e)
		}
		// Marker preparation refuses a stale bound instant after observing this
		// current qualified source, without resampling the clock or adding effects.
		prepared, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		g, ok, e := gs.ReadGuildTx(c, prepared, guild.ID(created.GuildID))
		if e != nil || !ok {
			t.Fatal(e)
		}
		stale := mustOp(t, source.Operation.Policies)
		stale.StartedAt = source.Operation.StartedAt.Add(-time.Second)
		if _, e = projection.PrepareMarkerTx(c, prepared, g, leader, leader.PlayerID, gi.Retire, stale, source.DecisionAt.Add(-time.Microsecond)); e == nil {
			t.Fatal("backclock marker accepted")
		}
		prepared.Rollback(c)
		lifecycle := mustOp(t, policy.Set{})
		start := make(chan struct{})
		var wg sync.WaitGroup
		var targetErr, sourceErr error
		wg.Add(2)
		go func() { defer wg.Done(); <-start; _, targetErr = bundle.Target.Materialize(c, invite.ID) }()
		go func() {
			defer wg.Done()
			<-start
			if iteration == 0 {
				_, sourceErr = core.AcceptInvite(c, recipient, guild.ID(created.GuildID), lifecycle)
			} else {
				_, sourceErr = core.Dissolve(c, leader, lifecycle)
			}
		}()
		close(start)
		wg.Wait()
		if targetErr != nil || sourceErr != nil {
			t.Fatal("concurrent body", targetErr, sourceErr)
		}
		if e = cleanup.RunBatch(c, lifecycle.ID, 32); e != nil {
			t.Fatal(e)
		}
		snapshot, e := bundle.Source.ReadInviteSnapshotTx(c, p, invite.ID)
		if e != nil {
			t.Fatal(e)
		}
		at, e := (postgres.AuthoritativeTime{Queryer: p}).Now(c)
		if e != nil {
			t.Fatal(e)
		}
		eligible, e := snapshot.Eligible(at)
		if e != nil || eligible {
			t.Fatal("race left eligible old source", eligible, e)
		}
		proof, e := bundle.Target.Materialize(c, invite.ID)
		if e != nil {
			t.Fatal("terminal target replay", e)
		}
		var active int64
		p.QueryRow(c, `SELECT count(*) FROM social_notices WHERE recipient_player_id=$1 AND source_kind='guild.invite.v1' AND source_key=$2 AND active`, int64(recipient.PlayerID), mustSourceKey(t, source.Tuple)).Scan(&active)
		if active != 0 {
			t.Fatal("target resurrection", proof)
		}
		if iteration == 0 {
			if _, e = core.Leave(c, recipient, mustOp(t, policy.Set{})); e != nil {
				t.Fatal(e)
			}
			snapshot, e = bundle.Source.ReadInviteSnapshotTx(c, p, invite.ID)
			if e != nil {
				t.Fatal(e)
			}
			eligible, e = snapshot.Eligible(at)
			if e != nil || eligible {
				t.Fatal("JOIN then leave restored eligibility", e)
			}
			if _, e = core.Dissolve(c, leader, mustOp(t, policy.Set{})); e != nil {
				t.Fatal(e)
			}
		}
	}
	t.Log("REAL_PG concurrent materialization/JOIN and materialization/retirement serialize through315 or SSI; canonical read excludes invalid source immediately; cleanup and replay cannot resurrect; later leave preserves permanent JOIN boundary")
}
func mustSourceKey(t *testing.T, v gi.Tuple) string {
	t.Helper()
	s, e := v.SourceKey()
	if e != nil {
		t.Fatal(e)
	}
	return s
}

//go:build postgres && river

package guildinvite_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

type failAfterEnqueue struct{ Queue obligation.Queue }

func (q failAfterEnqueue) InsertTx(c context.Context, t tx.Tx, o obligation.Obligation) error {
	if e := q.Queue.InsertTx(c, t, o); e != nil {
		return e
	}
	return errors.New("injected after real transactional River insertion")
}

func TestWorkingP2ActualFiveProducerHooksAndAtomicRiverRollback(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8B_SOURCE_DSN")
	if dsn == "" {
		t.Skip("fresh disposable38 source-only working database required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	countJobs := func() int64 {
		var n int64
		if e := p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'obligation_kind' IN ('guild.invite.notice.v1','guild.invite.cleanup.v1')`).Scan(&n); e != nil {
			t.Fatal(e)
		}
		return n
	}
	before := countJobs()
	w := seedWorld(t, c, p)
	jobs := countJobs() - before
	actors, service, queue := w.actors, w.core, w.queue
	store := guildinvitestore.Store{}
	gs := guildstore.Store{Queryer: p}
	// Source/core/I5 effects plus an already inserted real job must all roll
	// back when the final source enqueue stage fails.
	failingProjection := w.projection
	failingProjection.Enqueue = failAfterEnqueue{Queue: queue}
	failing := service
	failing.InviteProjection = &failingProjection
	failedOp := mustOp(t, w.refs)
	if _, e = failing.Create(c, actors[7], guildcore.CreateRequest{Name: fmt.Sprintf("F%d", actors[0].PlayerID), Icon: service.Policy.Policy.GuildIcons[0]}, failedOp); e == nil {
		t.Fatal("injected enqueue failure accepted")
	}
	if _, _, exists, e := store.ReadMarkerTx(c, p, failedOp.ID); e != nil || exists {
		t.Fatal("aborted marker visible", exists, e)
	}
	if _, exists, e := gs.ReadMembership(c, actors[7].PlayerID); e != nil || exists {
		t.Fatal("failed Create left membership", exists, e)
	}
	var balance, afterJobs int64
	if e = p.QueryRow(c, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(actors[7].PlayerID)).Scan(&balance); e != nil || balance != 10000 {
		t.Fatal("failed Create charged currency", balance, e)
	}
	if afterJobs = countJobs() - before; afterJobs != jobs {
		t.Fatal("aborted River job visible", jobs, afterJobs)
	}
	var issues, markers int64
	guilds := []int64{int64(w.guildA), int64(w.guildB), int64(w.guildC)}
	if e = p.QueryRow(c, `SELECT count(*) FROM guild_invite_projection_sources WHERE guild_id=ANY($1)`, guilds).Scan(&issues); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM guild_invite_projection_markers WHERE guild_id=ANY($1)`, guilds).Scan(&markers); e != nil {
		t.Fatal(e)
	}
	if issues != 2 || markers != 7 || jobs != 9 {
		t.Fatal("source/marker/job cardinality", issues, markers, jobs)
	}
	t.Log(fmt.Sprintf("WORKING_SOURCE_ONLY: all4JOIN + Invite + Retire;2issues,7markers,9finite real jobs; I5/River rollback; no target consumer or frozen gate credit"))
}

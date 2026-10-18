//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	gen "gxb.local/backend/v2/internal/application/generation"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sync"
	"testing"
)

func metricProvider(p *pg.Pool) app.CanonicalMetricProvider {
	return app.CanonicalMetricProvider{Creation: app.CanonicalCreationMetricProvider{Players: i5store.Store{}}, Library: achievementLibraryService(p, p)}
}
func metricCommands(p *pg.Pool, db tx.Beginner) app.CommandService {
	return app.CommandService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Fresh: p, Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}, Metrics: metricProvider(p)}
}
func readMetrics(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, ids []int64) ([]app.MetricObservation, error) {
	t.Helper()
	at, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	var out []app.MetricObservation
	_, e = (tx.Runner{DB: p}).Run(ctx, opPinned(rev), lib.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out, e = metricProvider(p).ReadMetricsScopeTx(c, sc, app.MetricRequest{PlayerID: a.PlayerID, IDs: ids, ContentRevision: rev, ObservedAt: at})
		return e
	})
	return out, e
}
func marryMetric(t *testing.T, p *pg.Pool, a identity.ActorContext) {
	t.Helper()
	favorForMarriage(t, p, a, 1)
	if _, e := achievementLibraryService(p, p).Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}, op()); e != nil {
		t.Fatal(e)
	}
}
func TestI7C4CActualMarriageMetricReceiptReplayAndRecompute(t *testing.T) {
	p := pool(t)
	a, rev := achievementFixture(t, p, true)
	s := metricCommands(p, p)
	q := app.Command{Kind: app.ShowCommand, Show: []int64{1010, 1011}}
	o := op()
	before, e := s.Execute(ctx, a, q, o)
	if e != nil || before.Show["1010"] != 0 || len(before.MetricObservations) != 2 || before.MetricObservations[0].PopulationVersion <= 0 {
		t.Fatal(before, e)
	}
	marryMetric(t, p, a)
	replay, e := s.Execute(ctx, a, q, o)
	if e != nil || !reflect.DeepEqual(before, replay) {
		t.Fatal("receipt changed with currentpopulation", replay, e)
	}
	values, e := readMetrics(t, p, a, rev, []int64{1010, 1011})
	if e != nil || values[0].Value != 1 || values[0].LibraryRootVersion <= before.MetricObservations[0].LibraryRootVersion || values[1].Value != before.Show["1011"] {
		t.Fatal(values, e)
	}
	fresh, e := s.Execute(ctx, a, q, op())
	if e != nil || fresh.Show["1010"] != 1 {
		t.Fatal(fresh, e)
	}
	// No-op source replay cannot increment currentpopulation or turn it into trophyhighwater.
	if _, e := achievementLibraryService(p, p).Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}, op()); e != nil {
		t.Fatal(e)
	}
	after, e := readMetrics(t, p, a, rev, []int64{1010})
	if e != nil || after[0].Value != 1 {
		t.Fatal(after, e)
	}
	for _, id := range []int64{1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009} {
		if _, e := s.Execute(ctx, a, app.Command{Kind: app.ShowCommand, Show: []int64{id}}, op()); e == nil {
			t.Fatal("unqualifiedmetric", id)
		}
	}
}
func TestI7C4CLegacyUnknownZeroAndRollback(t *testing.T) {
	p := pool(t)
	a, rev := achievementFixture(t, p, false)
	s := metricCommands(p, p)
	exec(t, p, `DELETE FROM player_library_heroes WHERE player_id=$1`, int64(a.PlayerID))
	if _, e := s.Execute(ctx, a, app.Command{Kind: app.ShowCommand, Show: []int64{1010}}, op()); e == nil {
		t.Fatal("missingfacet becamezero")
	}
	r, found, e := (publicprofilestore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || found {
		t.Fatal("failedselectionwrote", r, found, e)
	}
	if _, e := readMetrics(t, p, a, rev, []int64{1010}); e == nil {
		t.Fatal("incompletepopulationqualified")
	}
	if _, e := s.Execute(ctx, a, app.Command{Kind: app.ShowCommand, Show: []int64{1011}}, op()); e != nil {
		t.Fatal("legacycreationregression", e)
	}
	// DB failure after owner reads must roll back preference and receipt together.
	a2, _ := achievementFixture(t, p, false)
	q := app.Command{Kind: app.ShowCommand, Show: []int64{1010}}
	o := op()
	db := metricCommitDB{Beginner: p, commit: false}
	_, e = metricCommands(p, db).Execute(ctx, a2, q, o)
	if e == nil {
		t.Fatal("rollback fault succeeded")
	}
	_, found, e = (publicprofilestore.Store{}).ReadRootTx(ctx, p, a2.PlayerID)
	if e != nil || found {
		t.Fatal("rollback root leaked", e)
	}
}

type metricCommitDB struct {
	tx.Beginner
	commit bool
}

func (d metricCommitDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	v, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return faultTx{Tx: v, commit: d.commit}, nil
}
func TestI7C4CUnknownCommitPositiveProof(t *testing.T) {
	p := pool(t)
	a, _ := achievementFixture(t, p, false)
	q := app.Command{Kind: app.ShowCommand, Show: []int64{1010}}
	o := op()
	first, e := metricCommands(p, metricCommitDB{p, true}).Execute(ctx, a, q, o)
	if e != nil || first.Show["1010"] != 0 {
		t.Fatal(first, e)
	}
	again, e := metricCommands(p, p).Execute(ctx, a, q, o)
	if e != nil || !reflect.DeepEqual(first, again) {
		t.Fatal(again, e)
	}
}
func TestI7C4CCoherentSnapshotAcrossActualMarriage(t *testing.T) {
	p := pool(t)
	a, rev := achievementFixture(t, p, false)
	favorForMarriage(t, p, a, 1)
	at, _ := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), lib.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		q := app.MetricRequest{PlayerID: a.PlayerID, IDs: []int64{1010}, ContentRevision: rev, ObservedAt: at}
		before, e := metricProvider(p).ReadMetricsScopeTx(c, sc, q)
		if e != nil || before[0].Value != 0 {
			return errors.New("initialsnapshot")
		}
		if _, e := achievementLibraryService(p, p).Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}, op()); e != nil {
			return e
		}
		after, e := metricProvider(p).ReadMetricsScopeTx(c, sc, q)
		if e != nil || !reflect.DeepEqual(before, after) {
			return errors.New("mixed owner generations")
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	fresh, e := readMetrics(t, p, a, rev, []int64{1010})
	if e != nil || fresh[0].Value != 1 {
		t.Fatal(fresh, e)
	}
}
func TestI7C4CConcurrentSelectionsAndFutureOwner(t *testing.T) {
	p := pool(t)
	a, rev := achievementFixture(t, p, false)
	var wg sync.WaitGroup
	errs := make(chan error, 3)
	for i := 0; i < 3; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := metricCommands(p, p).Execute(ctx, a, app.Command{Kind: app.ShowCommand, Show: []int64{1010}}, op())
			errs <- e
		}()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	exec(t, p, `UPDATE player_library_roots SET updated_at=clock_timestamp()+interval '1 day' WHERE player_id=$1`, int64(a.PlayerID))
	if _, e := readMetrics(t, p, a, rev, []int64{1010}); e == nil {
		t.Fatal("future owner qualified")
	}
}

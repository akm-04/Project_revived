//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"
)

func achievementService(p *pg.Pool) ach.Service {
	return ach.Service{Store: achievementstore.Store{}, Content: contentstore.Store{}, Population: libraryService(p, p)}
}

// The actor/unmarried Hero/inventory are explicit test prerequisites. All favor
// and marriage effects, ring costs and trophies are produced by real Library
// commands. This does not qualify unresolved Hero acquisition-capacity policy.
func achievementFixture(t *testing.T, p *pg.Pool, tracked bool) (identity.ActorContext, string) {
	a, rev := libraryFixture(t, p, false)
	if tracked {
		tr, e := p.Begin(ctx, tx.Options{})
		if e != nil {
			t.Fatal(e)
		}
		defer tr.Rollback(ctx)
		if e = (achievementstore.BootstrapContributor{Revision: rev}).PersistCharacterBootstrap(ctx, tr, logicalserver.BootstrapContext{PlayerID: a.PlayerID, Operation: op()}); e != nil {
			t.Fatal(e)
		}
		if e = tr.Commit(ctx); e != nil {
			t.Fatal(e)
		}
	}
	return a, rev
}
func favorForMarriage(t *testing.T, p *pg.Pool, a identity.ActorContext, partner int64) {
	t.Helper()
	s := libraryService(p, p)
	for i := 0; i < 22; i++ {
		if _, e := s.Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: partner, Value: 50005013}, op()); e != nil {
			t.Fatal("favor", partner, i, e)
		}
	}
}
func achievementRoot(t *testing.T, p *pg.Pool, a identity.ActorContext) d.Root {
	r, ok, e := (achievementstore.Store{}).ReadRootTx(ctx, p, a.PlayerID, false)
	if e != nil || !ok {
		t.Fatal(r, ok, e)
	}
	return r
}
func achievementEvents(t *testing.T, p *pg.Pool, a identity.ActorContext) int {
	var n int
	if e := p.QueryRow(ctx, `SELECT count(*) FROM achievement_events WHERE player_id=$1`, int64(a.PlayerID)).Scan(&n); e != nil {
		t.Fatal(e)
	}
	return n
}
func readAchievement(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, q ach.Request, at time.Time) (ach.Observation, error) {
	t.Helper()
	var out ach.Observation
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), lib.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		co, e := ca.NewCoherentReadScope(sc, rev, at)
		if e != nil {
			return e
		}
		out, e = achievementService(p).ReadTierFactsTx(c, co, q)
		return e
	})
	return out, e
}
func TestI7C4BGenuineLibraryAllTiersReplayAndUnavailable(t *testing.T) {
	p := pool(t)
	a, rev := achievementFixture(t, p, true)
	q := ach.Request{Player: a.PlayerID, AchievementID: 100014}
	before, e := readAchievement(t, p, a, rev, q, time.Now())
	if e != nil || before.Progress != 0 || len(before.UnavailableAchievementIDs) != 32 {
		t.Fatal(before, e)
	}
	for _, x := range before.Tiers {
		if x.Earned || x.CompleteTime != 0 {
			t.Fatal("fresh unearned", before)
		}
	}
	exec(t, p, `UPDATE player_item_stacks SET quantity=1000 WHERE player_id=$1 AND item_id=50005013`, int64(a.PlayerID))
	catalog, e := (contentstore.Store{}).LibraryCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	tables := []int64{}
	for id, r := range catalog.Templates {
		if id != 10001001 && id < 20000000 && r.DialogEnabled {
			tables = append(tables, id)
		}
	}
	sort.Slice(tables, func(i, j int) bool { return tables[i] < tables[j] })
	if len(tables) < 19 {
		t.Fatal("insufficient distinct canonical templates")
	}
	var first operation.Context
	var original lib.Result
	for n := 1; n <= 20; n++ {
		partner := int64(n)
		if n > 1 {
			h := skillHero(t, p, a, rev, tables[n-2], partner)
			tr, e := p.Begin(ctx, tx.Options{})
			if e != nil {
				t.Fatal(e)
			}
			if e = (librarystore.Store{}).InitFreshHeroTx(ctx, tr, h.Ref(), h.CreatedAt); e != nil {
				t.Fatal(e)
			}
			if e = tr.Commit(ctx); e != nil {
				t.Fatal(e)
			}
		}
		favorForMarriage(t, p, a, partner)
		o := op()
		r, e := libraryService(p, p).Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: partner, Value: 50001112}, o)
		if e != nil || !r.Married || !r.Changed {
			t.Fatal(n, r, e)
		}
		if n == 1 {
			first = o
			original = r
		}
		obs, e := readAchievement(t, p, a, rev, q, time.Now())
		if e != nil || obs.Progress != int64(n) {
			t.Fatal(n, obs, e)
		}
		for i, target := range []int{1, 10, 20} {
			if obs.Tiers[i].Earned != (n >= target) || obs.Tiers[i].Earned != (obs.Tiers[i].CompleteTime > 0) {
				t.Fatal(n, i, obs)
			}
		}
	}
	r := achievementRoot(t, p, a)
	if achievementEvents(t, p, a) != 20 || r.StateVersion != 21 {
		t.Fatal(r)
	}
	replay, e := libraryService(p, p).Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}, first)
	if e != nil || !reflect.DeepEqual(replay, original) {
		t.Fatal("replay", replay, e)
	}
	if achievementEvents(t, p, a) != 20 || !reflect.DeepEqual(achievementRoot(t, p, a), r) {
		t.Fatal("replay changed facts")
	}
	noop, e := libraryService(p, p).Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}, op())
	if e != nil || noop.Changed || achievementEvents(t, p, a) != 20 {
		t.Fatal("noop", noop, e)
	}
	q.CompleteCatalog = true
	if _, e = readAchievement(t, p, a, rev, q, time.Now()); !errors.Is(e, d.ErrUnavailable) {
		t.Fatal("partial promoted full", e)
	}
	q.CompleteCatalog = false
	q.AchievementID = 100001
	if _, e = readAchievement(t, p, a, rev, q, time.Now()); !errors.Is(e, d.ErrUnavailable) {
		t.Fatal("unqualified producer", e)
	}
	q.AchievementID = 100014
	if _, e = readAchievement(t, p, a, rev, q, r.CreatedAt.Add(-time.Second)); e == nil {
		t.Fatal("future state")
	}
	other := pool(t)
	out, e := readAchievement(t, other, a, rev, q, time.Now())
	if e != nil || out.Progress != 20 || !out.Tiers[2].Earned {
		t.Fatal("reload", out, e)
	}
}
func TestI7C4BLegacyHistoryUnavailableButSourceWorks(t *testing.T) {
	p := pool(t)
	a, rev := achievementFixture(t, p, false)
	favorForMarriage(t, p, a, 1)
	if _, e := libraryService(p, p).Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}, op()); e != nil {
		t.Fatal(e)
	}
	if achievementEvents(t, p, a) != 0 {
		t.Fatal("invented legacy event history")
	}
	if _, e := readAchievement(t, p, a, rev, ach.Request{Player: a.PlayerID, AchievementID: 100014}, time.Now()); !errors.Is(e, d.ErrUnavailable) {
		t.Fatal("legacy zero inferred", e)
	}
}

type failingAchievementStore struct{ achievementstore.Store }

func (failingAchievementStore) SaveRootTx(context.Context, tx.Tx, d.Root, int64) error {
	return errors.New("injected owner CAS failure")
}
func TestI7C4BAtomicRollbackAndRetainedRecovery(t *testing.T) {
	p := pool(t)
	a, _ := achievementFixture(t, p, true)
	favorForMarriage(t, p, a, 1)
	s := libraryService(p, p)
	bad := achievementService(p)
	bad.Store = failingAchievementStore{}
	s.Achievements = bad
	o := op()
	cmd := lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}
	if _, e := s.Command(ctx, a, cmd, o); e == nil {
		t.Fatal("missing failure")
	}
	if libraryFacts(t, p, a).Married || achievementRoot(t, p, a).Progress != 0 || achievementEvents(t, p, a) != 0 {
		t.Fatal("partial commit")
	}
	var quantity int64
	if e := p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001112`, int64(a.PlayerID)).Scan(&quantity); e != nil || quantity != 100 {
		t.Fatal(quantity, e)
	}
	r, e := libraryService(p, p).Command(ctx, a, cmd, op())
	if e != nil || r.OperationID != o.ID || achievementRoot(t, p, a).Progress != 1 || achievementEvents(t, p, a) != 1 {
		t.Fatal("retained recovery", r, e)
	}
}
func TestI7C4BUnknownCommitAndConcurrentReplay(t *testing.T) {
	p := pool(t)
	for _, committed := range []bool{true, false} {
		a, _ := achievementFixture(t, p, true)
		favorForMarriage(t, p, a, 1)
		o := op()
		cmd := lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}
		s := libraryService(p, &libraryFaultDB{Beginner: p, commit: committed})
		r, e := s.Command(ctx, a, cmd, o)
		if committed {
			if e != nil || !r.Married || achievementEvents(t, p, a) != 1 {
				t.Fatal("positive proof", r, e)
			}
		} else {
			var u *tx.UnknownCommitError
			if !errors.As(e, &u) || achievementEvents(t, p, a) != 0 || libraryFacts(t, p, a).Married {
				t.Fatal("unknown absent", e)
			}
			r, e = libraryService(pool(t), p).Command(ctx, a, cmd, op())
			if e != nil || r.OperationID != o.ID || achievementEvents(t, p, a) != 1 {
				t.Fatal("unknown recovery", r, e)
			}
		}
	}
	a, _ := achievementFixture(t, p, true)
	favorForMarriage(t, p, a, 1)
	s := libraryService(p, p)
	o := op()
	errs := make(chan error, 6)
	var wg sync.WaitGroup
	for i := 0; i < 6; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.Command(ctx, a, lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}, o)
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
	if achievementEvents(t, p, a) != 1 || achievementRoot(t, p, a).StateVersion != 2 {
		t.Fatal("duplicate concurrent effect")
	}
}

var _ = character.HeroRef{}

func TestI7C4BMissingHookAndEventConflict(t *testing.T) {
	p := pool(t)
	a, rev := achievementFixture(t, p, true)
	favorForMarriage(t, p, a, 1)
	s := libraryService(p, p)
	s.Achievements = nil
	o := op()
	cmd := lib.Command{Family: lib.Gift, PartnerID: 1, Value: 50001112}
	if _, e := s.Command(ctx, a, cmd, o); e == nil || achievementEvents(t, p, a) != 0 || libraryFacts(t, p, a).Married {
		t.Fatal("new content missing hook silently passed", e)
	}
	r, e := libraryService(p, p).Command(ctx, a, cmd, op())
	if e != nil {
		t.Fatal(e)
	}
	event, e := ach.NewEvent(lib.MarriageEvent{Player: a.PlayerID, PartnerID: 1, OldVersion: r.StateVersion - 1, NewVersion: r.StateVersion, OperationID: r.OperationID, ContentRevision: r.ContentRevision, DecisionAt: r.DecisionAt}, 1)
	if e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = (achievementstore.Store{}).PutEventTx(ctx, tr, event); e != nil {
		t.Fatal("exact event dedup", e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	event.Source.PartnerID = 2
	event, e = ach.NewEvent(event.Source, 1)
	if e != nil {
		t.Fatal(e)
	}
	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = (achievementstore.Store{}).PutEventTx(ctx, tr, event); !errors.Is(e, d.ErrConflict) {
		t.Fatal("same source event changed target", e)
	}
	_, e = (tx.Runner{DB: p}).Run(ctx, opPinned(rev), lib.Profile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		_, e := ca.NewCoherentReadScope(sc, rev, time.Now())
		return e
	})
	if e == nil {
		t.Fatal("readcommitted accepted")
	}
	_, e = (tx.Runner{DB: p}).Run(ctx, opPinned(rev), lib.Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		co, e := ca.NewCoherentReadScope(sc, strings.Repeat("a", 64), time.Now())
		if e != nil {
			return e
		}
		_, e = achievementService(p).ReadTierFactsTx(c, co, ach.Request{Player: a.PlayerID, AchievementID: 100014})
		return e
	})
	if e == nil {
		t.Fatal("content pin mismatch accepted")
	}
}

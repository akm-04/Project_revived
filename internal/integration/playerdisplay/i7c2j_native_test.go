//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/characterasset"
	app "gxb.local/backend/v2/internal/application/conquerschool"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sync"
	"testing"
	"time"
)

func conquerService(p *pg.Pool) app.Service {
	cs := contentstore.Store{Queryer: p}
	return app.Service{Owner: conquerstore.Store{}, Content: cs, Heroes: characterstore.Store{Queryer: p}, Kinds: cs, Players: i4store.PlayerRootLocker{}}
}
func conquerFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, app.Service) {
	t.Helper()
	rev := installed(t, p)
	a := actor(t, p)
	for i, id := range []int64{10001001, 11001} {
		skillHero(t, p, a, rev, id, int64(i+1))
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	o := opPinned(rev)
	if e = (conquerstore.BootstrapContributor{Revision: rev}).PersistCharacterBootstrap(ctx, tr, logicalserver.BootstrapContext{PlayerID: a.PlayerID, Operation: o, BootstrapProfileVersion: "NATIVE_FIXTURE_BOOTSTRAP"}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return a, rev, conquerService(p)
}
func conquerRead(t *testing.T, p *pg.Pool, s app.Service, a identity.ActorContext, rev string, id int64) (d.HeroInputs, error) {
	t.Helper()
	o := opPinned(rev)
	var out d.HeroInputs
	_, e := (tx.Runner{DB: p}).Run(ctx, o, app.Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := characterasset.NewCoherentReadScope(sc, rev, time.Now().UTC())
		if e != nil {
			return e
		}
		out, e = s.HeroInputsTx(c, scope, character.HeroRef{PlayerID: a.PlayerID, PartnerID: id})
		return e
	})
	return out, e
}

// This caller is qualification infrastructure. It does not qualify a genuine
// Conquer result, progression writer, or production source attestation.
func conquerFixtureWrite(p *pg.Pool, db tx.Beginner, a identity.ActorContext, rev string, o operation.Context, level, loop int64, fail bool, service *app.Service) (tx.Result, error) {
	id := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(a.PlayerID), Domain: "conquer-foundation-fixture", Operation: "RETAIN", SemanticKey: o.ID.String()}
	fp, _ := receipt.FingerprintRequest(map[string]any{"level": level, "loop": loop, "scope": "QUALIFICATION_FIXTURE_ONLY"})
	rs := kernelstore.Store{}
	svc := conquerService(p)
	if service != nil {
		svc = *service
	}
	return (tx.Runner{DB: db}).Run(ctx, o, app.Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true}, receipt.Resolver{Reader: kernelstore.Reader{Queryer: p}, Identity: id, Fingerprint: fp}, func(c context.Context, sc tx.Scope) error {
		r, found, e := rs.FindTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if found {
			if r.RequestFingerprint != fp {
				return errors.New("fixture semantic conflict")
			}
			return nil
		}
		pr, e := svc.PrepareWriteTx(c, sc.Tx, a.LogicalServerID, a.PlayerID, rev, o)
		if e != nil {
			return e
		}
		f, e := svc.ApplyWriteTx(c, sc.Tx, pr, d.Progress{Level: level, Loop: loop}, &d.Run{Loop: 1, CurrentID: 10002, PassedID: 10001, Generation: "FIXTURE-NOT-ACTUAL-ATTEMPT"}, "QUALIFICATION_FIXTURE_ONLY/no-mode-activation")
		if e != nil {
			return e
		}
		if fail {
			return errors.New("injected after owner write")
		}
		raw, _ := json.Marshal(f)
		r, e = receipt.New(o, id, "I7C2J_QUALIFICATION_FIXTURE_ONLY", "gxb.qualification.conquer.fixture.v1", raw, fp)
		if e != nil {
			return e
		}
		r.PolicyVersion = d.Policy
		r.RecordedAt = o.StartedAt
		_, e = rs.PutTx(c, sc.Tx, r)
		return e
	})
}
func TestI7C2JNativeInitialUnknownAndLegacyNoInference(t *testing.T) {
	p := pool(t)
	a, rev, s := conquerFixture(t, p)
	v, e := conquerRead(t, p, s, a, rev, 1)
	if e != nil || v.Hero.Kind != "NORMAL" || v.Observation.Facts.Payload.Kind != d.Initial || len(v.Observation.Contributions) != 0 || v.Observation.RunAvailable {
		t.Fatal(v, e)
	}
	legacy := actor(t, p)
	exec(t, p, `UPDATE player_directory_profiles SET conquer_lev=56,conquer_loop_id=2 WHERE player_id=$1`, int64(legacy.PlayerID))
	timed := gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}
	if e = app.RunBackfill(ctx, timed, i4store.PlayerRootLocker{}, conquerstore.Store{}, rev, op()); e != nil {
		t.Fatal(e)
	}
	f, e := (conquerstore.Store{}).ReadFactsTx(ctx, p, legacy.PlayerID)
	if e != nil || f.Payload.Kind != d.Unknown || f.Known() {
		t.Fatal("directory copied or missing", f, e)
	}
	initial, e := (conquerstore.Store{}).ReadFactsTx(ctx, p, a.PlayerID)
	if e != nil || !reflect.DeepEqual(initial, v.Observation.Facts) {
		t.Fatal("fresh overwritten", initial, e)
	}
	if e = app.RunBackfill(ctx, timed, i4store.PlayerRootLocker{}, conquerstore.Store{}, rev, op()); e != nil {
		t.Fatal(e)
	}
	after, _ := (conquerstore.Store{}).ReadFactsTx(ctx, p, legacy.PlayerID)
	if !reflect.DeepEqual(f, after) {
		t.Fatal("repeat changed", f, after)
	}
	o := opPinned(rev)
	_, e = (tx.Runner{DB: p}).Run(ctx, o, app.Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := characterasset.NewCoherentReadScope(sc, rev, time.Now().UTC())
		if e != nil {
			return e
		}
		_, e = s.FactsTx(c, scope, legacy.PlayerID)
		return e
	})
	if !errors.Is(e, d.ErrUnavailable) {
		t.Fatal("unknown became qualifiedzero", e)
	}
}
func TestI7C2JNativeRetainedNormalSuperRunAndCurrentSnapshot(t *testing.T) {
	p := pool(t)
	a, rev, s := conquerFixture(t, p)
	o := opPinned(rev)
	if r, e := conquerFixtureWrite(p, p, a, rev, o, 20, 1, false, nil); e != nil || r.Outcome != tx.DefiniteCommit {
		t.Fatal(r, e)
	}
	for _, id := range []int64{1, 2} {
		v, e := conquerRead(t, p, s, a, rev, id)
		if e != nil || v.Hero.Validate() != nil || v.Observation.Contributions[5] != 100 || v.Observation.Contributions[6] != 200 || v.Observation.Facts.Payload.Run.PassedID != 10001 || v.Observation.RunComplete {
			t.Fatal(v, e)
		}
		v.Observation.Facts.Payload.Progress.Level = 56
		v.Observation.Contributions[5] = 999
		again, e := conquerRead(t, p, s, a, rev, id)
		if e != nil || again.Observation.Contributions[5] != 100 {
			t.Fatal("alias", again, e)
		}
	}
	if _, e := conquerRead(t, p, s, a, rev, 999); e == nil {
		t.Fatal("retired/missing Hero accepted")
	}
	if _, e := conquerFixtureWrite(p, p, a, rev, opPinned(rev), 1, 2, false, nil); e != nil {
		t.Fatal(e)
	}
	v, e := conquerRead(t, p, s, a, rev, 1)
	if e != nil || v.Observation.Contributions[15] != 10 || v.Observation.Facts.Payload.Progress.Level != 1 {
		t.Fatal("source loop/translation distinction", v, e)
	}
	if r, e := conquerFixtureWrite(p, p, a, rev, o, 20, 1, false, nil); e != nil || r.Outcome != tx.DefiniteCommit {
		t.Fatal(r, e)
	}
	v, e = conquerRead(t, p, s, a, rev, 1)
	if e != nil || v.Observation.Facts.Version != 3 || v.Observation.Facts.Payload.Progress.Level != 1 {
		t.Fatal("receipt overwrote laterstate", v, e)
	}
}
func TestI7C2JNativeRollbackUnknownConcurrencyAndReceiptBeforeProvider(t *testing.T) {
	p := pool(t)
	for _, commit := range []bool{false, true} {
		a, rev, s := conquerFixture(t, p)
		o := opPinned(rev)
		before, _ := (conquerstore.Store{}).ReadFactsTx(ctx, p, a.PlayerID)
		if _, e := conquerFixtureWrite(p, p, a, rev, opPinned(rev), 20, 1, true, nil); e == nil {
			t.Fatal("faultmissing")
		}
		after, _ := (conquerstore.Store{}).ReadFactsTx(ctx, p, a.PlayerID)
		if !reflect.DeepEqual(before, after) {
			t.Fatal("writeescapedrollback")
		}
		r, e := conquerFixtureWrite(p, &faultDB{Beginner: p, n: 2, commit: commit}, a, rev, o, 20, 1, false, nil)
		if commit {
			if e != nil || r.Outcome != tx.DefiniteCommit || !r.Reconciled {
				t.Fatal("commit proof", r, e)
			}
		} else if r.Outcome != tx.UnknownCommitOutcome || e == nil {
			t.Fatal("missingreceipt provedabort", r, e)
		}
		svc := s
		if commit {
			svc.Content = nil
			svc.Owner = nil
		}
		if _, e = conquerFixtureWrite(p, p, a, rev, o, 20, 1, false, &svc); e != nil {
			t.Fatal("retained receipt/currentprovider", e)
		}
		v, e := conquerRead(t, p, s, a, rev, 1)
		if e != nil || v.Observation.Facts.Version != 2 {
			t.Fatal(v, e)
		}
		if _, e = conquerFixtureWrite(p, p, a, rev, o, 40, 1, false, nil); e == nil {
			t.Fatal("UUIDreuseddifferentrequest")
		}
	}
	a, rev, s := conquerFixture(t, p)
	o := opPinned(rev)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := conquerFixtureWrite(p, p, a, rev, o, 20, 1, false, nil); errs <- e }()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	v, e := conquerRead(t, p, s, a, rev, 1)
	if e != nil || v.Observation.Facts.Version != 2 {
		t.Fatal("doublewrite", v, e)
	}
}
func TestI7C2JNativeWitnessStaleMissingAndCAS(t *testing.T) {
	p := pool(t)
	a, rev, s := conquerFixture(t, p)
	if _, e := s.HeroInputsTx(ctx, characterasset.CoherentReadScope{}, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}); e == nil {
		t.Fatal("forged witness")
	}
	o := opPinned(rev)
	_, e := (tx.Runner{DB: p}).Run(ctx, o, app.Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := characterasset.NewCoherentReadScope(sc, rev, time.Unix(1, 0))
		if e != nil {
			return e
		}
		_, e = s.FactsTx(c, scope, a.PlayerID)
		return e
	})
	if !errors.Is(e, d.ErrStale) {
		t.Fatal("futurestate", e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	pr, e := s.PrepareWriteTx(ctx, tr, a.LogicalServerID, a.PlayerID, rev, opPinned(rev))
	if e != nil {
		t.Fatal(e)
	}
	if _, e = s.ApplyWriteTx(ctx, tr, pr, d.Progress{Level: 20, Loop: 1}, nil, "QUALIFICATION_FIXTURE_ONLY/CAS"); e != nil {
		t.Fatal(e)
	}
	if _, e = s.ApplyWriteTx(ctx, tr, pr, d.Progress{Level: 20, Loop: 1}, nil, "QUALIFICATION_FIXTURE_ONLY/CAS"); !errors.Is(e, d.ErrConflict) {
		t.Fatal("CASdoubleuse", e)
	}
	tr.Rollback(ctx)
	exec(t, p, `DELETE FROM player_conquer_facts WHERE player_id=$1`, int64(a.PlayerID))
	if _, e = conquerRead(t, p, s, a, rev, 1); !errors.Is(e, d.ErrUnavailable) {
		t.Fatal("missing default", e)
	}
}

func TestI7C2JNativeCoherentSnapshotConcurrentWriterAndTargetPlayer(t *testing.T) {
	p := pool(t)
	a, rev, s := conquerFixture(t, p)
	o := opPinned(rev)
	_, e := (tx.Runner{DB: p}).Run(ctx, o, app.Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := characterasset.NewCoherentReadScope(sc, rev, time.Now().UTC())
		if e != nil {
			return e
		}
		before, e := s.HeroInputsTx(c, scope, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
		if e != nil {
			return e
		}
		if _, e = conquerFixtureWrite(p, p, a, rev, opPinned(rev), 40, 1, false, nil); e != nil {
			return e
		}
		after, e := s.HeroInputsTx(c, scope, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
		if e != nil {
			return e
		}
		if !reflect.DeepEqual(before, after) || after.Observation.Facts.Version != 1 {
			t.Fatal("mixed owner snapshot", before, after)
		}
		scope.ContentRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
		if _, e = s.FactsTx(c, scope, a.PlayerID); e == nil {
			t.Fatal("mixed content witness")
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	v, e := conquerRead(t, p, s, a, rev, 1)
	if e != nil || v.Observation.Facts.Version != 2 || v.Observation.Contributions[9] != 48 {
		t.Fatal(v, e)
	}
	b, _, _ := conquerFixture(t, p)
	v, e = conquerRead(t, p, s, b, rev, 1)
	if e != nil || v.Observation.Facts.Player != b.PlayerID || len(v.Observation.Contributions) != 0 {
		t.Fatal("viewer fallback", v, e)
	}
}

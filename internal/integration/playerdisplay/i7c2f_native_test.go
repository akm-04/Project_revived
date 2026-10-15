//go:build postgres

package playerdisplay_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	asset "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/inscription"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	ins "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

// This owner-state fixture tests the conditional Inscription contract. It is
// explicitly NOT the missing genuine blood-stage lifecycle producer.
type inscriptionEligibilityFixture struct {
	characterstore.Store
	stage int64
}

func (f inscriptionEligibilityFixture) InscriptionEligibilityTx(c context.Context, q tx.Queryer, p identity.PlayerID, id int64, rev string, at time.Time) (app.Eligibility, error) {
	h, e := f.ReadHeroByPartnerIDTx(c, q, p, id)
	if e != nil {
		return app.Eligibility{}, e
	}
	pop, e := f.ReadRootTx(c, q, p)
	if e != nil {
		return app.Eligibility{}, e
	}
	k, e := (contentstore.Store{}).HeroKindTx(c, q, rev, h.TableID)
	return app.Eligibility{Player: p, PartnerID: id, PopulationVersion: pop.StateVersion, HeroVersion: h.StateVersion, Level: h.Level, RawStage: f.stage, Kind: k, ContentRevision: rev, ProviderRevision: "CONDITIONAL_TEST_ONLY_NOT_LIVE_PRODUCER", ObservedAt: at, Qualified: true}, e
}
func inscriptionService(p *pg.Pool, db tx.Beginner) app.Service {
	cs := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: db}
	iv := i5.Service{Runner: runner, Store: values, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("inscription-native-fixture-secret-000")}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Reads: tx.Runner{DB: p}, Heroes: characterstore.InscriptionHeroPort{Store: characterstore.Store{Queryer: p}}, Owner: inscriptionstore.Store{}, Content: cs, Players: i4store.PlayerRootLocker{}, Fence: values, Values: values, ValuePlans: iv, Eligibility: inscriptionEligibilityFixture{characterstore.Store{Queryer: p}, 3}, Receipts: kernelstore.Store{}}
}
func inscriptionFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, app.Service) {
	t.Helper()
	a, rev, course := courseFixture(t, p)
	exec(t, p, `UPDATE player_heroes SET level=100 WHERE player_id=$1`, int64(a.PlayerID))
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	at := time.Now().Add(-time.Hour)
	owner := inscriptionstore.Store{}
	if e = owner.EnsureRootTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	for id := int64(1); id <= 3; id++ {
		if e = owner.EnsureHeroTx(ctx, tr, a.PlayerID, id, at); e != nil {
			t.Fatal(e)
		}
	}
	if e = (i5store.Store{}).EnsureInscriptionCertificatesTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	lines := []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 100000000}, {Kind: grant.ScalarCurrency, ResourceKey: "degree_cer", Amount: 100000}, {Kind: grant.ScalarCurrency, ResourceKey: "graduate_cer", Amount: 100000}, {Kind: grant.ScalarCurrency, ResourceKey: "patent_cer", Amount: 100000}}
	for _, id := range []int64{160100101, 160100102, 160100701, 160400101, 160500101, 160500102, 160500103, 50001343, 50001344, 50001345, 50001346} {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: 20})
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2f-fixture", Operation: "conditional-owner-inputs", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: "fixture-only"}, Lines: lines}
	if _, e = course.Grants.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return a, rev, inscriptionService(p, p)
}
func insCmd(t *testing.T, s app.Service, a identity.ActorContext, c app.Command) app.Result {
	t.Helper()
	r, e := s.Command(ctx, a, c, op())
	if e != nil {
		t.Fatal(c, e)
	}
	return r
}
func insRoot(t *testing.T, p *pg.Pool, a identity.ActorContext) ins.Root {
	t.Helper()
	r, e := (inscriptionstore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func insFacet(t *testing.T, p *pg.Pool, a identity.ActorContext, id int64) ins.HeroRoot {
	t.Helper()
	r, e := (inscriptionstore.Store{}).ReadHeroTx(ctx, p, a.PlayerID, id)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func insIDs(t *testing.T, r app.Result) []int64 {
	t.Helper()
	b, _ := json.Marshal(r.Body["inscript_items"])
	var ids []int64
	if e := json.Unmarshal(b, &ids); e != nil {
		t.Fatal(e)
	}
	return ids
}
func TestI7C2FAllEightOperationsPendingIsolationAndRecovery(t *testing.T) {
	p := pool(t)
	a, rev, s := inscriptionFixture(t, p)
	before := libraryAmount(t, p, a, "degree_cer")
	r := insCmd(t, s, a, app.Command{Family: app.Make, FamilyID: 10001, Amount: 1})
	ids := insIDs(t, r)
	if len(ids) != 1 || libraryAmount(t, p, a, "degree_cer") != before-90 {
		t.Fatal(r)
	}
	o := op()
	cmd := app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 10, CostType: 1}
	r, e := s.Command(ctx, a, cmd, o)
	if e != nil {
		t.Fatal(e)
	}
	pending := insRoot(t, p, a).Facts.Pending
	if pending == nil || len(pending.Candidates) != 10 || dormStack(t, p, a, 160100101) != 20 || len(insFacet(t, p, a, 1).Facts.Wire()) != 0 {
		t.Fatal(pending)
	}
	r2, e := s.Command(ctx, a, cmd, o)
	if e != nil || r2.OperationID != r.OperationID || libraryAmount(t, p, a, "crystal") != 10000800 {
		t.Fatal("replay", r2, e)
	}
	chosen := pending.Candidates[0]
	n := dormStack(t, p, a, chosen)
	saved := insCmd(t, s, a, app.Command{Family: app.Save, ItemID: chosen})
	if insRoot(t, p, a).Facts.Pending != nil || dormStack(t, p, a, 160100101) != 19 || dormStack(t, p, a, chosen) != n+1 || saved.Body["rebuild_items"] == nil {
		t.Fatal("save", saved)
	}
	insCmd(t, s, a, app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 1, CostType: 2})
	insCmd(t, s, a, app.Command{Family: app.Abandon})
	insCmd(t, s, a, app.Command{Family: app.Abandon})
	if insRoot(t, p, a).Facts.Pending != nil {
		t.Fatal("abandon")
	}
	insCmd(t, s, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160100101})
	insCmd(t, s, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160100102, ReplaceID: 160100101})
	if dormStack(t, p, a, 160100101) != 19 || insFacet(t, p, a, 1).Facts.Slots[0] != 160100102 {
		t.Fatal("replace")
	}
	v, e := s.HeroInscriptionInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 1)
	if e != nil || len(v.Items) != 1 || v.Items[0].ID != 160100102 {
		t.Fatal("projection", v, e)
	}
	s.Eligibility = inscriptionEligibilityFixture{characterstore.Store{Queryer: p}, 0}
	insCmd(t, s, a, app.Command{Family: app.Remove, PartnerID: 1, ItemID: 160100102})
	if len(insFacet(t, p, a, 1).Facts.Wire()) != 0 {
		t.Fatal("recovery remove")
	}
	before = libraryAmount(t, p, a, "degree_cer")
	insCmd(t, s, a, app.Command{Family: app.Resolve, ItemID: 160100101, Amount: 2})
	if libraryAmount(t, p, a, "degree_cer") != before+180 {
		t.Fatal("resolve")
	}
	ex := insCmd(t, s, a, app.Command{Family: app.Exchange})
	if ex.Body["currency_change"] == nil || dormStack(t, p, a, 50001343) != 0 {
		t.Fatal("exchange", ex)
	}
	if insCmd(t, s, a, app.Command{Family: app.Exchange}).Body["currency_change"] != nil {
		t.Fatal("empty exchange")
	}
}
func TestI7C2FStaleSaveClearAndNoInventedEligibility(t *testing.T) {
	p := pool(t)
	a, _, s := inscriptionFixture(t, p)
	r := insCmd(t, s, a, app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 1, CostType: 1})
	id := insIDs(t, r)[0]
	exec(t, p, `DELETE FROM player_item_stacks WHERE player_id=$1 AND item_id=160100101`, int64(a.PlayerID))
	o := op()
	_, e := s.Command(ctx, a, app.Command{Family: app.Save, ItemID: id}, o)
	if !errors.Is(e, app.ErrRejected) || insRoot(t, p, a).Facts.Pending != nil {
		t.Fatal("stale clear", e)
	}
	_, e = s.Command(ctx, a, app.Command{Family: app.Save, ItemID: id}, o)
	if !errors.Is(e, app.ErrRejected) {
		t.Fatal("stale replay", e)
	}
	before := libraryAmount(t, p, a, "degree_cer")
	s.Eligibility = characterstore.InscriptionHeroPort{Store: characterstore.Store{Queryer: p}}
	_, e = s.Command(ctx, a, app.Command{Family: app.Make, FamilyID: 10001, Amount: 1}, op())
	if !errors.Is(e, app.ErrUnavailable) || libraryAmount(t, p, a, "degree_cer") != before {
		t.Fatal("invented live blood eligibility", e)
	}
}
func TestI7C2FUnknownOutcomeRetainedEntropyAndOneLane(t *testing.T) {
	p := pool(t)
	for _, commit := range []bool{true, false} {
		a, _, _ := inscriptionFixture(t, p)
		s := inscriptionService(p, &libraryFaultDB{Beginner: p, commit: commit})
		o := op()
		c := app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 10, CostType: 1}
		_, e := s.Command(ctx, a, c, o)
		if commit && e != nil {
			t.Fatal(e)
		}
		if !commit && e == nil {
			t.Fatal("unknown reported success")
		}
		reopened := pool(t)
		r, e := inscriptionService(reopened, reopened).Command(ctx, a, c, op())
		if e != nil {
			t.Fatal(e)
		}
		if !commit && r.OperationID != o.ID {
			t.Fatal("lost retained identity")
		}
		n := libraryAmount(t, p, a, "crystal")
		if !commit && n != 10000800 {
			t.Fatal("replayed debit", n)
		}
	}
}
func TestI7C2FConcurrencyReferenceGuardAndNoPartialSpend(t *testing.T) {
	p := pool(t)
	a, _, s := inscriptionFixture(t, p)
	o := op()
	var wg sync.WaitGroup
	errs := make(chan error, 6)
	for i := 0; i < 6; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.Command(ctx, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160100101}, o)
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
	if dormStack(t, p, a, 160100101) != 19 {
		t.Fatal("duplicate spend")
	}
	guard := inscriptionstore.Store{}
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	plan, e := guard.PreflightHeroRemovalTx(ctx, p, ref)
	if e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = guard.LockReferenceGuardKeyTx(ctx, tr, plan.Locks[0]); e != nil {
		t.Fatal(e)
	}
	if e = guard.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); !errors.Is(e, asset.ErrReferenceInUse) {
		t.Fatal("retired applied Hero", e)
	}
	tr.Rollback(ctx)
	before := insRoot(t, p, a)
	exec(t, p, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='degree_cer'`, int64(a.PlayerID))
	_, e = s.Command(ctx, a, app.Command{Family: app.Make, FamilyID: 10001, Amount: 1}, op())
	after := insRoot(t, p, a)
	if !errors.Is(e, app.ErrRejected) || after.Version != before.Version {
		t.Fatal("partial counter/pending", e)
	}
}

func TestI7C2FClosureSeamsBackfillFreshFacetsOverflowAndCurrentResponse(t *testing.T) {
	p := pool(t)
	a, rev, s := inscriptionFixture(t, p)
	owner := inscriptionstore.Store{}
	insCmd(t, s, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160500101})
	insCmd(t, s, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160500102})
	old := insFacet(t, p, a, 1)
	if e := app.RunBackfill(ctx, s.Timed, characterstore.Store{}, owner, i5store.Store{}, rev, op()); e != nil {
		t.Fatal(e)
	}
	if insFacet(t, p, a, 1).Version != old.Version || insFacet(t, p, a, 1).Facts != old.Facts {
		t.Fatal("backfill overwrote applied")
	}
	o := op()
	r, e := s.Command(ctx, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160500103}, o)
	if e != nil {
		t.Fatal(e)
	}
	v, e := s.HeroInscriptionInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 1)
	if e != nil || len(v.CompleteSuits) != 1 || v.CompleteSuits[0] != 2001 {
		t.Fatal("suit", v, e)
	}
	// Copy isolation: a caller changing its observation cannot mutate canonical truth.
	v.Items[0].Display[15] = "99999"
	again, e := s.HeroInscriptionInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 1)
	if e != nil || again.Items[0].Display[15] == "99999" {
		t.Fatal("mutable observation")
	}
	exec(t, p, `UPDATE player_currency_balances SET amount=amount+7 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	body, e := s.Response(ctx, a, r, op())
	if e != nil {
		t.Fatal(e)
	}
	bal := body["economy_"].(map[string]any)["crystal"].(int64)
	if bal != libraryAmount(t, p, a, "crystal") {
		t.Fatal("stale absolute receipt")
	}
	// Fill the return destination, then remove into canonical overflow Mail.
	exec(t, p, `UPDATE player_item_stacks SET quantity=999 WHERE player_id=$1 AND item_id=160500101`, int64(a.PlayerID))
	insCmd(t, s, a, app.Command{Family: app.Remove, PartnerID: 1, ItemID: 160500101})
	if dormStack(t, p, a, 160500101) != 999 || insFacet(t, p, a, 1).Facts.Slots[0] != 0 {
		t.Fatal("overflow return")
	}
	var mails int64
	if e = p.QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID)).Scan(&mails); e != nil {
		t.Fatal(e)
	}
	if mails < 1 {
		t.Fatal("lost overflow")
	}
	// Real fresh Hero acquisition uses the same insert-only chain; direct facet call
	// verifies its independent rollback semantics here, acquisition tested separately.
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = owner.InitFreshHeroTx(ctx, tr, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 777}, time.Now().UTC()); e != nil {
		t.Fatal(e)
	}
	tr.Rollback(ctx)
	if _, e = owner.ReadHeroTx(ctx, p, a.PlayerID, 777); e == nil {
		t.Fatal("facet escaped rollback")
	}
}

func TestI7C2FControlledImportRequiresProvenanceAndPreservesOnce(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	skillHero(t, p, a, rev, 10001001, 1)
	s := inscriptionService(p, p)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	at := time.Now().Add(-time.Hour)
	owner := inscriptionstore.Store{}
	if e = owner.EnsureRootTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	if e = owner.EnsureHeroTx(ctx, tr, a.PlayerID, 1, at); e != nil {
		t.Fatal(e)
	}
	if e = (i5store.Store{}).EnsureInscriptionCertificatesTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	source := []byte("qualified-preservation-fixture-not-official-server")
	hash := sha256.Sum256(source)
	state := ins.Seed()
	state.ForgeMisses = 7
	v := app.ImportPackage{SchemaVersion: 1, Player: a.PlayerID, ContentRevision: rev, Policy: ins.Policy, SourceArtifactSHA256: hex.EncodeToString(hash[:]), Facts: state, Heroes: []app.ImportedHero{{PartnerID: 1, Facts: ins.HeroFacts{Slots: [3]int64{160100101}}}}, Certificates: [3]int64{123, 456, 789}}
	raw, _ := json.Marshal(v)
	if _, e = app.VerifyImport(raw, []byte("wrong")); e == nil {
		t.Fatal("unbound provenance")
	}
	verified, e := app.VerifyImport(raw, source)
	if e != nil {
		t.Fatal(e)
	}
	if e = s.RunImport(ctx, verified, i5store.Store{}, op()); e != nil {
		t.Fatal(e)
	}
	before := insRoot(t, p, a)
	if before.Facts.ForgeMisses != 7 || insFacet(t, p, a, 1).Facts.Slots[0] != 160100101 || libraryAmount(t, p, a, "degree_cer") != 123 {
		t.Fatal("import effects")
	}
	if e = s.RunImport(ctx, verified, i5store.Store{}, op()); e != nil || insRoot(t, p, a).Version != before.Version {
		t.Fatal("import replay", e)
	}
	v.Certificates[0]++
	raw, _ = json.Marshal(v)
	conflict, e := app.VerifyImport(raw, source)
	if e != nil {
		t.Fatal(e)
	}
	if e = s.RunImport(ctx, conflict, i5store.Store{}, op()); e == nil || libraryAmount(t, p, a, "degree_cer") != 123 {
		t.Fatal("conflicting import overwrite", e)
	}
}

func TestI7C2FCoherentCallerSnapshotAndPinnedTime(t *testing.T) {
	p := pool(t)
	a, rev, s := inscriptionFixture(t, p)
	insCmd(t, s, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160100101})
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	runner := tx.Runner{DB: p}
	res, e := runner.Run(ctx, o, app.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := asset.NewCoherentReadScope(sc, rev, time.Now().UTC())
		if e != nil {
			return e
		}
		ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
		before, e := s.CoherentHeroInputsTx(c, scope, ref)
		if e != nil {
			return e
		}
		insCmd(t, s, a, app.Command{Family: app.Remove, PartnerID: 1, ItemID: 160100101})
		after, e := s.CoherentHeroInputsTx(c, scope, ref)
		if e != nil {
			return e
		}
		if before.FacetVersion != after.FacetVersion || before.Applied != after.Applied || after.Applied.Slots[0] != 160100101 {
			t.Fatal("mixed snapshots")
		}
		return nil
	})
	if e != nil || res.Outcome != tx.DefiniteCommit {
		t.Fatal(e)
	}
	if insFacet(t, p, a, 1).Facts.Slots[0] != 0 {
		t.Fatal("outside snapshot")
	}
	_, e = runner.Run(ctx, op(), app.Profile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		_, e := asset.NewCoherentReadScope(sc, rev, time.Now().UTC())
		return e
	})
	if !errors.Is(e, asset.ErrInsufficientReadIsolation) {
		t.Fatal("read committed accepted", e)
	}
}

func TestI7C2FLatestPendingSupersedesAndStaleClockRejects(t *testing.T) {
	p := pool(t)
	a, _, s := inscriptionFixture(t, p)
	insCmd(t, s, a, app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 10, CostType: 1})
	old := insRoot(t, p, a).Facts.Pending
	insCmd(t, s, a, app.Command{Family: app.Rebuild, ItemID: 160100701, Amount: 1, CostType: 2})
	next := insRoot(t, p, a).Facts.Pending
	if next.Generation != old.Generation+1 || next.Source != 160100701 {
		t.Fatal("latest pending", next)
	}
	o := op()
	s.Timed.Binder.Time = courseInstant{at: old.CreatedAt.Add(-time.Hour)}
	before := libraryAmount(t, p, a, "crystal")
	_, e := s.Command(ctx, a, app.Command{Family: app.Remove, PartnerID: 1, ItemID: 160100101}, o)
	if !errors.Is(e, app.ErrRejected) || libraryAmount(t, p, a, "crystal") != before {
		t.Fatal("backward clock", e)
	}
	if insRoot(t, p, a).Facts.Pending.Generation != next.Generation {
		t.Fatal("stale changed pending")
	}
}

func TestI7C2FPreparedValueRejectsLateDestinationWithoutSpend(t *testing.T) {
	p := pool(t)
	a, rev, s := inscriptionFixture(t, p)
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	before := libraryAmount(t, p, a, "crystal")
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	support := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "inscription", Operation: app.Insert, BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: app.LifecyclePolicy}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 160100101, Amount: 1}}}
	prepared, e := s.ValuePlans.PrepareInscriptionValueTx(ctx, tr, a, i5.InscriptionValueRequest{Cost: i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: 20}}}, Support: support}, o)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = s.ValuePlans.ApplyInscriptionValueTx(ctx, tr, prepared, []grant.Line{{Kind: grant.StackItem, ItemID: 160100102, Amount: 1}}); e == nil {
		t.Fatal("late identity accepted")
	}
	b, ok, e := (i5store.Store{}).ReadScalarTx(ctx, tr, a.PlayerID, "crystal")
	if e != nil || !ok || b.Amount != before {
		t.Fatal("unplanned credit debited", b, e)
	}
	tr.Rollback(ctx)
}

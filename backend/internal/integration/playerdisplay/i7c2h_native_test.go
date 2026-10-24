//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	asset "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sync"
	"testing"
	"time"
)

func spiritService(p *pg.Pool, db tx.Beginner) app.Service {
	cs := contentstore.Store{Queryer: p}
	v := i5store.Store{Queryer: p}
	run := tx.Runner{DB: db}
	return app.Service{Mint: d.V1PreservationPolicy{}, Milestones: d.V1PreservationPolicy{}, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: run}, Reads: tx.Runner{DB: p}, Heroes: characterstore.SpiritHeroPort{Store: characterstore.Store{Queryer: p}}, Owner: spiritstore.Store{}, Content: cs, Players: i4store.PlayerRootLocker{}, Fence: v, Values: v, Costs: i5.MaterialCostDebiter{Store: v, Content: cs}, Receipts: kernelstore.Store{}}
}
func spiritI5(p *pg.Pool, s app.Service) i5.Service {
	cs := contentstore.Store{Queryer: p}
	v := i5store.Store{Queryer: p}
	return i5.Service{Runner: tx.Runner{DB: p}, Store: v, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: v, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Spirits: s}
}
func spiritGrant(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, s app.Service, lines []grant.Line) (i5.GrantResult, grant.Plan, operation.Context) {
	t.Helper()
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2h-native", Operation: "typed-source-intent", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: d.ReconstructionPolicy}, Lines: lines}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	r, e := spiritI5(p, s).SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{})
	if e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return r, plan, o
}
func spiritFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, app.Service) {
	t.Helper()
	rev := installed(t, p)
	a := bornActor(t, p)
	s := spiritService(p, p)
	for id := int64(1); id <= 3; id++ {
		bornHero(t, p, a, rev, 10001000+id, id)
	}
	// Level 1 with no EXP and no energy: eligibility is then produced by actual I5 EXP Grant.
	exec(t, p, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_temporal_resources SET stored_amount=0 WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID))
	rule, e := (contentstore.Store{}).ResolveProgressionPolicyTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	target := rule.Rows[58].TotalExp
	spiritGrant(t, p, a, rev, s, []grant.Line{{Kind: grant.PlayerExp, Amount: target}, {Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 100000000}, {Kind: grant.SpecializedDomain, Domain: "spirit", ItemID: 250000111, Amount: 3}, {Kind: grant.SpecializedDomain, Domain: "spirit", ItemID: 250000112, Amount: 2}, {Kind: grant.SpecializedDomain, Domain: "spirit", ItemID: 250001151, Amount: 10}})
	level, e := (i5store.Store{}).ReadProgressionTx(ctx, p, a.PlayerID)
	if e != nil || level.Level != 60 {
		t.Fatal("actual level60 EXP", level, e)
	}
	return a, rev, s
}
func spiritRoot(t *testing.T, p *pg.Pool, a identity.ActorContext) d.Root {
	t.Helper()
	r, e := (spiritstore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func spiritCmd(t *testing.T, s app.Service, a identity.ActorContext, c app.Command) app.Result {
	t.Helper()
	r, e := s.Command(ctx, a, c, op())
	if e != nil {
		t.Fatal(c, e)
	}
	return r
}
func TestI7C2HMaterializedMintReplayAndOwnerBoundaries(t *testing.T) {
	p := pool(t)
	a, rev, s := spiritFixture(t, p)
	before := spiritRoot(t, p, a)
	r, plan, o := spiritGrant(t, p, a, rev, s, []grant.Line{{Kind: grant.SpecializedDomain, Domain: "spirit", ItemID: 250000161, Amount: 2}})
	if len(r.Materializations) != 1 || r.Materializations[0].ProviderRevision != d.ReconstructionPolicy {
		t.Fatal(r)
	}
	after := spiritRoot(t, p, a)
	if after.Facts.NextID != before.Facts.NextID+2 {
		t.Fatal("mint count")
	}
	iv := spiritI5(p, s)
	iv.Spirits = nil
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	again, e := iv.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{})
	if e != nil {
		t.Fatal("replay provider nil", e)
	}
	tr.Commit(ctx)
	x, _ := json.Marshal(r)
	y, _ := json.Marshal(again)
	var xv, yv any
	json.Unmarshal(x, &xv)
	json.Unmarshal(y, &yv)
	if !reflect.DeepEqual(xv, yv) || spiritRoot(t, p, a).Version != after.Version {
		t.Fatal("replay allocated")
	}
	for _, line := range []grant.Line{{Kind: grant.StackItem, ItemID: 250000111, Amount: 1}, {Kind: grant.SpecializedDomain, Domain: "other", ItemID: 250000111, Amount: 1}, {Kind: grant.SpecializedDomain, Domain: "spirit", ItemID: 50001112, Amount: 1}} {
		tr, _ := p.Begin(ctx, tx.Options{})
		plan.Source.Occurrence = op().ID.String()
		plan.Lines = []grant.Line{line}
		_, e := spiritI5(p, s).SettleGrantTx(ctx, tr, a, plan, opPinned(rev), i5.GrantTxOptions{})
		tr.Rollback(ctx)
		if e == nil {
			t.Fatal("foreign destination admitted", line)
		}
	}
	if _, e = s.HeroSpiritInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 1); e != nil {
		t.Fatal(e)
	}
}
func opPinned(rev string) operation.Context {
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	return o
}
func TestI7C2HAllCommandsTransferReferencesAndFullStrengthening(t *testing.T) {
	p := pool(t)
	a, rev, s := spiritFixture(t, p)
	spiritCmd(t, s, a, app.Command{Family: app.Lock, SpiritID: 1})
	if !spiritRoot(t, p, a).Facts.Instances[1].Locked {
		t.Fatal("lock")
	}
	spiritCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 1, SpiritID: 1, Position: 1})
	if _, e := s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 2, SpiritID: 1, Position: 1}, op()); e == nil {
		t.Fatal("direct crossHero")
	}
	slots := [6]int64{1, 4}
	saved := spiritCmd(t, s, a, app.Command{Family: app.Save, Name: "一二三四五六七八九十", Slots: slots})
	id := saved.Body["id"].(int64)
	spiritCmd(t, s, a, app.Command{Family: app.Apply, ProgramID: id, PartnerID: 2})
	one, e := s.HeroSpiritInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 1)
	if e != nil || one.Facet.Facts.Slots != ([6]int64{}) {
		t.Fatal("source detach", one, e)
	}
	two, e := s.HeroSpiritInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 2)
	if e != nil || two.Items[0]["spirit_id"] != int64(1) || two.Facet.Facts.Slots != slots {
		t.Fatal("target payload", two, e)
	}
	before := spiritRoot(t, p, a)
	mana := libraryAmount(t, p, a, "mana")
	for _, fodder := range []int64{1, 4} {
		if _, e = s.Command(ctx, a, app.Command{Family: app.Enhance, SpiritID: 2, SpiritIDs: []int64{fodder}}, op()); e == nil {
			t.Fatal("referenced consumed")
		}
	}
	if spiritRoot(t, p, a).Version != before.Version || libraryAmount(t, p, a, "mana") != mana {
		t.Fatal("failed consume wrote")
	}
	spiritCmd(t, s, a, app.Command{Family: app.AllOff, PartnerID: 2})
	spiritCmd(t, s, a, app.Command{Family: app.Delete, ProgramID: id})
	spiritCmd(t, s, a, app.Command{Family: app.Unlock, SpiritID: 1})
	o := op()
	c := app.Command{Family: app.Enhance, SpiritID: 1, SpiritIDs: []int64{6, 7, 8, 9}}
	r, e := s.Command(ctx, a, c, o)
	if e != nil {
		t.Fatal(e)
	}
	x := spiritRoot(t, p, a).Facts.Instances[1]
	if x.Level != 15 || x.EXP != 67500 || libraryAmount(t, p, a, "mana") != mana-80000*25 {
		t.Fatal("full gain/cap", x)
	}
	if x.Validate(two.Catalog) != nil || len(x.Sub) < 1 {
		t.Fatal("milestone materialization", x)
	}
	v := spiritRoot(t, p, a).Version
	r2, e := s.Command(ctx, a, c, o)
	if e != nil || r.OperationID != r2.OperationID || spiritRoot(t, p, a).Version != v {
		t.Fatal("enhance replay", e)
	}
	if _, e = s.Command(ctx, a, app.Command{Family: app.Enhance, SpiritID: 1, SpiritIDs: []int64{10}}, op()); e == nil {
		t.Fatal("cap consume")
	}
	programs, e := s.Programs(ctx, a, op())
	if e != nil || len(programs) != 0 {
		t.Fatal(programs, e)
	}
	items, e := s.InventoryTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()})
	if e != nil || len(items) != 11 {
		t.Fatal("inventory", len(items), e)
	}
}
func TestI7C2HUnknownRaceRollbackAndCoherentForeignRead(t *testing.T) {
	p := pool(t)
	for _, committed := range []bool{true, false} {
		a, _, _ := spiritFixture(t, p)
		s := spiritService(p, &libraryFaultDB{Beginner: p, commit: committed})
		o := op()
		c := app.Command{Family: app.Enhance, SpiritID: 1, SpiritIDs: []int64{6}}
		_, e := s.Command(ctx, a, c, o)
		if !committed && e == nil {
			t.Fatal("unknown false success")
		}
		normal := spiritService(p, p)
		r, e := normal.Command(ctx, a, c, o)
		if e != nil || r.OperationID != o.ID || libraryAmount(t, p, a, "mana") != 100000000-500000 {
			t.Fatal("unknown recovery", r, e)
		}
	}
	a, rev, s := spiritFixture(t, p)
	o := op()
	c := app.Command{Family: app.Enhance, SpiritID: 1, SpiritIDs: []int64{6}}
	var wg sync.WaitGroup
	errs := make(chan error, 6)
	for i := 0; i < 6; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.Command(ctx, a, c, o); errs <- e }()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	if libraryAmount(t, p, a, "mana") != 99500000 {
		t.Fatal("race cost")
	}
	spiritCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 1, SpiritID: 1, Position: 1})
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), app.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		scope, e := asset.NewCoherentReadScope(sc, rev, time.Now())
		if e != nil {
			return e
		}
		v, e := s.CoherentHeroInputsTx(ctx, scope, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
		if e != nil {
			return e
		}
		if v.Root.Version < 2 || v.PopulationVersion < 1 || v.Items[0]["spirit_id"] != int64(1) {
			return errors.New("foreign materialization")
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	guard := spiritstore.Store{}
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	plan, e := guard.PreflightHeroRemovalTx(ctx, p, ref)
	if e != nil {
		t.Fatal(e)
	}
	tr, _ := p.Begin(ctx, tx.Options{})
	defer tr.Rollback(ctx)
	if e = guard.LockReferenceGuardKeyTx(ctx, tr, plan.Locks[0]); e != nil {
		t.Fatal(e)
	}
	if e = guard.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); !errors.Is(e, asset.ErrReferenceInUse) {
		t.Fatal("retirement", e)
	}
}

func TestI7C2HMixedGrantRollbackAndReferenceRace(t *testing.T) {
	p := pool(t)
	a, rev, s := spiritFixture(t, p)
	before := spiritRoot(t, p, a)
	money := libraryAmount(t, p, a, "mana")
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2h-rollback", Operation: "overflow-after-mint", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: op().ID.String(), PolicyVersion: d.ReconstructionPolicy}, Lines: []grant.Line{{Kind: grant.SpecializedDomain, Domain: "spirit", ItemID: 250000161, Amount: 2}, {Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 9223372036854775807}}}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	_, e = spiritI5(p, s).SettleGrantTx(ctx, tr, a, plan, opPinned(rev), i5.GrantTxOptions{})
	tr.Rollback(ctx)
	if e == nil {
		t.Fatal("overflow did not rollback")
	}
	after := spiritRoot(t, p, a)
	x, _ := json.Marshal(before)
	y, _ := json.Marshal(after)
	if string(x) != string(y) || money != libraryAmount(t, p, a, "mana") {
		t.Fatal("partial minted IDs/cursor survived rollback")
	}
	errs := make(chan error, 2)
	var wg sync.WaitGroup
	for _, c := range []app.Command{{Family: app.Save, Name: "Guard", Slots: [6]int64{3}}, {Family: app.Enhance, SpiritID: 1, SpiritIDs: []int64{3}}} {
		wg.Add(1)
		go func(c app.Command) { defer wg.Done(); _, e := s.Command(ctx, a, c, op()); errs <- e }(c)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil && !errors.Is(e, app.ErrRejected) {
			t.Fatal(e)
		}
	}
	state := spiritRoot(t, p, a).Facts
	_, exists := state.Instances[3]
	if !exists && len(state.Programs) > 0 {
		t.Fatal("consumed reference survived race")
	}
	if exists && len(state.Programs) != 1 {
		t.Fatal("neither branch settled")
	}
}
func TestI7C2HProgramLimitIDsAndFunctionEligibilityFacts(t *testing.T) {
	p := pool(t)
	a, rev, s := spiritFixture(t, p)
	for i := 0; i < 20; i++ {
		spiritCmd(t, s, a, app.Command{Family: app.Save, Name: fmt.Sprint("P", i), Slots: [6]int64{1}})
	}
	before := spiritRoot(t, p, a)
	if before.Facts.NextProgramID != 21 || before.Facts.ReferenceCount(1) != 20 {
		t.Fatal("count/cursor")
	}
	if _, e := s.Command(ctx, a, app.Command{Family: app.Save, Name: "Overflow", Slots: [6]int64{1}}, op()); e == nil {
		t.Fatal("21st program")
	}
	spiritCmd(t, s, a, app.Command{Family: app.Delete, ProgramID: 1})
	r := spiritCmd(t, s, a, app.Command{Family: app.Save, Name: "New", Slots: [6]int64{1}})
	if r.Body["id"] != int64(21) {
		t.Fatal("program ID reused")
	}
	var unlocks int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM player_function_unlocks WHERE player_id=$1 AND function_id=99`, int64(a.PlayerID)).Scan(&unlocks); e != nil || unlocks != 0 {
		t.Fatal("invented function99 announcement", unlocks, e)
	}
	exec(t, p, `DELETE FROM player_function_eligibility WHERE player_id=$1 AND function_id=99`, int64(a.PlayerID))
	before = spiritRoot(t, p, a)
	if _, e := s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 1, SpiritID: 1, Position: 1}, op()); e == nil {
		t.Fatal("missing eligibility accepted")
	}
	if spiritRoot(t, p, a).Version != before.Version {
		t.Fatal("missing eligibility wrote")
	}
	// Independent owner unavailable is never a zero-valued successful read.
	exec(t, p, `DELETE FROM player_spirit_heroes WHERE player_id=$1 AND partner_id=3`, int64(a.PlayerID))
	if _, e := s.HeroSpiritInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 3); e == nil {
		t.Fatal("missing facet fabricated zero")
	}
}

func TestI7C2HQualifiedHeroKindComesFromPinnedContent(t *testing.T) {
	p := pool(t)
	a, rev, s := spiritFixture(t, p)
	skillHero(t, p, a, rev, 11001, 4)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (spiritstore.Store{}).EnsureHeroTx(ctx, tr, a.PlayerID, 4, time.Now().Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	for _, row := range []struct {
		id   int64
		kind character.HeroKind
	}{{1, character.NormalHero}, {4, character.SuperHero}} {
		spiritCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: row.id, SpiritID: 2, Position: 1})
		v, e := s.HeroSpiritInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, row.id)
		if e != nil {
			t.Fatal(e)
		}
		if e = v.Hero.Validate(); e != nil || v.Hero.Kind != row.kind || v.Items[0]["spirit_id"] != int64(2) {
			t.Fatal("qualified provider omitted pinned HeroKind orbinding", v.Hero.Kind, e)
		}
		spiritCmd(t, s, a, app.Command{Family: app.AllOff, PartnerID: row.id})
	}
}

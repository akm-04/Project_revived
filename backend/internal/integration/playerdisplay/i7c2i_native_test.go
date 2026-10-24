//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	asset "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/heroevolution"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	evo "gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"strconv"
	"sync"
	"testing"
	"time"
)

func evolutionService(p *pg.Pool, db tx.Beginner) app.Service {
	cs := contentstore.Store{Queryer: p}
	v := i5store.Store{Queryer: p}
	return app.Service{Values: v, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Heroes: characterstore.EvolutionHeroPort{Store: characterstore.Store{Queryer: p}}, Owner: characterstore.EvolutionStore{}, Content: cs, Players: i4store.PlayerRootLocker{}, Fence: v, Costs: i5.MaterialCostDebiter{Store: v, Content: cs}, Receipts: kernelstore.Store{}}
}
func evolutionFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, app.Service) {
	t.Helper()
	rev := installed(t, p)
	a := actor(t, p)
	exec(t, p, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_function_state_owners(player_id,state_version,updated_at)VALUES($1,1,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_temporal_resources(player_id,resource_key,stored_amount,regen_anchor_at,state_version,policy_version,content_revision,updated_at)VALUES($1,'energy',0,clock_timestamp()-interval '1 hour',1,$2,$2,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID), rev)
	// Owned base level/star are accepted Character fixture inputs. All stone
	// progress below is created through the actual canonical commands, not SQL.
	for i, table := range []int64{10001001, 11001} {
		h := skillHero(t, p, a, rev, table, int64(i+1))
		exec(t, p, `UPDATE player_heroes SET level=100,star=5 WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), h.PartnerID)
	}
	s := evolutionService(p, p)
	if e := app.RunBackfill(ctx, s.Timed, characterstore.Store{}, characterstore.EvolutionStore{}, op()); e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	rule, e := (contentstore.Store{}).ResolveProgressionPolicyTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	lines := []grant.Line{{Kind: grant.PlayerExp, Amount: rule.Rows[98].TotalExp}}
	for _, id := range []int64{40001001, 41001, 50005148, 50005149} {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: 900})
	}
	original := opPinned(rev)
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2i-native", Operation: "fixture-source-items", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: original.ID.String(), PolicyVersion: evo.LifecyclePolicy}, Lines: lines}
	v := i5store.Store{Queryer: p}
	svc := i5.Service{Runner: tx.Runner{DB: p}, Store: v, Content: contentstore.Store{Queryer: p}, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
	if _, e = svc.SettleGrantTx(ctx, tr, a, plan, original, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	level, e := v.ReadProgressionTx(ctx, p, a.PlayerID)
	if e != nil || level.Level != 100 {
		t.Fatal("genuine Player100 EXP grant", level, e)
	}
	return a, rev, s
}
func evolutionFacet(t *testing.T, p *pg.Pool, a identity.ActorContext, id int64) evo.Facet {
	t.Helper()
	f, e := (characterstore.EvolutionStore{}).ReadHeroTx(ctx, p, a.PlayerID, id)
	if e != nil {
		t.Fatal(e)
	}
	return f
}
func evolutionStock(t *testing.T, p *pg.Pool, a identity.ActorContext, item int64) int64 {
	t.Helper()
	var n int64
	if e := p.QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(a.PlayerID), item).Scan(&n); e != nil {
		t.Fatal(e)
	}
	return n
}
func evolutionCmd(t *testing.T, s app.Service, a identity.ActorContext, c app.Command) app.Result {
	t.Helper()
	r, e := s.Command(ctx, a, c, op())
	if e != nil {
		t.Fatal(c, e)
	}
	return r
}
func TestI7C2IRealNormalSuperAllocationStageAndCumulativeOwner(t *testing.T) {
	p := pool(t)
	a, rev, s := evolutionFixture(t, p)
	for _, id := range []int64{1, 2} {
		item := int64(40001001)
		if id == 2 {
			item = 41001
		}
		for stage := int64(1); stage <= 3; stage++ {
			cap := int64(20)
			if stage == 3 {
				cap = 40
			}
			for _, attr := range []int64{4, 7, 8, 11, 26} {
				evolutionCmd(t, s, a, app.Command{Family: app.Allocate, PartnerID: id, AttrID: attr, Amount: cap, CostItem: item})
			}
			if stage < 3 {
				evolutionCmd(t, s, a, app.Command{Family: app.Advance, PartnerID: id})
				f := evolutionFacet(t, p, a, id)
				if f.Facts.Stage != stage+1 || len(f.Facts.Points) != 0 {
					t.Fatal(f)
				}
			}
		}
		v, e := s.HeroEvolutionInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, id)
		if e != nil || v.Hero.Kind == "" || v.Facet.Facts.Stage != 3 || !reflect.DeepEqual(v.Contributions, map[int64]int64{4: 14400, 7: 320, 8: 320, 11: 6400, 26: 3600}) || evolutionStock(t, p, a, item) != 500 {
			t.Fatal(v, e, evolutionStock(t, p, a, item))
		}
		if _, e = s.Command(ctx, a, app.Command{Family: app.Advance, PartnerID: id}, op()); e == nil {
			t.Fatal("max stage advanced")
		}
	}
	// Stone stage3 is not a blood-awakening producer; preserve2F fail-closed gate.
	if _, e := (characterstore.InscriptionHeroPort{}).InscriptionEligibilityTx(ctx, p, a.PlayerID, 1, rev, time.Now().UTC()); e == nil {
		t.Fatal("stone progression manufactured blood eligibility")
	}
}

type failingEvolutionCosts struct{ app.DebitPort }

func (f failingEvolutionCosts) ApplyMaterialDebitTx(context.Context, tx.Tx, *i5.PreparedMaterialDebit) (i5.MaterialDebitResult, error) {
	return i5.MaterialDebitResult{}, errors.New("injected failure after facet write")
}
func TestI7C2IInvalidCostsAndPostWriteFailureRollBackTogether(t *testing.T) {
	p := pool(t)
	a, _, s := evolutionFixture(t, p)
	before := evolutionFacet(t, p, a, 1)
	count := evolutionStock(t, p, a, 40001001)
	for _, c := range []app.Command{{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 21, CostItem: 40001001}, {Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 1, CostItem: 41001}, {Family: app.Allocate, PartnerID: 2, AttrID: 4, Amount: 1, CostItem: 50005148}, {Family: app.Advance, PartnerID: 1}} {
		if _, e := s.Command(ctx, a, c, op()); e == nil {
			t.Fatal("invalid command accepted", c)
		}
	}
	cmd := app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 2, CostItem: 40001001}
	o := op()
	bad := s
	bad.Costs = failingEvolutionCosts{s.Costs}
	if _, e := bad.Command(ctx, a, cmd, o); e == nil {
		t.Fatal("injected failure hidden")
	}
	after := evolutionFacet(t, p, a, 1)
	if !reflect.DeepEqual(before, after) || evolutionStock(t, p, a, 40001001) != count {
		t.Fatal("rollback leaked facet/value", before, after)
	}
	if _, e := s.Command(ctx, a, cmd, o); e != nil {
		t.Fatal(e)
	}
	if evolutionStock(t, p, a, 40001001) != count-2 || evolutionFacet(t, p, a, 1).Facts.Points["4"] != 2 {
		t.Fatal("pending retry effect drift")
	}
}
func TestI7C2IReceiptConcurrencyUnknownAndPriorHeroRecovery(t *testing.T) {
	p := pool(t)
	for _, commit := range []bool{true, false} {
		a, _, s := evolutionFixture(t, p)
		bad := evolutionService(p, &libraryFaultDB{Beginner: p, commit: commit})
		c := app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 2, CostItem: 40001001}
		o := op()
		_, e := bad.Command(ctx, a, c, o)
		if !commit && e == nil {
			t.Fatal("unknown false success")
		}
		if !commit {
			_, _ = s.Command(ctx, a, app.Command{Family: app.Advance, PartnerID: 999}, op())
		}
		if _, e = s.Command(ctx, a, c, o); e != nil {
			t.Fatal("retained recovery", e)
		}
		if evolutionStock(t, p, a, 40001001) != 898 || evolutionFacet(t, p, a, 1).Facts.Points["4"] != 2 {
			t.Fatal("unknown duplicated cost")
		}
	}
	a, _, s := evolutionFixture(t, p)
	c := app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 7, Amount: 1, CostItem: 50005148}
	o := op()
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
	if evolutionStock(t, p, a, 50005148) != 899 || evolutionFacet(t, p, a, 1).Facts.Points["7"] != 1 {
		t.Fatal("sameUUID race reapplied")
	}
	bad := c
	bad.Amount = 2
	if _, e := s.Command(ctx, a, bad, o); e == nil {
		t.Fatal("sameUUID fingerprint mismatch accepted")
	}
}
func TestI7C2ICoherentForeignInputsCopiesMissingFacetAndBackfill(t *testing.T) {
	p := pool(t)
	a, rev, s := evolutionFixture(t, p)
	evolutionCmd(t, s, a, app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 3, CostItem: 50005149})
	before := evolutionFacet(t, p, a, 1)
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), app.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		scope, e := asset.NewCoherentReadScope(sc, rev, time.Now().UTC())
		if e != nil {
			return e
		}
		v, e := s.CoherentHeroInputsTx(ctx, scope, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
		if e != nil {
			return e
		}
		if v.Hero.Kind != character.NormalHero || v.Contributions[4] != 540 || v.PopulationVersion < 1 || v.Facet.Version != 2 {
			return errors.New("coherent identity/contribution drift")
		}
		v.Facet.Facts.Points["4"] = 99
		v.Contributions[4] = 99
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	if e = app.RunBackfill(ctx, s.Timed, characterstore.Store{}, characterstore.EvolutionStore{}, op()); e != nil {
		t.Fatal(e)
	}
	after := evolutionFacet(t, p, a, 1)
	if !reflect.DeepEqual(before, after) {
		t.Fatal("backfill overwrote progression")
	}
	exec(t, p, `DELETE FROM player_hero_evolution WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
	if _, e = s.HeroEvolutionInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 2); e == nil {
		t.Fatal("missing facet was qualified default")
	}
	// Current callback reads newer allocations rather than old receipt payloads.
	first := evolutionCmd(t, s, a, app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 1, CostItem: 40001001})
	evolutionCmd(t, s, a, app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 1, CostItem: 40001001})
	body, e := s.Response(ctx, a, first, op())
	if e != nil || body["evo_info"].(map[string]any)["evo_attr_points"].(map[string]int64)[strconv.FormatInt(4, 10)] != 5 {
		t.Fatal("historical callback regression", body, e)
	}
}

// EXP is produced through the accepted I5 owner. Fixtures initialize only the
// canonical starting level, function root and energy row required by that owner.
func evolutionGrantEXP(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, target int64) {
	t.Helper()
	v := i5store.Store{Queryer: p}
	cs := contentstore.Store{Queryer: p}
	rule, e := cs.ResolveProgressionPolicyTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	state, e := v.ReadProgressionTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	amount := rule.Rows[target-2].TotalExp - state.Exp
	if amount <= 0 {
		t.Fatal("EXP target must advance")
	}
	o := opPinned(rev)
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2i-native", Operation: "canonical-exp", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: evo.LifecyclePolicy}, Lines: []grant.Line{{Kind: grant.PlayerExp, Amount: amount}}}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	svc := i5.Service{Runner: tx.Runner{DB: p}, Store: v, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
	if _, e = svc.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	state, e = v.ReadProgressionTx(ctx, p, a.PlayerID)
	if e != nil || state.Level != target || rule.ValidateState(state) != nil {
		t.Fatal("canonical EXP did not reach valid target", state, e)
	}
}

type unavailableEvolutionValues struct{ app.ValuePort }

func (unavailableEvolutionValues) ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error) {
	return player.Progression{}, errors.New("qualified progression temporarily unavailable")
}
func TestI7C2IGenuinePlayer79To80GateAndRetainedProofBeforeAvailability(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	exec(t, p, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_function_state_owners(player_id,state_version,updated_at)VALUES($1,1,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_temporal_resources(player_id,resource_key,stored_amount,regen_anchor_at,state_version,policy_version,content_revision,updated_at)VALUES($1,'energy',0,clock_timestamp()-interval '1 hour',1,$2,$2,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID), rev)
	skillHero(t, p, a, rev, 10001001, 1)
	exec(t, p, `UPDATE player_heroes SET level=80,star=3 WHERE player_id=$1`, int64(a.PlayerID))
	skillBook(t, p, a, 40001001)
	exec(t, p, `UPDATE player_item_stacks SET quantity=30 WHERE player_id=$1 AND item_id=40001001`, int64(a.PlayerID))
	s := evolutionService(p, p)
	if e := app.RunBackfill(ctx, s.Timed, characterstore.Store{}, characterstore.EvolutionStore{}, op()); e != nil {
		t.Fatal(e)
	}
	evolutionGrantEXP(t, p, a, rev, 79)
	// Deliberately high Hero fixture cannot bypass the Player gate; this is a
	// negative boundary counterexample, not acceptance of that coupled base state.
	c := app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 1, CostItem: 40001001}
	if _, e := s.Command(ctx, a, c, op()); e == nil {
		t.Fatal("Player79 bypassed panel gate")
	}
	var n int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM player_hero_evolution_admissions WHERE player_id=$1`, int64(a.PlayerID)).Scan(&n); e != nil || n != 0 || evolutionStock(t, p, a, 40001001) != 30 {
		t.Fatal("ineligible intent admitted/debited", n, e)
	}
	starterBefore := evolutionStock(t, p, a, 50001050)
	evolutionGrantEXP(t, p, a, rev, 80)
	if starterBefore != 1 || evolutionStock(t, p, a, 50001050) != starterBefore {
		t.Fatal("repeated EXP reissued Pet starter")
	}
	o := op()
	first, e := s.Command(ctx, a, c, o)
	if e != nil {
		t.Fatal("genuine Player80 exact threshold", e)
	}
	blocked := s
	blocked.Values = unavailableEvolutionValues{s.Values}
	replayed, e := blocked.Command(ctx, a, c, o)
	if e != nil || first.OperationID != replayed.OperationID || evolutionStock(t, p, a, 40001001) != 29 {
		t.Fatal("known proof depended on current availability", replayed, e)
	}
	if _, e = blocked.Command(ctx, a, c, op()); e == nil {
		t.Fatal("unavailable progression accepted new intent")
	}
}
func TestI7C2IContradictoryProgressionStaleFactsAndRetiredIdentityFailClosed(t *testing.T) {
	p := pool(t)
	a, rev, s := evolutionFixture(t, p)
	c := app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 1, CostItem: 40001001}
	before := evolutionFacet(t, p, a, 1)
	exec(t, p, `UPDATE player_progression SET exp=0 WHERE player_id=$1`, int64(a.PlayerID))
	if _, e := s.Command(ctx, a, c, op()); e == nil {
		t.Fatal("contradictory Player100/EXP0 admitted")
	}
	if !reflect.DeepEqual(before, evolutionFacet(t, p, a, 1)) || evolutionStock(t, p, a, 40001001) != 900 {
		t.Fatal("invalid progression mutated owner")
	}
	// Restore the explicit counterexample fixture, retaining the original genuine
	// grant's qualified value rather than manufacturing a new progression level.
	rule, e := (contentstore.Store{}).ResolveProgressionPolicyTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_progression SET exp=$2 WHERE player_id=$1`, int64(a.PlayerID), rule.Rows[98].TotalExp)
	exec(t, p, `UPDATE player_hero_evolution SET updated_at=clock_timestamp()+interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	if _, e = s.Command(ctx, a, c, op()); e == nil {
		t.Fatal("future facet accepted")
	}
	if evolutionStock(t, p, a, 40001001) != 900 {
		t.Fatal("stale-state debit")
	}
	exec(t, p, `UPDATE player_hero_evolution SET updated_at=$2 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID), before.UpdatedAt)
	evolutionCmd(t, s, a, c)
	saved := evolutionFacet(t, p, a, 1)
	// Simulate the owning retirement transition under its accepted shared keys.
	// No new retirement endpoint or foreign-owner production SQL is introduced.
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	store := characterstore.Store{}
	if _, e = store.LockRootTx(ctx, tr, a.PlayerID); e != nil {
		t.Fatal(e)
	}
	if _, e = store.LockHeroByPartnerIDTx(ctx, tr, a.PlayerID, 1); e != nil {
		t.Fatal(e)
	}
	if _, e = tr.Exec(ctx, `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if _, e = s.Command(ctx, a, c, op()); e == nil {
		t.Fatal("retired Hero mutated")
	}
	if _, e = s.HeroEvolutionInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 1); e == nil {
		t.Fatal("retired facet projected as live")
	}
	if !reflect.DeepEqual(saved, evolutionFacet(t, p, a, 1)) {
		t.Fatal("retirement erased intrinsic provenance")
	}
}

func TestI7C2INonemptyMID1ContributorUsesCanonicalEvolutionFacet(t *testing.T) {
	p := pool(t)
	a, _, s := evolutionFixture(t, p)
	evolutionCmd(t, s, a, app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 7, CostItem: 40001001})
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	// This isolates the changed contributor seam. The actual API test separately
	// composes all production contributors and exercises bootstrap and restart.
	detail := map[string]any{}
	projection := characterstore.HeroBootstrapProjection{Content: contentstore.Store{Queryer: p}, Evolution: s}
	if e = projection.OverlayMID1(ctx, tr, a, false, time.Now().UTC(), detail); e != nil {
		t.Fatal(e)
	}
	row := detail["49"].(map[string]any)["heros"].(map[string]any)["1"].(map[string]any)
	if row["evo_stage"] != int64(1) || row["evo_attr_points"].(map[string]int64)["4"] != 7 {
		t.Fatal("MID1 contributor used default/foreign points", row)
	}
}

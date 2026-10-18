//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"testing"
)

func privateMetricProvider(p *pg.Pool) app.CanonicalMetricProvider {
	v := metricProvider(p)
	v.Roster = characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: contentstore.Store{}}
	return v
}
func privateMetricCommands(p *pg.Pool, db tx.Beginner) app.CommandService {
	s := metricCommands(p, db)
	s.Metrics = privateMetricProvider(p)
	return s
}
func privateRead(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, ids []int64) ([]app.MetricObservation, error) {
	t.Helper()
	at, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	o := opPinned(rev)
	o.Policies, e = policy.NewSet(append(o.Policies.Refs(), policy.Ref{Name: "roster-metrics", Version: app.RosterMetricPolicy})...)
	if e != nil {
		t.Fatal(e)
	}
	var out []app.MetricObservation
	_, e = (tx.Runner{DB: p}).Run(ctx, o, lib.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out, e = privateMetricProvider(p).ReadMetricsScopeTx(c, sc, app.MetricRequest{PlayerID: a.PlayerID, IDs: ids, ContentRevision: rev, ObservedAt: at})
		return e
	})
	return out, e
}
func privateHeroService(p *pg.Pool) hero.Service {
	st := characterstore.Store{Queryer: p}
	co := contentstore.Store{Queryer: p}
	ec := i5store.Store{Queryer: p}
	return hero.Service{Runner: tx.Runner{DB: p}, Store: st, Fencer: ec, Content: co, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, AcquisitionStore: st, Acquisition: co, ProgressionStore: st, Progression: co, Economy: i5.HeroProgressionDebiter{Store: ec, Content: co}, Backpack: ec, MaterialCosts: i5.MaterialCostDebiter{Store: ec, Content: co}, PlayerLevel: i5.CrossOwner{Store: ec}, Capacity: skillTestCapacity{}}
}
func privateSeed(t *testing.T, p *pg.Pool) (identity.ActorContext, string) {
	t.Helper()
	rev := installed(t, p)
	a := actor(t, p)
	exec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,1,0,1,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_pet_roots(player_id,next_pet_id,first_free_hatch_used,state_version,created_at,updated_at)VALUES($1,1,false,1,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'mana',100000000,1,clock_timestamp())`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(a.PlayerID))
	return a, rev
}
func TestI7C4CPrivateActualSummonEvolutionPetAndHistoricReplay(t *testing.T) {
	p := pool(t)
	a, rev := privateSeed(t, p)
	co := contentstore.Store{Queryer: p}
	hs := privateHeroService(p)
	def, e := co.HeroNormalSummonTx(ctx, p, rev, 10001001)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,100000,1,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID), def.Template.FragmentItemID)
	empty, e := privateRead(t, p, a, rev, []int64{1001, 1002, 1008, 1009})
	if e != nil {
		t.Fatal(e)
	}
	for _, v := range empty {
		if v.Value != 0 {
			t.Fatal(empty)
		}
	}
	summonOp := op()
	h, e := hs.SummonNormal(ctx, a, 10001001, def.Template.FragmentItemID, def.FragmentCount, summonOp)
	if e != nil {
		t.Fatal(e)
	}
	s := privateMetricCommands(p, p)
	q := app.Command{Kind: app.ShowCommand, Show: []int64{1001, 1008, 1009}}
	assignment := op()
	first, e := s.Execute(ctx, a, q, assignment)
	if e != nil || first.Show["1001"] != 1 || first.Show["1008"] != h.Star {
		t.Fatal(first, e)
	}
	if _, e = hs.SummonNormal(ctx, a, 10001001, def.Template.FragmentItemID, def.FragmentCount, summonOp); e != nil {
		t.Fatal(e)
	}
	if _, e = hs.SummonNormal(ctx, a, 10001001, def.Template.FragmentItemID, def.FragmentCount, op()); e == nil {
		t.Fatal("duplicate origin created")
	}
	evolveOp := op()
	if e = hs.Evolve(ctx, a, h.PartnerID, evolveOp); e != nil {
		t.Fatal(e)
	}
	if e = hs.Evolve(ctx, a, h.PartnerID, evolveOp); e != nil {
		t.Fatal(e)
	}
	after, e := privateRead(t, p, a, rev, []int64{1001, 1008})
	if e != nil || after[0].Value != 1 || after[1].Value != h.Star+1 || after[0].PopulationDigest == first.MetricObservations[0].PopulationDigest {
		t.Fatal(after, e)
	}
	replay, e := s.Execute(ctx, a, q, assignment)
	if e != nil || !reflect.DeepEqual(first, replay) {
		t.Fatal("receipt reinterpreted evolution", replay, e)
	}
	// Egg inventory is not a Pet. Genuine existing Summon creates one canonical
	// instance and repeated acquisition returns that instance rather than another.
	pd, e := co.PetAcquisitionTx(ctx, p, rev, 10010001)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,2,1,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID), pd.EggItemID)
	beforePet, e := privateRead(t, p, a, rev, []int64{1002})
	if e != nil || beforePet[0].Value != 0 {
		t.Fatal(beforePet, e)
	}
	ec := i5store.Store{Queryer: p}
	ps := pet.Service{Runner: tx.Runner{DB: p}, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: characterstore.Store{Queryer: p}, Fencer: ec, Content: co, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Acquisition: i5.PetAcquisitionDebiter{Store: ec, Content: co}, Scalar: i5.CrossOwner{Store: ec}}
	one, e := ps.Summon(ctx, a, 10010001, op())
	if e != nil {
		t.Fatal(e)
	}
	two, e := ps.Summon(ctx, a, 10010001, op())
	if e != nil || one.PetID != two.PetID {
		t.Fatal(one, two, e)
	}
	pets, e := privateRead(t, p, a, rev, []int64{1002})
	if e != nil || pets[0].Value != 1 || pets[0].PrivatePolicy != app.RosterMetricPolicy {
		t.Fatal(pets, e)
	}
}
func TestI7C4CPrivateMissingOwnerRollbackAndUnknownCommit(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	s := privateMetricCommands(p, p)
	if _, e := s.Execute(ctx, a, app.Command{Kind: app.ShowCommand, Show: []int64{1001}}, op()); e == nil {
		t.Fatal("missing hero root becamezero")
	}
	if _, e := s.Execute(ctx, a, app.Command{Kind: app.ShowCommand, Show: []int64{1011}}, op()); e != nil {
		t.Fatal("legacy creation regressed", e)
	}
	b, rev := privateSeed(t, p)
	q := app.Command{Kind: app.ShowCommand, Show: []int64{1001, 1002, 1008, 1009}}
	o := op()
	if _, e := privateMetricCommands(p, metricCommitDB{p, false}).Execute(ctx, b, q, o); e == nil {
		t.Fatal("rollback accepted")
	}
	first, e := privateMetricCommands(p, metricCommitDB{p, true}).Execute(ctx, b, q, o)
	if e != nil {
		t.Fatal(e)
	}
	again, e := privateMetricCommands(p, p).Execute(ctx, b, q, o)
	if e != nil || !reflect.DeepEqual(first, again) {
		t.Fatal(again, e)
	}
	exec(t, p, `DELETE FROM player_pet_roots WHERE player_id=$1`, int64(b.PlayerID))
	if _, e = privateRead(t, p, b, rev, []int64{1002}); e == nil {
		t.Fatal("missing pet root becamezero")
	}
	if _, e = privateRead(t, p, b, rev, []int64{1001, 1008}); e != nil {
		t.Fatal("hero read depends on pets", e)
	}
}
func TestI7C4CPrivateSnapshotDuringCanonicalEvolution(t *testing.T) {
	p := pool(t)
	a, rev := privateSeed(t, p)
	h := skillHero(t, p, a, rev, 10001001, 1)
	exec(t, p, `UPDATE player_heroes SET star=1 WHERE player_id=$1`, int64(a.PlayerID))
	h.Star = 1
	co := contentstore.Store{Queryer: p}
	d, e := co.HeroTemplateProgressionTx(ctx, p, rev, h.TableID)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,100000,1,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID), d.FragmentItemID)
	o := opPinned(rev)
	o.Policies, _ = policy.NewSet(append(o.Policies.Refs(), policy.Ref{Name: "roster-metrics", Version: app.RosterMetricPolicy})...)
	at, _ := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	_, e = (tx.Runner{DB: p}).Run(ctx, o, lib.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		req := app.MetricRequest{PlayerID: a.PlayerID, IDs: []int64{1001, 1008}, ContentRevision: rev, ObservedAt: at}
		before, e := privateMetricProvider(p).ReadMetricsScopeTx(c, sc, req)
		if e != nil {
			return e
		}
		if e = privateHeroService(p).Evolve(ctx, a, h.PartnerID, op()); e != nil {
			return e
		}
		after, e := privateMetricProvider(p).ReadMetricsScopeTx(c, sc, req)
		if e != nil {
			return e
		}
		if !reflect.DeepEqual(before, after) {
			return errors.New("mixed character generations")
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	fresh, e := privateRead(t, p, a, rev, []int64{1001, 1008})
	if e != nil || fresh[0].Value != 1 || fresh[1].Value != 2 {
		t.Fatal(fresh, e)
	}
}

func TestI7C4CPrivateAwakenCountsNormalAndSuperWithoutSkinEligibility(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	catalog, e := (contentstore.Store{}).ReadPlayerDisplayCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	ids := map[string]int64{}
	for _, h := range catalog.HeroTemplates {
		if h.BeforeAwaken > 0 && ids[h.Kind] == 0 {
			ids[h.Kind] = h.TableID
		}
	}
	if ids["NORMAL"] == 0 || ids["SUPER"] == 0 {
		t.Fatal("source awaken templates absent", ids)
	}
	// Explicit pre-existing progression fixtures exercise the count predicate,
	// independently of the Normal-only 4A avatar eligibility rule.
	skillHero(t, p, a, rev, ids["NORMAL"], 1)
	skillHero(t, p, a, rev, ids["SUPER"], 2)
	got, e := privateRead(t, p, a, rev, []int64{1001, 1008, 1009})
	if e != nil || got[0].Value != 2 || got[1].Value != 10 || got[2].Value != 2 {
		t.Fatal(got, e)
	}
	exec(t, p, `UPDATE player_heroes SET updated_at=clock_timestamp()+interval '1 hour',state_version=state_version+1 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	if _, e = privateRead(t, p, a, rev, []int64{1009}); e == nil {
		t.Fatal("future owner state accepted")
	}
}

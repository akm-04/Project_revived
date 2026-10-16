//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	boot "gxb.local/backend/v2/internal/application/bootstrap"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	conquer "gxb.local/backend/v2/internal/application/conquerschool"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	profile "gxb.local/backend/v2/internal/application/publicprofile"
	app "gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	dp "gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"reflect"
	"strings"
	"testing"
	"time"
)

func statOwned(p *pg.Pool) *ca.OwnedCompositeBuilder {
	hs := characterstore.Store{Queryer: p}
	cs := contentstore.Store{Queryer: p}
	return &ca.OwnedCompositeBuilder{
		HeroBase: hero.BaseObservationReader{Store: hs, Content: cs}, PetBase: pet.BaseObservationReader{Store: hs},
		HeroEquipment: hero.CA8EquipmentObservationAdapter{Reader: hero.EquipmentStateReader{Store: hs, Content: cs}}, PetEquipment: pet.CA8EquipmentObservationAdapter{Reader: pet.EquipmentStateReader{Store: hs, Content: cs}},
		HeroPractice: hero.CA8PracticeObservationAdapter{Reader: hero.PracticeContributionReader{Store: hs, Content: cs}}, PetPractice: pet.CA8PracticeObservationAdapter{Reader: pet.PracticeContributionReader{Store: hs, Content: cs}},
		HeroAppearance: hero.CA8AppearanceObservationAdapter{Reader: hero.AppearanceContributionReader{Store: hs, Content: cs}}, PetAppearance: pet.CA8AppearanceObservationAdapter{Reader: pet.AppearanceContributionReader{Store: hs, Content: cs}},
	}
}
func statService(p *pg.Pool) app.Service {
	return app.Service{Owned: statOwned(p), Pets: characterstore.Store{Queryer: p}, Content: contentstore.Store{Queryer: p}, Skills: hero.RawSkillObservationReader{Store: characterstore.Store{Queryer: p}, Content: contentstore.Store{Queryer: p}}, Library: libraryService(p, p), Dorm: dormService(p, p), Book: bookService(p, p), Courses: courseService(p, p), Inscription: inscriptionService(p, p), Element: elementService(p, p), Spirit: spiritService(p, p), Evolution: evolutionService(p, p), Conquer: conquerService(p)}
}

// Explicit fixture attestation tests the conditional Hero composition path.
// It is not a genuine raw blood-awakening producer and is never production-wired.
type statAwakeningFixture struct {
	p   *pg.Pool
	bad bool
}

func (f statAwakeningFixture) RawAwakeningTx(c context.Context, s ca.CoherentReadScope, r character.HeroRef) (app.AwakeningObservation, error) {
	h, e := (characterstore.Store{}).ReadHeroByPartnerIDTx(c, s.Queryer(), r.PlayerID, r.PartnerID)
	if e != nil {
		return app.AwakeningObservation{}, e
	}
	v := app.AwakeningObservation{Ref: r, StateVersion: h.StateVersion, ContentRevision: s.ContentRevision, ObservedAt: s.ObservedAt, Known: true, RawStage: 0, ProducerReference: "CONDITIONAL_TEST_FIXTURE_NOT_GENUINE_PRODUCER"}
	if f.bad {
		v.StateVersion++
	}
	return v, nil
}
func statPet(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string) character.Pet {
	t.Helper()
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (characterstore.PetBootstrapContributor{}).PersistCharacterBootstrap(ctx, tr, logicalserver.BootstrapContext{PlayerID: a.PlayerID, Operation: opPinned(rev)}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	cs := contentstore.Store{Queryer: p}
	def, e := cs.PetAcquisitionTx(ctx, p, rev, 10010001)
	if e != nil {
		t.Fatal(e)
	}
	skillBook(t, p, a, def.EggItemID)
	iv := i5store.Store{Queryer: p}
	s := pet.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: characterstore.Store{Queryer: p}, Fencer: iv, Content: cs, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Acquisition: i5.PetAcquisitionDebiter{Store: iv, Content: cs}, Scalar: i5.CrossOwner{Store: iv}}
	o := opPinned(rev)
	v, e := s.Summon(ctx, a, def.TableID, o)
	if e != nil {
		t.Fatal(e)
	}
	again, e := s.Summon(ctx, a, def.TableID, o)
	if e != nil || !reflect.DeepEqual(v, again) {
		t.Fatal("summon replay", e)
	}
	return v
}
func statRead(t *testing.T, p *pg.Pool, rev string, f func(ca.CoherentReadScope) error) error {
	t.Helper()
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), conquer.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var at time.Time
		if e := sc.Tx.QueryRow(c, "SELECT clock_timestamp()").Scan(&at); e != nil {
			return e
		}
		s, e := ca.NewCoherentReadScope(sc, rev, at)
		if e != nil {
			return e
		}
		return f(s)
	})
	return e
}
func TestI7C3BNativePetActualSummonCanonicalReadAndNoWrites(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	v := statPet(t, p, a, rev)
	s := statService(p)
	var first app.Result
	if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		var e error
		first, e = s.PetTx(ctx, sc, v.Ref(), app.View{Kind: app.Self, Viewer: a.PlayerID})
		return e
	}); e != nil {
		t.Fatal(e)
	}
	if first.Stats.Model != "Pet" || first.Stats.Force <= 0 {
		t.Fatal(first)
	}
	if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		again, e := s.PetTx(ctx, sc, v.Ref(), app.View{Kind: app.Self, Viewer: a.PlayerID})
		if e == nil && (!reflect.DeepEqual(first.Stats.Total, again.Stats.Total) || first.Stats.Force != again.Stats.Force) {
			t.Fatal("reload changed stats")
		}
		return e
	}); e != nil {
		t.Fatal(e)
	}
	// Nonzero applied Practice is already included in the accepted contribution.
	// Typed owner write is a conditional fixture, not a new Practice origin.
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	next := v
	next.StateVersion++
	next.Practice = character.PracticeAttrs{20, 30, 40}
	next.UpdatedAt = time.Now().UTC()
	if e = (characterstore.Store{}).SavePetPracticeTx(ctx, tr, next, v.StateVersion); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if e = statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		after, e := s.PetTx(ctx, sc, v.Ref(), app.View{Kind: app.Self, Viewer: a.PlayerID})
		if e == nil && (math.Abs(after.Stats.Total[0]-first.Stats.Total[0]-20) > 1e-8 || math.Abs(after.Stats.Total[1]-first.Stats.Total[1]-30) > 1e-8 || math.Abs(after.Stats.Total[2]-first.Stats.Total[2]-40) > 1e-8) {
			t.Fatal("Practice duplicated or omitted", first.Stats.Total[:3], after.Stats.Total[:3])
		}
		return e
	}); e != nil {
		t.Fatal(e)
	}

	if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		_, e := s.PetTx(ctx, sc, character.PetRef{PlayerID: a.PlayerID, PetID: v.PetID + 999}, app.View{Kind: app.Self, Viewer: a.PlayerID})
		if e == nil {
			t.Fatal("missing Pet became zero")
		}
		return nil
	}); e != nil {
		t.Fatal(e)
	}
}
func TestI7C3BNativeCatalogTamperRejectedRollback(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	s := contentstore.Store{Queryer: p}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = s.StatInputCatalogTx(ctx, tr, rev); e != nil {
		t.Fatal(e)
	}
	if _, e = s.StatInputCatalogTx(ctx, tr, strings.Repeat("0", 64)); e == nil {
		t.Fatal("missing content became empty")
	}
	if _, e = tr.Exec(ctx, "UPDATE content_stat_input_catalogs SET payload=jsonb_set(payload,'{policy_id}','\"tampered\"') WHERE revision_id=$1", rev); e != nil {
		t.Fatal(e)
	}
	if _, e = s.StatInputCatalogTx(ctx, tr, rev); e == nil {
		t.Fatal("payload hash unchecked")
	}
	tr.Rollback(ctx)
	if _, e = s.StatInputCatalogTx(ctx, p, rev); e != nil {
		t.Fatal("rollback lost content", e)
	}
}
func statHeroPrerequisites(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string) {
	t.Helper()
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	o := opPinned(rev)
	o.StartedAt = time.Now().UTC().Add(-time.Minute)
	b := logicalserver.BootstrapContext{PlayerID: a.PlayerID, Operation: o, BootstrapProfileVersion: "CONDITIONAL_OWNER_FACT_FIXTURE"}
	for _, c := range []boot.CharacterBootstrapPersistenceContributor{dormstore.BootstrapContributor{Revision: rev}, bookstore.BootstrapContributor{Revision: rev}, coursestore.BootstrapContributor{Revision: rev}, inscriptionstore.BootstrapContributor{Revision: rev}, elementstore.BootstrapContributor{Revision: rev}, spiritstore.BootstrapContributor{Revision: rev}, conquerstore.BootstrapContributor{Revision: rev}} {
		if e = c.PersistCharacterBootstrap(ctx, tr, b); e != nil {
			t.Fatal(c.Name(), e)
		}
	}
	for _, c := range []interface {
		InitFreshHeroTx(context.Context, tx.Tx, character.HeroRef, time.Time) error
	}{dormstore.Store{}, coursestore.Store{}, inscriptionstore.Store{}, spiritstore.Store{}, characterstore.EvolutionStore{}} {
		if e = c.InitFreshHeroTx(ctx, tr, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}, o.StartedAt); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}
func TestI7C3BNativeHeroConditionalOwnersMissingAwakeningAndStaleRoot(t *testing.T) {
	p := pool(t)
	a, rev := libraryFixture(t, p, false)
	statHeroPrerequisites(t, p, a, rev)
	s := statService(p)
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		_, e := s.HeroTx(ctx, sc, ref, app.View{Kind: app.Self, Viewer: a.PlayerID})
		if !errors.Is(e, app.ErrUnqualified) {
			t.Fatal("missing genuine awakening defaulted", e)
		}
		return nil
	}); e != nil {
		t.Fatal(e)
	}
	s.Awakening = statAwakeningFixture{p: p}
	if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		v, e := s.HeroTx(ctx, sc, ref, app.View{Kind: app.Self, Viewer: a.PlayerID})
		if e != nil {
			return e
		}
		if v.Stats.Model != "NormalHero" || v.Stats.Force <= 0 {
			t.Fatal(v)
		}
		return nil
	}); e != nil {
		t.Fatal("conditional owner composition", e)
	}
	s.Awakening = statAwakeningFixture{p: p, bad: true}
	if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		_, e := s.HeroTx(ctx, sc, ref, app.View{Kind: app.Self, Viewer: a.PlayerID})
		if e == nil {
			t.Fatal("mixed Hero state version accepted")
		}
		return nil
	}); e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = tr.Exec(ctx, "UPDATE player_library_roots SET updated_at=clock_timestamp()+interval '1 hour' WHERE player_id=$1", int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	ls := libraryService(p, p)
	at := time.Now().UTC()
	scope := lib.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: at}
	if _, e = ls.HeroLibraryInputsTx(ctx, tr, scope, 1); e == nil {
		t.Fatal("future Library root accepted")
	}
	if _, e = ls.PlayerCollectionInputsTx(ctx, tr, scope); e == nil {
		t.Fatal("future collection root accepted")
	}
}

type forbiddenStats struct{ called *bool }

func (f forbiddenStats) HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, app.View) (app.Result, error) {
	*f.called = true
	return app.Result{}, errors.New("stats before privacy")
}
func (f forbiddenStats) PetTx(context.Context, ca.CoherentReadScope, character.PetRef, app.View) (app.Result, error) {
	*f.called = true
	return app.Result{}, errors.New("stats before privacy")
}
func TestI7C3BNativePublicSelectedStatsAndBlockPrivacy(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	v := statPet(t, p, a, rev)
	other := actor(t, p)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	at := time.Now().UTC()
	store := publicprofilestore.Store{}
	if e = store.InsertRootTx(ctx, tr, profile.Root{PlayerID: a.PlayerID, Preferences: dp.Defaults(), StateVersion: 1, CreatedAt: at, UpdatedAt: at}); e != nil {
		t.Fatal(e)
	}
	if e = store.ReplaceSelectionTx(ctx, tr, a.PlayerID, profile.Selection{-v.PetID}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	reader := profile.ShowcaseReader{Slots: store, Content: contentstore.Store{}, Basic: profile.BasicReader{Roots: profile.RootService{Store: store}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, PlayerBasis: i5store.Store{}, Relations: socialrelationstore.Store{}, Content: contentstore.Store{}}, Characters: ca.PublicShowcaseCharacterReader{OwnerComposite: statOwned(p)}}
	run := func(actor identity.ActorContext, provider profile.ShowcaseStatProvider) error {
		_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), conquer.Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
			var at time.Time
			if e := sc.Tx.QueryRow(c, "SELECT clock_timestamp()").Scan(&at); e != nil {
				return e
			}
			out, e := reader.ReadSelectedStatsTx(c, sc, actor, a.PlayerID, 1, rev, at, provider)
			if e == nil && out.Stats.Stats.Model != "Pet" {
				t.Fatal("wrong selected model")
			}
			return e
		})
		return e
	}
	if e = run(a, statService(p)); e != nil {
		t.Fatal("self selected", e)
	}
	if e = run(other, statService(p)); e != nil {
		t.Fatal("foreign selected", e)
	}
	exec(t, p, "INSERT INTO player_social_roots(player_id,created_at,updated_at)VALUES($1,clock_timestamp(),clock_timestamp()),($2,clock_timestamp(),clock_timestamp())", int64(other.PlayerID), int64(a.PlayerID))
	exec(t, p, "INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp())", int64(other.PlayerID), int64(a.PlayerID))
	called := false
	e = run(other, forbiddenStats{called: &called})
	if !errors.Is(e, profile.ErrShowcasePrivate) || called {
		t.Fatal("privacy was bypassed", e, called)
	}
	raw, _ := json.Marshal(v)
	if len(raw) == 0 {
		t.Fatal("missing canonical fact")
	}
}

// Nondefault canonical owner facts are explicit conditional fixtures. Their
// source-derived numerical use is qualified; fixture writes are not origins.
func TestI7C3BNativeNondefaultBookCourseAndSelfCollectionRequiredness(t *testing.T) {
	p := pool(t)
	a, rev := libraryFixture(t, p, false)
	statHeroPrerequisites(t, p, a, rev)
	s := statService(p)
	s.Awakening = statAwakeningFixture{p: p}
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	read := func(s app.Service, view app.View) app.Result {
		var v app.Result
		if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error { var e error; v, e = s.HeroTx(ctx, sc, ref, view); return e }); e != nil {
			t.Fatal(e)
		}
		return v
	}
	view := app.View{Kind: app.Self, Viewer: a.PlayerID}
	before := read(s, view)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	bs := bookstore.Store{}
	b, e := bs.LockRootTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	old := b.Version
	b.Version++
	b.Facts.Skills[10010001] = 1
	b.UpdatedAt = time.Now().UTC()
	if e = bs.SaveRootTx(ctx, tr, b, old); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	after := read(s, view)
	if math.Abs(after.Stats.Total[3]-before.Stats.Total[3]-400) > 1e-8 || math.Abs(after.Stats.WithoutBook[3]-before.Stats.WithoutBook[3]) > 1e-8 {
		t.Fatal("book total/display separation", before.Stats.Total[3], after.Stats.Total[3])
	}
	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	cs := coursestore.Store{}
	h, e := cs.LockHeroTx(ctx, tr, a.PlayerID, 1)
	if e != nil {
		t.Fatal(e)
	}
	old = h.Version
	h.Version++
	h.Facts.Courses = []course.Record{{ID: 100101, Progress: 100, Quality: 1, Skill: 1, EXP: 0}}
	h.UpdatedAt = time.Now().UTC()
	if e = cs.SaveHeroTx(ctx, tr, h, old); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	trained := read(s, view)
	if math.Abs(trained.Stats.Total[0]-after.Stats.Total[0]-23.5) > 1e-8 {
		t.Fatal("course number+quality*step not applied", after.Stats.Total[0], trained.Stats.Total[0])
	}
	s.Library = unavailableCollection{Library: s.Library}
	if e = statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		_, e := s.HeroTx(ctx, sc, ref, view)
		if e == nil {
			t.Fatal("self collection unavailable became zero")
		}
		return nil
	}); e != nil {
		t.Fatal(e)
	}
	foreign := app.View{Kind: app.Foreign, Viewer: actor(t, p).PlayerID}
	_ = read(s, foreign)
}

type unavailableCollection struct{ app.Library }

func (unavailableCollection) PlayerCollectionInputsTx(context.Context, tx.Queryer, lib.InputScope) (lib.CollectionInputs, error) {
	return lib.CollectionInputs{}, errors.New("explicit unavailable collection test")
}

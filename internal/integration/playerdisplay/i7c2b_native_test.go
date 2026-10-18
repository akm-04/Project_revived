//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	gen "gxb.local/backend/v2/internal/application/generation"
	i5 "gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func libraryService(p *pg.Pool, db tx.Beginner) app.Service {
	content := contentstore.Store{Queryer: p}
	hero := characterstore.Store{Queryer: p}
	inv := i5store.Store{Queryer: p}
	s := app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Heroes: characterstore.LibraryHeroPort{Store: hero}, Library: librarystore.Store{}, Content: content, Players: i4store.PlayerRootLocker{}, Fence: inv, Costs: i5.MaterialCostDebiter{Store: inv, Content: content}, Receipts: kernelstore.Store{}}
	s.Achievements = ach.Service{Store: achievementstore.Store{}, Content: content, Population: s}
	s.Roster = characterstore.HeroBootstrapProjection{Content: content, Library: s}
	return s
}
func libraryFixture(t *testing.T, p *pg.Pool, married bool) (identity.ActorContext, string) {
	t.Helper()
	rev := installed(t, p)
	a := actor(t, p)
	h := skillHero(t, p, a, rev, 10001001, 1)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	s := librarystore.Store{}
	at := time.Now().Add(-time.Minute).UTC()
	if e = s.EnsurePlayerRootTx(ctx, tr, a.PlayerID, at); e != nil {
		t.Fatal(e)
	}
	if _, e = s.BackfillMissingHeroTx(ctx, tr, h.Ref(), at); e != nil {
		t.Fatal(e)
	}
	if married {
		f, e := s.LockHeroTx(ctx, tr, h.Ref())
		if e != nil {
			t.Fatal(e)
		}
		f.Married = true
		f.Favor = 2000
		f.StateVersion++
		f.UpdatedAt = at
		if e = s.SaveHeroTx(ctx, tr, f, 1); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'mana',5000000,1,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	for _, id := range []int64{50005013, 50001112, 50001375} {
		skillBook(t, p, a, id)
		exec(t, p, `UPDATE player_item_stacks SET quantity=100 WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), id)
	}
	return a, rev
}
func libraryFacts(t *testing.T, p *pg.Pool, a identity.ActorContext) lib.HeroFacts {
	t.Helper()
	f, e := (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil {
		t.Fatal(e)
	}
	return f
}
func libraryAmount(t *testing.T, p *pg.Pool, a identity.ActorContext, key string) int64 {
	t.Helper()
	var n int64
	if e := p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2`, int64(a.PlayerID), key).Scan(&n); e != nil {
		t.Fatal(e)
	}
	return n
}
func TestI7C2BLibraryGiftMarriageFeedingAndReplay(t *testing.T) {
	p := pool(t)
	a, rev := libraryFixture(t, p, false)
	s := libraryService(p, p)
	if _, e := s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("unmarried", e)
	}
	if libraryAmount(t, p, a, "mana") != 5000000 {
		t.Fatal("unmarried charge")
	}
	if _, e := s.Command(ctx, a, app.Command{Family: app.Gift, PartnerID: 1, Value: 50001112}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("ring gate", e)
	}
	var original operation.Context
	var originalResult app.Result
	for i := 0; i < 20; i++ {
		o := op()
		r, e := s.Command(ctx, a, app.Command{Family: app.Gift, PartnerID: 1, Value: 50005013}, o)
		if e != nil {
			t.Fatal(i, e)
		}
		if i == 0 {
			original = o
			originalResult = r
		}
	}
	if f := libraryFacts(t, p, a); f.Favor != 2000 || f.Married {
		t.Fatal(f)
	}
	replay, e := s.Command(ctx, a, app.Command{Family: app.Gift, PartnerID: 1, Value: 50005013}, original)
	if e != nil || replay.StateVersion != originalResult.StateVersion || replay.Favor != 105 {
		t.Fatal("historic gift", replay, e)
	}
	ring := app.Command{Family: app.Gift, PartnerID: 1, Value: 50001112}
	r, e := s.Command(ctx, a, ring, op())
	if e != nil || !r.Married || !r.Changed {
		t.Fatal(r, e)
	}
	r, e = s.Command(ctx, a, ring, op())
	if e != nil || r.Changed {
		t.Fatal("ring noop", r, e)
	}
	scope := app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}
	obs, e := s.MarriedHeroCountTx(ctx, p, scope)
	if e != nil || obs.MarriedCount != 1 {
		t.Fatal(obs, e)
	}
	roll := op()
	r, e = s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, roll)
	if e != nil || !r.HasPreview {
		t.Fatal(r, e)
	}
	f := libraryFacts(t, p, a)
	if f.Applied != (lib.FeedAttrs{}) || f.Pending == nil || libraryAmount(t, p, a, "mana") != 4500000 {
		t.Fatal("paid preview", f)
	}
	redo, e := s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 2}, op())
	if e != nil {
		t.Fatal(e)
	}
	r, e = s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, roll)
	if e != nil || r.Delta != f.Pending.Delta || libraryAmount(t, p, a, "mana") != 4500000 {
		t.Fatal("historical feed", r, e)
	}
	r, e = s.Command(ctx, a, app.Command{Family: app.Save, PartnerID: 1}, op())
	if e != nil || r.Applied != redo.Delta {
		t.Fatal("save current redo", r, e)
	}
	r, e = s.Command(ctx, a, app.Command{Family: app.Save, PartnerID: 1}, op())
	if e != nil || r.Changed {
		t.Fatal("save noop", r, e)
	}
	for _, mid := range []uint16{49, 836, 853, 2784} {
		body, e := s.Read(ctx, a, op(), mid, 1)
		if e != nil {
			t.Fatal(mid, e)
		}
		if mid == 853 {
			if _, ok := body["feed_add"]; ok {
				t.Fatal("fabricated missing preview", body)
			}
		}
		if mid == 49 {
			row := body["heros"].(map[string]any)["1"].(map[string]any)
			if row["favor_degree"] != int64(2000) || row["is_married"] != int64(1) {
				t.Fatal(body)
			}
		}
	}
}

// Fault only the economic transaction COMMIT; admission is already durable.
type libraryFaultDB struct {
	tx.Beginner
	n      atomic.Int32
	commit bool
}

func (d *libraryFaultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	tr, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	if d.n.Add(1) == 2 {
		return faultTx{Tx: tr, commit: d.commit}, nil
	}
	return tr, nil
}
func TestI7C2BLibraryUnknownRollbackPendingAndConcurrency(t *testing.T) {
	p := pool(t)
	for _, committed := range []bool{true, false} {
		a, _ := libraryFixture(t, p, true)
		d := &libraryFaultDB{Beginner: p, commit: committed}
		s := libraryService(p, d)
		o := op()
		c := app.Command{Family: app.Feed, PartnerID: 1, Value: 1}
		r, e := s.Command(ctx, a, c, o)
		if committed {
			if e != nil || !r.HasPreview || libraryAmount(t, p, a, "mana") != 4500000 {
				t.Fatal("commit proof", r, e)
			}
		} else {
			var u *tx.UnknownCommitError
			if !errors.As(e, &u) || libraryFacts(t, p, a).Pending != nil || libraryAmount(t, p, a, "mana") != 5000000 {
				t.Fatal("unknown absent", e)
			}
			// A fresh request after reopen must execute retained original entropy/time/ID.
			reopened := pool(t)
			r, e = libraryService(reopened, reopened).Command(ctx, a, c, op())
			if e != nil || r.OperationID != o.ID || !r.HasPreview || libraryAmount(t, p, a, "mana") != 4500000 {
				t.Fatal("pending retained", r, e)
			}
		}
	}
	a, _ := libraryFixture(t, p, true)
	s := libraryService(p, p)
	o := op()
	var wg sync.WaitGroup
	errs := make(chan error, 6)
	for i := 0; i < 6; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, o)
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
	if libraryAmount(t, p, a, "mana") != 4500000 {
		t.Fatal("duplicate debit")
	}
	// SAVE/redo serialize against the same Library root; no candidate enters applied before SAVE.
	errs = make(chan error, 2)
	for _, c := range []app.Command{{Family: app.Feed, PartnerID: 1, Value: 3}, {Family: app.Save, PartnerID: 1}} {
		wg.Add(1)
		go func(c app.Command) {
			defer wg.Done()
			_, e := s.Command(ctx, a, c, op())
			if e != nil && !errors.Is(e, app.ErrRejected) {
				errs <- e
			}
		}(c)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		t.Fatal(e)
	}
	if e := libraryFacts(t, p, a).Validate(); e != nil {
		t.Fatal(e)
	}
}
func TestI7C2BLibraryCollectionPopulationAndRetirement(t *testing.T) {
	p := pool(t)
	a, rev := libraryFixture(t, p, true)
	s := libraryService(p, p)
	for _, id := range []int64{1, 2} {
		if id == 2 {
			h := skillHero(t, p, a, rev, 11001001, id)
			tr, e := p.Begin(ctx, tx.Options{})
			if e != nil {
				t.Fatal(e)
			}
			if _, e = (librarystore.Store{}).BackfillMissingHeroTx(ctx, tr, h.Ref(), time.Now().Add(-time.Minute)); e != nil {
				t.Fatal(e)
			}
			if e = tr.Commit(ctx); e != nil {
				t.Fatal(e)
			}
		}
		if _, e := s.Command(ctx, a, app.Command{Family: app.NormalClaim, PartnerID: id}, op()); e != nil {
			t.Fatal(e)
		}
	}
	scope := app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}
	before, e := s.PlayerCollectionInputsTx(ctx, p, scope)
	if e != nil {
		t.Fatal(e)
	}
	cat, e := (contentstore.Store{}).LibraryCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	f := libraryFacts(t, p, a)
	want, e := f.NormalContribution(cat.NormalCollections[10001001])
	if e != nil || want.Hundredths <= 0 || before.Contributions[want.AttrID] != 2*want.Hundredths {
		t.Fatal("all instances", before, want, e)
	}
	r, e := s.Command(ctx, a, app.Command{Family: app.NormalClaim, PartnerID: 1}, op())
	if e != nil || r.Changed {
		t.Fatal("claim noop", r, e)
	}
	// Owning retirement operation under Character root makes retained Library history non-live.
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	hs := characterstore.Store{}
	if _, e = hs.LockRootTx(ctx, tr, a.PlayerID); e != nil {
		t.Fatal(e)
	}
	if _, e = tr.Exec(ctx, `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	scope.ObservedAt = time.Now().UTC()
	after, e := s.PlayerCollectionInputsTx(ctx, p, scope)
	if e != nil || after.MarriedCount != 0 || after.Contributions[want.AttrID] != want.Hundredths {
		t.Fatal("retired excluded", after, e)
	}
	if _, e = s.Command(ctx, a, app.Command{Family: app.Save, PartnerID: 1}, op()); e == nil {
		t.Fatal("retired save")
	}
	if _, e = s.HeroLibraryInputsTx(ctx, p, scope, 1); e == nil {
		t.Fatal("orphan live read")
	}
}
func TestI7C2BLibraryBackfillAndSpecialDecimals(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	catalog, e := (contentstore.Store{}).LibraryCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	rule := catalog.SpecialCollections[1]
	for i, id := range rule.RequiredSourceIDs {
		skillHero(t, p, a, rev, id, int64(i+1))
	}
	timed := libraryService(p, p).Timed
	if e = app.RunBackfill(ctx, timed, characterstore.Store{}, librarystore.Store{}, op()); e != nil {
		t.Fatal(e)
	}
	s := libraryService(p, p)
	r, e := s.Command(ctx, a, app.Command{Family: app.SpecialClaim, Value: 2}, op())
	if e != nil || !r.Changed {
		t.Fatal(r, e)
	}
	r, e = s.Command(ctx, a, app.Command{Family: app.SpecialClaim, Value: 2}, op())
	if e != nil || r.Changed {
		t.Fatal("special noop", r, e)
	}
	obs, e := s.PlayerCollectionInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()})
	if e != nil || obs.Contributions[rule.Contribution.AttrID] != 10 {
		t.Fatal(".1 exact hundredths", obs, e)
	}
	if _, e = s.Command(ctx, a, app.Command{Family: app.SpecialClaim, Value: 1}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("incomplete set", e)
	}
	b, _ := registry.LoadBuiltinBundle()
	if b.RevisionID() != rev {
		t.Fatal("captured revision")
	}
}

func TestI7C2BLibraryCostRollbackCapsAndBootstrap(t *testing.T) {
	p := pool(t)
	a, rev := libraryFixture(t, p, true)
	s := libraryService(p, p)
	s.Receipts = skillFailReceipts{}
	if _, e := s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, op()); e == nil {
		t.Fatal("receipt failure must abort")
	}
	if libraryFacts(t, p, a).Pending != nil || libraryAmount(t, p, a, "mana") != 5000000 {
		t.Fatal("atomic cost rollback")
	}
	// Reopen resolves the retained same operation, then applies current state.
	s = libraryService(p, p)
	if _, e := s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := s.Command(ctx, a, app.Command{Family: app.Save, PartnerID: 1}, op()); e != nil {
		t.Fatal(e)
	}
	cat, e := (contentstore.Store{}).LibraryCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	ls := librarystore.Store{}
	f, e := ls.LockHeroTx(ctx, tr, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil {
		t.Fatal(e)
	}
	old := f.StateVersion
	for i, axis := range cat.Feeding.Axes {
		f.Applied[i] = axis.Cap
	}
	f.Pending = nil
	f.StateVersion++
	f.UpdatedAt = time.Now().UTC()
	if e = ls.SaveHeroTx(ctx, tr, f, old); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	amount := libraryAmount(t, p, a, "mana")
	if _, e = s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("cap rejects", e)
	}
	if libraryAmount(t, p, a, "mana") != amount {
		t.Fatal("cap charge")
	}
	at := time.Now().UTC()
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	detail := map[string]any{"836": map[string]any{"library_talk_infos": map[string]any{}, "unselected": "preserved"}}
	if e = (characterstore.HeroBootstrapProjection{Content: contentstore.Store{}, Library: s}).OverlayMID1(ctx, tr, a, false, at, detail); e != nil {
		t.Fatal(e)
	}
	if e = (librarystore.BootstrapProjection{Service: s}).OverlayMID1(ctx, tr, a, false, at, detail); e != nil {
		t.Fatal(e)
	}
	body := detail["836"].(map[string]any)
	if body["unselected"] != "preserved" || body["library_infos"].(map[string]any)["1"].(map[string]any)["favor_degree"] != int64(2000) {
		t.Fatal(detail)
	}
}
func TestI7C2BLibraryFreshMaterializerAtomicFacet(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	exec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,1,0,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (librarystore.Store{}).EnsurePlayerRootTx(ctx, tr, a.PlayerID, time.Now().Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	m := hero.HeroMaterializer{Store: characterstore.Store{}, Content: contentstore.Store{}, Capacity: skillTestCapacity{}, FreshFacets: librarystore.Store{}}
	batch := i5.PartnerEntityBatch{PlayerID: a.PlayerID, ContentRevision: rev, Lines: []i5.PartnerEntityLine{{Identity: i5.PartnerEntityLineIdentity{GrantSemanticKey: "i7c2b", LineOrdinal: 0}, ItemID: 40001001, Amount: 1}}}
	for _, commit := range []bool{false, true} {
		tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		pf, e := m.PreflightPartnerEntityBatchTx(ctx, tr, batch)
		if e != nil {
			t.Fatal(e)
		}
		for _, k := range pf.Locks {
			if e = m.LockPartnerEntityKeyTx(ctx, tr, k); e != nil {
				t.Fatal(e)
			}
		}
		if _, e = m.MaterializePartnerEntityBatchTx(ctx, tr, batch, pf, op()); e != nil {
			t.Fatal(e)
		}
		if commit {
			e = tr.Commit(ctx)
		} else {
			e = tr.Rollback(ctx)
		}
		if e != nil {
			t.Fatal(e)
		}
		_, e = (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
		if !commit && e == nil {
			t.Fatal("facet survived rollback")
		}
		if commit && e != nil {
			t.Fatal(e)
		}
	}
	if h := skillRead(t, p, a, 1); h.RawSkills != character.NewHeroRawSkillSeed() {
		t.Fatal("inherited skill seed", h)
	}
}
func TestI7C2BLibraryRetiredPendingAndReconnectFence(t *testing.T) {
	p := pool(t)
	a, _ := libraryFixture(t, p, true)
	c := app.Command{Family: app.Feed, PartnerID: 1, Value: 1}
	o := op()
	s := libraryService(p, &libraryFaultDB{Beginner: p, commit: false})
	if _, e := s.Command(ctx, a, c, o); e == nil {
		t.Fatal("unknown abort")
	}
	// Current context moves on; fresh authenticated caller resolves the retained
	// dead actor as definitely rejected before a future fresh semantic admission.
	exec(t, p, `UPDATE gameplay_contexts SET liveness_version=liveness_version+1 WHERE context_id=$1::uuid`, a.ContextID.UUID().String())
	fresh := a
	fresh.ContextLivenessVersion++
	s = libraryService(p, p)
	if _, e := s.Command(ctx, fresh, c, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("retained dead context rejected", e)
	}
	if libraryAmount(t, p, a, "mana") != 5000000 {
		t.Fatal("dead actor charge")
	}
	if _, e := s.Command(ctx, fresh, c, op()); e != nil {
		t.Fatal("fresh after resolved rejection", e)
	}
	exec(t, p, `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	if _, e := s.Command(ctx, fresh, app.Command{Family: app.Save, PartnerID: 1}, op()); e == nil {
		t.Fatal("retired save")
	}
	if libraryFacts(t, p, a).Pending == nil {
		t.Fatal("history incorrectly discarded")
	}
}

func TestI7C2BLibraryConcurrentMarriageAndRetirement(t *testing.T) {
	p := pool(t)
	a, _ := libraryFixture(t, p, true)
	exec(t, p, `UPDATE player_library_heroes SET is_married=false WHERE player_id=$1`, int64(a.PlayerID))
	s := libraryService(p, p)
	var wg sync.WaitGroup
	errs := make(chan error, 4)
	for i := 0; i < 4; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.Command(ctx, a, app.Command{Family: app.Gift, PartnerID: 1, Value: 50001112}, op())
			if e != nil && !errors.Is(e, app.ErrRejected) {
				errs <- e
			}
		}()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		t.Fatal(e)
	}
	var qty int64
	if e := p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001112`, int64(a.PlayerID)).Scan(&qty); e != nil || qty != 99 || !libraryFacts(t, p, a).Married {
		t.Fatal("one ring debit", qty, e)
	}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = (characterstore.Store{}).LockRootTx(ctx, tr, a.PlayerID); e != nil {
		t.Fatal(e)
	}
	// Retire while a competing stock roll waits on the canonical population lock.
	done := make(chan error, 1)
	go func() {
		_, e := s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, op())
		done <- e
	}()
	time.Sleep(50 * time.Millisecond)
	if _, e = tr.Exec(ctx, `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	if _, e = tr.Exec(ctx, `UPDATE player_hero_roots SET state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1`, int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if e = <-done; e == nil {
		t.Fatal("retired competing roll succeeded")
	}
	if libraryAmount(t, p, a, "mana") != 5000000 || libraryFacts(t, p, a).Pending != nil {
		t.Fatal("retired roll charged")
	}
}

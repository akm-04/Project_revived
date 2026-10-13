//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/characterasset"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	gen "gxb.local/backend/v2/internal/application/generation"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	proj "gxb.local/backend/v2/internal/projection/hero"
	"sync"
	"testing"
	"time"
)

type skillTestCapacity struct{}

// Existing unresolved production capacity is not qualified by this explicit
// test-only authorizer. Test the implemented acquisition seam, not policy truth.
func (skillTestCapacity) AuthorizeHeroAddition(identity.PlayerID, int, int) error { return nil }
func skillService(p *pg.Pool, db tx.Beginner) hero.SkillChoiceService {
	return hero.SkillChoiceService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Store: characterstore.Store{}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}, Inventory: i5store.Store{}, Content: contentstore.Store{Queryer: p}}
}
func skillHero(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, table int64, partner int64) character.Hero {
	t.Helper()
	exec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,10,0,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id) DO NOTHING`, int64(a.PlayerID))
	at := time.Now().UTC().Add(-time.Hour)
	h := character.Hero{PlayerID: a.PlayerID, PartnerID: partner, TableID: table, OriginTableID: table, Star: 5, Level: 1, Color: 1, CreationContentRevision: rev, RawSkills: character.NewHeroRawSkillSeed(), IllusionSkinID: character.DefaultIllusionSkinID, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = (characterstore.Store{}).InsertHeroTx(ctx, tr, h); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return h
}
func skillBook(t *testing.T, p *pg.Pool, a identity.ActorContext, item int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=1,updated_at=clock_timestamp()-interval '1 hour'`, int64(a.PlayerID), item)
}
func skillRead(t *testing.T, p *pg.Pool, a identity.ActorContext, id int64) character.Hero {
	t.Helper()
	h, e := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, a.PlayerID, id)
	if e != nil {
		t.Fatal(e)
	}
	return h
}
func TestI7C2ARawChoiceReceiptReloadAndBoundaries(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	h := skillHero(t, p, a, rev, 11001144, 1)
	skillBook(t, p, a, 50000005)
	skillBook(t, p, a, 50000010)
	s := skillService(p, p)
	o := op()
	first, e := s.ChangeSkill(ctx, a, 1, 5, 50000005, o)
	if e != nil || !first.Changed || first.StateVersion != 2 || first.SkillIDs[4] != 60010144 {
		t.Fatal(first, e)
	}
	same, e := s.ChangeSkill(ctx, a, 1, 5, 50000005, op())
	if e != nil || same.Changed || same.StateVersion != 2 {
		t.Fatal(same, e)
	}
	if _, e = s.ChangeSkill(ctx, a, 1, 5, 50000010, op()); e != nil {
		t.Fatal(e)
	}
	replay, e := s.ChangeSkill(ctx, a, 1, 5, 50000005, o)
	if e != nil || replay.StateVersion != first.StateVersion || replay.SkillIDs[4] != 60010144 {
		t.Fatal("historical replay", replay, e)
	}
	if _, e = s.ChangeSkill(ctx, a, 1, 5, 50000010, o); e == nil {
		t.Fatal("same key different request accepted")
	}
	for _, req := range [][3]int64{{1, 4, 50000005}, {1, 5, 50000015}, {1, 5, 50000000}, {2, 5, 50000005}} {
		if _, e = s.ChangeSkill(ctx, a, req[0], req[1], req[2], op()); e == nil {
			t.Fatal("bad request", req)
		}
	}
	other := actor(t, p)
	if _, e = s.ChangeSkill(ctx, other, 1, 5, 50000005, op()); e == nil {
		t.Fatal("foreign Hero accepted")
	}
	skillHero(t, p, a, rev, 10001144, 2)
	skillHero(t, p, a, rev, 11001001, 3)
	for _, id := range []int64{2, 3} {
		if _, e = s.ChangeSkill(ctx, a, id, 5, 50000005, op()); e == nil {
			t.Fatal("base/nonKongMing accepted", id)
		}
	}
	latest := skillRead(t, p, a, 1)
	if latest.StateVersion != 3 || latest.RawSkills.ChoiceIDs[4] != 60020144 || latest.RawSkills.Levels != h.RawSkills.Levels || latest.Level != h.Level || latest.IsLike != h.IsLike {
		t.Fatal("owner preservation", latest)
	}
	var qty int64
	if e = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50000005`, int64(a.PlayerID)).Scan(&qty); e != nil || qty != 1 {
		t.Fatal("book consumed", qty, e)
	}
	latest.Kind = character.NormalHero
	wire, e := proj.StockHero(latest)
	if e != nil || wire["skill_ids"].([]any)[4] != int64(60020144) {
		t.Fatal("MID49 projection", wire, e)
	}
	detail := map[string]any{}
	if e = (characterstore.HeroBootstrapProjection{Content: contentstore.Store{}}).OverlayMID1(ctx, p, a, false, time.Now().UTC(), detail); e != nil {
		t.Fatal("MID1", e)
	}
	if _, ok := detail["49"]; !ok {
		t.Fatal("MID1 canonical roster missing")
	}
	hs := characterstore.Store{Queryer: p}
	list, e := hs.ListHeroes(ctx, a.PlayerID)
	if e != nil || len(list) != 3 || list[0].RawSkills != latest.RawSkills {
		t.Fatal("reload", list, e)
	}
	// Fresh coherent read uses the same DB snapshot, owner version and revision.
	_, e = (tx.Runner{DB: p}).Run(ctx, op(), tx.Profile{Name: "skill-read", AcquireTimeout: time.Second, LockTimeout: time.Second, StatementTimeout: time.Second * 3, TransactionTimeout: time.Second * 5, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: time.Second * 10}, tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := characterasset.NewCoherentReadScope(sc, rev, time.Now().UTC())
		if e != nil {
			return e
		}
		v, e := (hero.RawSkillObservationReader{Store: hs, Content: contentstore.Store{}}).HeroRawSkillsTx(c, scope, latest.Ref())
		if e != nil {
			return e
		}
		if v.StateVersion != latest.StateVersion || v.ResolvedIDs[4] != 60020144 || v.Facts != latest.RawSkills || v.ContentRevision != rev {
			t.Fatal(v)
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
}
func TestI7C2AChoiceAtomicFailureUnknownCommitAndConcurrency(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	for _, mode := range []string{"commit", "rollback"} {
		a := actor(t, p)
		skillHero(t, p, a, rev, 11001144, 1)
		skillBook(t, p, a, 50000005)
		s := skillService(p, skillFaultDB{Beginner: p, commit: mode == "commit"})
		r, e := s.ChangeSkill(ctx, a, 1, 5, 50000005, op())
		h := skillRead(t, p, a, 1)
		if mode == "commit" {
			if e != nil || r.StateVersion != 2 || h.StateVersion != 2 {
				t.Fatal("positive unknown proof", r, e, h)
			}
		} else {
			var unknown *tx.UnknownCommitError
			if !errors.As(e, &unknown) || h.StateVersion != 1 || h.RawSkills.ChoiceIDs[4] != 0 {
				t.Fatal("unknown absent remains unresolved / rollback", e, h)
			}
		}
	}
	a := actor(t, p)
	skillHero(t, p, a, rev, 11001144, 1)
	skillBook(t, p, a, 50000005)
	s := skillService(p, p)
	o := op()
	var wg sync.WaitGroup
	errs := make(chan error, 8)
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			r, e := s.ChangeSkill(ctx, a, 1, 5, 50000005, o)
			if e == nil && r.StateVersion != 2 {
				e = errors.New("duplicate owner version")
			}
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
	if h := skillRead(t, p, a, 1); h.StateVersion != 2 {
		t.Fatal(h)
	}
	// Roll back a definitely aborted receipt insertion after the owner update.
	a = actor(t, p)
	skillHero(t, p, a, rev, 11001144, 1)
	skillBook(t, p, a, 50000005)
	s = skillService(p, p)
	s.Receipts = skillFailReceipts{}
	if _, e := s.ChangeSkill(ctx, a, 1, 5, 50000005, op()); e == nil {
		t.Fatal("receipt failure accepted")
	}
	if h := skillRead(t, p, a, 1); h.StateVersion != 1 || h.RawSkills.ChoiceIDs[4] != 0 {
		t.Fatal("partial mutation", h)
	}
}

type skillFailReceipts struct{ kernelstore.Store }

func (skillFailReceipts) PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error) {
	return receipt.PutResult{}, errors.New("injected receipt failure")
}
func TestI7C2AMaterializerSeedsCanonicalFactsAndRollback(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	exec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,1,0,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	m := hero.HeroMaterializer{Store: characterstore.Store{}, Content: contentstore.Store{}, Capacity: skillTestCapacity{}}
	batch := i5.PartnerEntityBatch{PlayerID: a.PlayerID, ContentRevision: rev, Lines: []i5.PartnerEntityLine{{Identity: i5.PartnerEntityLineIdentity{GrantSemanticKey: "i7c2a", LineOrdinal: 0}, ItemID: 40001001, Amount: 1}}}
	for _, commit := range []bool{false, true} {
		tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
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
	}
	h := skillRead(t, p, a, 1)
	if h.RawSkills != character.NewHeroRawSkillSeed() {
		t.Fatal(h)
	}
	var next int64
	if e := p.QueryRow(ctx, `SELECT next_partner_id FROM player_hero_roots WHERE player_id=$1`, int64(a.PlayerID)).Scan(&next); e != nil || next != 2 {
		t.Fatal("allocator rollback", next, e)
	}
}

type skillFaultDB struct {
	tx.Beginner
	commit bool
}

func (d skillFaultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	tr, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return faultTx{Tx: tr, commit: d.commit}, nil
}

type skillBlockedInventory struct {
	i5store.Store
	reached chan struct{}
	once    *sync.Once
}

func (s skillBlockedInventory) LockStackTx(c context.Context, tr tx.Tx, pid identity.PlayerID, item int64, at time.Time) (economy.StackState, bool, error) {
	s.once.Do(func() { close(s.reached) })
	return s.Store.LockStackTx(c, tr, pid, item, at)
}
func TestI7C2AConcurrentBookLossRejectsAtomicChoice(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	skillHero(t, p, a, rev, 11001144, 1)
	skillBook(t, p, a, 50000005)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, _, e = (i5store.Store{}).LockStackTx(ctx, tr, a.PlayerID, 50000005, time.Now().UTC()); e != nil {
		t.Fatal(e)
	}
	reached := make(chan struct{})
	s := skillService(p, p)
	s.Inventory = skillBlockedInventory{reached: reached, once: &sync.Once{}}
	done := make(chan error, 1)
	go func() { _, e := s.ChangeSkill(ctx, a, 1, 5, 50000005, op()); done <- e }()
	select {
	case <-reached:
	case <-time.After(time.Second * 3):
		t.Fatal("choice did not reach resource lock")
	}
	if _, e = tr.Exec(ctx, `UPDATE player_item_stacks SET quantity=0,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1 AND item_id=50000005`, int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if e = <-done; e == nil {
		t.Fatal("concurrently lost book accepted")
	}
	if h := skillRead(t, p, a, 1); h.StateVersion != 1 || h.RawSkills.ChoiceIDs[4] != 0 {
		t.Fatal("partial Hero", h)
	}
}

func TestI7C2AFragmentAndVowsActualAcquisitionSeeds(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	store := characterstore.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	econ := i5store.Store{Queryer: p}
	exec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,1,0,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'mana',100000000,1,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(a.PlayerID))
	s := hero.Service{Runner: tx.Runner{DB: p}, Store: store, Fencer: econ, Content: content, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, AcquisitionStore: store, Acquisition: content, Progression: content, MaterialCosts: i5.MaterialCostDebiter{Store: econ, Content: content}, PlayerLevel: i5.CrossOwner{Store: econ}, Capacity: skillTestCapacity{}}
	policy, e := content.HeroNormalSummonTx(ctx, p, rev, 10001001)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(a.PlayerID), policy.Template.FragmentItemID, policy.FragmentCount)
	original := op()
	h, e := s.SummonNormal(ctx, a, 10001001, policy.Template.FragmentItemID, policy.FragmentCount, original)
	if e != nil || h.RawSkills != character.NewHeroRawSkillSeed() {
		t.Fatal(h, e)
	}
	replay, e := s.SummonNormal(ctx, a, 10001001, policy.Template.FragmentItemID, policy.FragmentCount, original)
	if e != nil || replay.RawSkills != h.RawSkills || replay.PartnerID != h.PartnerID {
		t.Fatal(replay, e)
	}
	b := actor(t, p)
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(b.PlayerID))
	pre, e := content.HeroSuperPrerequisitesTx(ctx, p, rev, 11001)
	if e != nil {
		t.Fatal(e)
	}
	for i, id := range pre {
		skillHero(t, p, b, rev, id, int64(i+1))
	}
	v, e := s.CreateVows(ctx, b, 11001, op())
	if e != nil || v.Kind != character.SuperHero || v.RawSkills != character.NewHeroRawSkillSeed() {
		t.Fatal("vows", v, e)
	}
}

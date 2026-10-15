//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	asset "gxb.local/backend/v2/internal/application/characterasset"
	app "gxb.local/backend/v2/internal/application/elementequipment"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	elem "gxb.local/backend/v2/internal/domain/elementequipment"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

func elementService(p *pg.Pool, db tx.Beginner) app.Service {
	cs := contentstore.Store{Queryer: p}
	v := i5store.Store{Queryer: p}
	run := tx.Runner{DB: db}
	iv := i5.Service{Runner: run, Store: v, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: v, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("element-native-fixture-secret-000")}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: run}, Reads: tx.Runner{DB: p}, Heroes: characterstore.ElementHeroPort{Store: characterstore.Store{Queryer: p}}, Owner: elementstore.Store{}, Content: cs, Players: i4store.PlayerRootLocker{}, Fence: v, Values: v, Costs: i5.MaterialCostDebiter{Store: v, Content: cs}, Grants: iv, Exchange: iv, Receipts: kernelstore.Store{}}
}

// Existing Character/I5 producers are inherited qualified subjects. These are
// explicit endgame Character preconditions, not a fake Element provider or eligibility flag.
func elementFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, app.Service) {
	t.Helper()
	a, rev, old := courseFixture(t, p)
	cs := contentstore.Store{}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	at := time.Now().Add(-time.Hour)
	owner := elementstore.Store{}
	if e = owner.EnsureRootTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	for id := int64(1); id <= 3; id++ {
		h, e := (characterstore.Store{}).LockHeroByPartnerIDTx(ctx, tr, a.PlayerID, id)
		if e != nil {
			t.Fatal(e)
		}
		before := h.StateVersion
		h.Color = 16
		for slot := int64(1); slot <= 6; slot++ {
			pos, e := cs.HeroEquipmentPositionTx(ctx, tr, rev, h.TableID, h.Color, slot)
			if e != nil {
				t.Fatal(e)
			}
			if pos.OrdinaryEligible {
				h.Equipment[slot-1] = 1
			}
		}
		h.StateVersion++
		h.UpdatedAt = at
		if e = (characterstore.Store{}).SaveHeroStateTx(ctx, tr, h, before); e != nil {
			t.Fatal(e)
		}
		if e = owner.EnsureHeroTx(ctx, tr, a.PlayerID, id, at); e != nil {
			t.Fatal(e)
		}
	}
	rule, e := cs.ResolveProgressionPolicyTx(ctx, tr, rev)
	if e != nil {
		t.Fatal(e)
	}
	pr, e := (i5store.Store{}).LockProgressionTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	before := pr.StateVersion
	pr.Level = rule.MaxLevel()
	pr.StateVersion++
	pr.UpdatedAt = at
	if e = (i5store.Store{}).SaveProgressionTx(ctx, tr, pr, before); e != nil {
		t.Fatal(e)
	}
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	ls := []grant.Line{}
	for _, id := range []int64{20001407, 20001408, 20001413, 20001414, 20001453, 50001885, 50001886} {
		amount := int64(100)
		if id == 50001885 {
			amount = 50
		}
		ls = append(ls, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: amount})
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2g-fixture", Operation: "actual-I5-acquisition", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: "endgame-fixture"}, Lines: ls}
	if _, e = old.Grants.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return a, rev, elementService(p, p)
}
func elementCmd(t *testing.T, s app.Service, a identity.ActorContext, c app.Command) app.Result {
	t.Helper()
	r, e := s.Command(ctx, a, c, op())
	if e != nil {
		t.Fatal(c, e)
	}
	return r
}
func elementFacet(t *testing.T, p *pg.Pool, a identity.ActorContext, id int64) elem.HeroRoot {
	t.Helper()
	r, e := (elementstore.Store{}).ReadHeroTx(ctx, p, a.PlayerID, id)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func TestI7C2GFiveCommandsBindingBackupAndSourceEffects(t *testing.T) {
	p := pool(t)
	a, rev, s := elementFixture(t, p)
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2})
	if n := dormStack(t, p, a, 20001413); n != 99 {
		t.Fatal(n)
	}
	elementCmd(t, s, a, app.Command{Family: app.Enhance, PartnerID: 1, EquipID: 7})
	if dormStack(t, p, a, 50001886) != 99 {
		t.Fatal("level0 normal cost")
	}
	elementCmd(t, s, a, app.Command{Family: app.Unload, PartnerID: 1, Position: 2})
	if elementFacet(t, p, a, 1).Facts.Backup[7] != 1 || dormStack(t, p, a, 20001413) != 99 {
		t.Fatal("unload refunded or lost level")
	}
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 3})
	if dormStack(t, p, a, 20001413) != 99 {
		t.Fatal("bound reactivation debited again")
	}
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 8, Position: 3})
	elementCmd(t, s, a, app.Command{Family: app.Enhance, PartnerID: 1, EquipID: 7})
	f := elementFacet(t, p, a, 1)
	if f.Facts.Backup[7] != 2 || f.Facts.Slots[2] != 8 {
		t.Fatal(f)
	}
	v, e := s.HeroElementInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 1)
	if e != nil || len(v.Contributions) != 1 {
		t.Fatal(v.Contributions, e)
	}
	if _, ok := v.Contributions[5]; ok {
		t.Fatal("backup stat leaked")
	}
	elementCmd(t, s, a, app.Command{Family: app.DestroyBound, PartnerID: 1, EquipID: 7})
	if _, ok := elementFacet(t, p, a, 1).Facts.Backup[7]; ok {
		t.Fatal("bound destroy retained source")
	}
	before := dormStack(t, p, a, 50001886)
	o := op()
	c := app.Command{Family: app.DestroyBackpack, EquipID: 1}
	if _, e = s.Command(ctx, a, c, o); e != nil {
		t.Fatal(e)
	}
	if _, e = s.Command(ctx, a, c, o); e != nil {
		t.Fatal(e)
	}
	if dormStack(t, p, a, 20001407) != 99 || dormStack(t, p, a, 50001886) != before+6 {
		t.Fatal("destroy/replay not once")
	}
	if _, e = s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 39, Position: 1}, op()); e == nil {
		t.Fatal("exclusive wrong Hero admitted")
	}
}
func TestI7C2GEligibilityRecoveryCapRollbackAndReference(t *testing.T) {
	p := pool(t)
	a, rev, s := elementFixture(t, p)
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2})
	for i := 0; i < 10; i++ {
		elementCmd(t, s, a, app.Command{Family: app.Enhance, PartnerID: 1, EquipID: 7})
	}
	before := dormStack(t, p, a, 50001886)
	root := elementFacet(t, p, a, 1)
	if _, e := s.Command(ctx, a, app.Command{Family: app.Enhance, PartnerID: 1, EquipID: 7}, op()); e == nil {
		t.Fatal("cap accepted")
	}
	if dormStack(t, p, a, 50001886) != before || elementFacet(t, p, a, 1).Version != root.Version {
		t.Fatal("cap partially charged")
	}
	exec(t, p, `UPDATE player_progression SET level=1 WHERE player_id=$1`, int64(a.PlayerID))
	if _, e := s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 8, Position: 3}, op()); e == nil {
		t.Fatal("ineligible new bind")
	}
	elementCmd(t, s, a, app.Command{Family: app.Unload, PartnerID: 1, Position: 2})
	guard := elementstore.Store{}
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	plan, e := guard.PreflightHeroRemovalTx(ctx, p, ref)
	if e != nil {
		t.Fatal(e)
	}
	tr, _ := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e = guard.LockReferenceGuardKeyTx(ctx, tr, plan.Locks[0]); e != nil {
		t.Fatal(e)
	}
	if e = guard.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); !errors.Is(e, asset.ErrReferenceInUse) {
		t.Fatal("backup retirement allowed", e)
	}
	tr.Rollback(ctx)
	elementCmd(t, s, a, app.Command{Family: app.DestroyBound, PartnerID: 1, EquipID: 7})
	tr, _ = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	defer tr.Rollback(ctx)
	if e = guard.LockReferenceGuardKeyTx(ctx, tr, plan.Locks[0]); e != nil {
		t.Fatal(e)
	}
	if e = guard.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); e != nil {
		t.Fatal(e)
	}
	_ = rev
}
func TestI7C2GUnknownConcurrencyAndCurrentReload(t *testing.T) {
	p := pool(t)
	for _, commit := range []bool{true, false} {
		a, _, _ := elementFixture(t, p)
		s := elementService(p, &libraryFaultDB{Beginner: p, commit: commit})
		o := op()
		c := app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2}
		_, e := s.Command(ctx, a, c, o)
		if commit && e != nil {
			t.Fatal(e)
		}
		if !commit && e == nil {
			t.Fatal("unknown false success")
		}
		s = elementService(p, p)
		r, e := s.Command(ctx, a, c, o)
		if e != nil || r.OperationID != o.ID {
			t.Fatal("retained intent lost", e)
		}
		if dormStack(t, p, a, 20001413) != 99 {
			t.Fatal("double debit")
		}
	}
	a, _, s := elementFixture(t, p)
	o := op()
	var wg sync.WaitGroup
	errs := make(chan error, 6)
	for i := 0; i < 6; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2}, o)
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
	if dormStack(t, p, a, 20001413) != 99 {
		t.Fatal("concurrent double debit")
	}
	elementCmd(t, s, a, app.Command{Family: app.Unload, PartnerID: 1, Position: 2})
	r, e := s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2}, o)
	if e != nil {
		t.Fatal(e)
	}
	body, e := s.Response(ctx, a, r, op())
	if e != nil || body["element_equips"] != "0|0|0|0" || body["element_bak_equips"] != "7" {
		t.Fatal("historical receipt overwrote newer state", body, e)
	}
}
func TestI7C2GCoherentReadAndMissingOwnerIsNotAbsence(t *testing.T) {
	p := pool(t)
	a, rev, s := elementFixture(t, p)
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2})
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	_, e := (tx.Runner{DB: p}).Run(ctx, o, app.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := asset.NewCoherentReadScope(sc, rev, time.Now())
		if e != nil {
			return e
		}
		before, e := s.CoherentHeroInputsTx(c, scope, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
		if e != nil {
			return e
		}
		elementCmd(t, s, a, app.Command{Family: app.Unload, PartnerID: 1, Position: 2})
		after, e := s.CoherentHeroInputsTx(c, scope, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
		if e != nil {
			return e
		}
		if before.Facet.Version != after.Facet.Version || after.Facet.Facts.Slots[1] != 7 {
			t.Fatal("mixed owner snapshot")
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	_, e = (tx.Runner{DB: p}).Run(ctx, op(), app.Profile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		_, e := asset.NewCoherentReadScope(sc, rev, time.Now())
		return e
	})
	if !errors.Is(e, asset.ErrInsufficientReadIsolation) {
		t.Fatal(e)
	}
	exec(t, p, `DELETE FROM player_element_heroes WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
	if _, e = s.HeroElementInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 2); e == nil {
		t.Fatal("missing owner accepted as zero")
	}
}

func eligibleElementHero(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, table, id int64, super bool) {
	t.Helper()
	skillHero(t, p, a, rev, table, id)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	h, e := (characterstore.Store{}).LockHeroByPartnerIDTx(ctx, tr, a.PlayerID, id)
	if e != nil {
		t.Fatal(e)
	}
	v := h.StateVersion
	h.Color = 16
	for slot := int64(1); slot <= 6; slot++ {
		if super {
			h.Equipment[slot-1] = 21
		} else {
			pos, e := (contentstore.Store{}).HeroEquipmentPositionTx(ctx, tr, rev, h.TableID, h.Color, slot)
			if e != nil {
				t.Fatal(e)
			}
			if pos.OrdinaryEligible {
				h.Equipment[slot-1] = 1
			}
		}
	}
	h.StateVersion++
	if e = (characterstore.Store{}).SaveHeroStateTx(ctx, tr, h, v); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}
func TestI7C2GSuperAndExclusiveGenuineOwnedInputs(t *testing.T) {
	p := pool(t)
	a, rev, s := elementFixture(t, p)
	eligibleElementHero(t, p, a, rev, 11001, 5, true)
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 5, EquipID: 1, Position: 1})
	elementCmd(t, s, a, app.Command{Family: app.Enhance, PartnerID: 5, EquipID: 1})
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 5, EquipID: 7, Position: 2})
	v, e := s.HeroElementInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 5)
	if e != nil || v.Hero.Kind != character.SuperHero || v.Contributions[5].Value != "648/5" {
		t.Fatal("Super real nondefault", v.Contributions, e)
	}
	exec(t, p, `UPDATE player_heroes SET equip_1=20 WHERE player_id=$1 AND partner_id=5`, int64(a.PlayerID))
	before := dormStack(t, p, a, 20001414)
	if _, e = s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 5, EquipID: 8, Position: 3}, op()); e == nil {
		t.Fatal("Super enhancement19 admitted")
	}
	if dormStack(t, p, a, 20001414) != before {
		t.Fatal("bad eligibility charged")
	}
	elementCmd(t, s, a, app.Command{Family: app.Unload, PartnerID: 5, Position: 1})
	elementCmd(t, s, a, app.Command{Family: app.DestroyBound, PartnerID: 5, EquipID: 1})
	eligibleElementHero(t, p, a, rev, 10001144, 4, false)
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 4, EquipID: 39, Position: 1})
	elementCmd(t, s, a, app.Command{Family: app.Enhance, PartnerID: 4, EquipID: 39})
	tr, _ := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2g-test", Operation: "real-book-acquisition", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: "test-input"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50000001, Amount: 1}, {Kind: grant.StackItem, ItemID: 50000002, Amount: 1}}}
	if _, e = s.Grants.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	v, e = s.HeroElementInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 4)
	if e != nil || v.ExclusiveBookCount != 2 || v.Contributions[2].Value != "256/5" {
		t.Fatal("exclusive actual I5 book state", v.ExclusiveBookCount, v.Contributions, e)
	}
}
func TestI7C2GOverflowBackfillNoOverwriteAndStaleTime(t *testing.T) {
	p := pool(t)
	a, rev, s := elementFixture(t, p)
	elementCmd(t, s, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2})
	old := elementFacet(t, p, a, 1)
	if e := app.RunBackfill(ctx, s.Timed, characterstore.Store{}, elementstore.Store{}, rev, op()); e != nil {
		t.Fatal(e)
	}
	if elementFacet(t, p, a, 1).Version != old.Version {
		t.Fatal("backfill overwrote binding")
	}
	exec(t, p, `UPDATE player_item_stacks SET quantity=999 WHERE player_id=$1 AND item_id=50001886`, int64(a.PlayerID))
	o := op()
	c := app.Command{Family: app.DestroyBackpack, EquipID: 7}
	if _, e := s.Command(ctx, a, c, o); e != nil {
		t.Fatal(e)
	}
	if dormStack(t, p, a, 50001886) != 999 || dormStack(t, p, a, 20001413) != 98 {
		t.Fatal("overflow values")
	}
	var before, after int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID)).Scan(&before); e != nil || before < 1 {
		t.Fatal("missing overflow Mail", before, e)
	}
	if _, e := s.Command(ctx, a, c, o); e != nil {
		t.Fatal(e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID)).Scan(&after); e != nil || after != before {
		t.Fatal("duplicate overflow Mail", before, after, e)
	}
	bad := c
	bad.EquipID = 8
	if _, e := s.Command(ctx, a, bad, o); !errors.Is(e, app.ErrProof) {
		t.Fatal("semantic UUID used with different fingerprint", e)
	}
	exec(t, p, `UPDATE player_element_heroes SET updated_at=clock_timestamp()+interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	if _, e := s.HeroElementInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, 1); !errors.Is(e, app.ErrStale) {
		t.Fatal("stale observed instant", e)
	}
}

type elementAdmissionHookDB struct {
	tx.Beginner
	once *sync.Once
	hook func()
}
type elementAdmissionHookTx struct {
	tx.Tx
	once *sync.Once
	hook func()
}

func (d elementAdmissionHookDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	if o.Isolation == tx.Serializable {
		return elementAdmissionHookTx{t, d.once, d.hook}, nil
	}
	return t, nil
}
func (t elementAdmissionHookTx) Commit(c context.Context) error {
	e := t.Tx.Commit(c)
	if e == nil {
		t.once.Do(t.hook)
	}
	return e
}
func TestI7C2GAdmissionRechecksChangedEligibilityBeforeSpend(t *testing.T) {
	p := pool(t)
	a, _, _ := elementFixture(t, p)
	once := &sync.Once{}
	s := elementService(p, elementAdmissionHookDB{Beginner: p, once: once, hook: func() {
		exec(t, p, `UPDATE player_progression SET level=1,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1`, int64(a.PlayerID))
	}})
	_, e := s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2}, op())
	if !errors.Is(e, app.ErrRejected) {
		t.Fatal("changed eligibility not rejected", e)
	}
	if dormStack(t, p, a, 20001413) != 100 || elementFacet(t, p, a, 1).Facts.Slots[1] != 0 {
		t.Fatal("stale admission spent values")
	}
}

// Conditional future Character removal under the inherited owner lock prefix;
// this qualifies the guard seam and adds no retirement endpoint.
func TestI7C2GAbsentReferencePreflightRacesFirstBinding(t *testing.T) {
	p := pool(t)
	a, _, s := elementFixture(t, p)
	guard := elementstore.Store{}
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	plan, e := guard.PreflightHeroRemovalTx(ctx, p, ref)
	if e != nil || len(plan.Locks) != 1 || plan.Locks[0].DomainRank != elem.RootLockRank {
		t.Fatal("absent preflight omitted owner lock", plan, e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = (characterstore.Store{}).LockRootTx(ctx, tr, a.PlayerID); e != nil {
		t.Fatal(e)
	}
	if _, e = (characterstore.Store{}).LockHeroByPartnerIDTx(ctx, tr, a.PlayerID, 1); e != nil {
		t.Fatal(e)
	}
	if e = guard.LockReferenceGuardKeyTx(ctx, tr, plan.Locks[0]); e != nil {
		t.Fatal(e)
	}
	done := make(chan error, 1)
	go func() {
		_, e := s.Command(ctx, a, app.Command{Family: app.Equip, PartnerID: 1, EquipID: 7, Position: 2}, op())
		done <- e
	}()
	if e = guard.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); e != nil {
		t.Fatal(e)
	}
	if _, e = tr.Exec(ctx, `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), int64(1)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	select {
	case e := <-done:
		if !errors.Is(e, app.ErrRetired) {
			t.Fatal("retired identity rebound", e)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("binding failed to settle after removal")
	}
	if dormStack(t, p, a, 20001413) != 100 || elementFacet(t, p, a, 1).Facts.Slots[1] != 0 {
		t.Fatal("orphan binding or debit")
	}
}

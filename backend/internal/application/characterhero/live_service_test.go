package characterhero

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ca74Content struct {
	ca73Content
	lives map[int64]characterasset.AppearanceLIVEDefinition
	kind  character.HeroKind
}

func (c ca74Content) AppearanceLIVE(_ context.Context, _ string, id int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	v, ok := c.lives[id]
	return v, ok, nil
}
func (c ca74Content) AppearanceLIVETx(_ context.Context, _ tx.Queryer, _ string, id int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	v, ok := c.lives[id]
	return v, ok, nil
}
func (c ca74Content) HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error) {
	if c.kind == "" {
		return character.NormalHero, nil
	}
	return c.kind, nil
}

type ca74Store struct {
	mu    sync.Mutex
	hero  character.Hero
	lives []character.HeroLIVEEntitlement
	saves int
}

func (s *ca74Store) LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.hero, nil
}
func (s *ca74Store) ListHeroLIVEEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroLIVEEntitlement, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]character.HeroLIVEEntitlement(nil), s.lives...), nil
}
func (s *ca74Store) SaveHeroLIVEEntitlementTx(_ context.Context, _ tx.Tx, h character.Hero, ent character.HeroLIVEEntitlement, old int64) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.hero.StateVersion != old || h.StateVersion != old+1 {
		return errors.New("test CA7-4 store: bad version")
	}
	s.hero = h
	s.lives = replaceLIVEEntitlement(s.lives, ent)
	s.saves++
	return nil
}

type ca74Material struct {
	mu      sync.Mutex
	debits  int
	crystal int64
	item    int64
	itemN   int64
	err     error
}

func (m *ca74Material) DebitMaterialCostTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	if len(cost.Scalars) != 1 || len(cost.Stacks) != 1 || cost.Scalars[0].ResourceKey != "crystal" {
		return appi5.MaterialDebitResult{}, errors.New("test CA7-4 material: unexpected cost shape")
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.err != nil {
		return appi5.MaterialDebitResult{}, m.err
	}
	m.debits++
	m.crystal = cost.Scalars[0].Amount
	m.item = cost.Stacks[0].ItemID
	m.itemN = cost.Stacks[0].Amount
	return appi5.MaterialDebitResult{}, nil
}

func (m *ca74Material) snapshot() (int, int64, int64, int64) {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.debits, m.crystal, m.item, m.itemN
}

func ca74ContentFixture() ca74Content {
	base := ca73ContentFixture()
	return ca74Content{ca73Content: base, lives: map[int64]characterasset.AppearanceLIVEDefinition{
		40001074: {ModelID: 40001074, HeroOriginTableID: 1001, CrystalCost: 500, ActivationItemID: 50005171, ActivationItemCount: 2},
		40001109: {ModelID: 40001109, HeroOriginTableID: 1001, CrystalCost: 700, ActivationItemID: 50005171, ActivationItemCount: 1},
		40009999: {ModelID: 40009999, HeroOriginTableID: 9999, CrystalCost: 900, ActivationItemID: 50005171, ActivationItemCount: 1},
	}}
}

func ca74Hero() character.Hero {
	h := ca73Hero(time.Unix(90, 0).UTC())
	h.StateVersion = 1
	return h
}

func ca74Service(h character.Hero, lives []character.HeroLIVEEntitlement) (Service, *ca74Store, *ca74Material, *receipts) {
	st := &ca74Store{hero: h, lives: append([]character.HeroLIVEEntitlement(nil), lives...)}
	mat := &ca74Material{}
	rec := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	content := ca74ContentFixture()
	core := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 12, StateVersion: 1, CreatedAt: time.Unix(90, 0).UTC(), UpdatedAt: time.Unix(90, 0).UTC()}}
	return Service{
		Runner: tx.Runner{DB: fakeDB{}}, Store: core, Fencer: &fence{}, Content: gate(true), Receipts: rec, ReceiptRead: rec,
		MaterialCosts: mat, AppearanceMutationContent: content, LIVEMutationStore: st,
	}, st, mat, rec
}

func liveEnt(model int64, show bool) character.HeroLIVEEntitlement {
	return character.HeroLIVEEntitlement{PlayerID: 7, PartnerID: 11, ModelID: model, IsShow: show}
}

func TestCA74MID68FirstUnlockDebitsOnceInitializesShowAndReplaysSameOperation(t *testing.T) {
	svc, st, mat, _ := ca74Service(ca74Hero(), nil)
	op := testOp(t, "c1010101-0101-4101-8101-010101010101")
	got, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got.Mutated || got.StateVersion != 2 || len(got.LIVE) != 1 || got.LIVE[0] != (LIVEResultState{ModelID: 40001074, IsShow: true}) {
		t.Fatalf("unlock=%+v", got)
	}
	if n, crystal, item, itemN := mat.snapshot(); n != 1 || crystal != 500 || item != 50005171 || itemN != 2 {
		t.Fatalf("debit=%d crystal=%d item=%d count=%d", n, crystal, item, itemN)
	}
	if st.saves != 1 || st.hero.StateVersion != 2 || len(st.lives) != 1 || !st.lives[0].IsShow {
		t.Fatalf("store hero=%+v lives=%+v saves=%d", st.hero, st.lives, st.saves)
	}
	replay, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, op)
	if err != nil || !replay.Replayed || st.saves != 1 {
		t.Fatalf("replay=%+v err=%v saves=%d", replay, err, st.saves)
	}
	if n, _, _, _ := mat.snapshot(); n != 1 {
		t.Fatalf("same-op replay debits=%d", n)
	}
}

func TestCA74MID68FreshOwnedRepeatNoDebitPreservesShowFalseAndSortsProjection(t *testing.T) {
	h := ca74Hero()
	svc, st, mat, _ := ca74Service(h, []character.HeroLIVEEntitlement{liveEnt(40001109, true), liveEnt(40001074, false), liveEnt(40009999, true)})
	got, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, testOp(t, "c2020202-0202-4202-8202-020202020202"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Mutated || got.StateVersion != 1 || st.saves != 0 {
		t.Fatalf("repeat=%+v saves=%d", got, st.saves)
	}
	if n, _, _, _ := mat.snapshot(); n != 0 {
		t.Fatalf("fresh owned repeat debits=%d", n)
	}
	want := []LIVEResultState{{ModelID: 40001074, IsShow: false}, {ModelID: 40001109, IsShow: true}}
	if len(got.LIVE) != len(want) || got.LIVE[0] != want[0] || got.LIVE[1] != want[1] {
		t.Fatalf("projection=%+v want=%+v", got.LIVE, want)
	}
}

func TestCA74MID68InsufficientResourcesAndQualificationFailuresDoNotWrite(t *testing.T) {
	svc, st, mat, _ := ca74Service(ca74Hero(), nil)
	mat.err = economy.ErrInsufficientBalance
	_, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, testOp(t, "c3030303-0303-4303-8303-030303030303"))
	if !errors.Is(err, ErrHeroAppearanceUnavailable) || st.saves != 0 {
		t.Fatalf("insufficient err=%v saves=%d", err, st.saves)
	}
	mat.err = nil
	_, err = svc.UnlockLIVE(context.Background(), testActor(t), 11, 40009999, testOp(t, "c4040404-0404-4404-8404-040404040404"))
	if !errors.Is(err, ErrHeroAppearanceUnavailable) || st.saves != 0 {
		t.Fatalf("wrong-origin err=%v saves=%d", err, st.saves)
	}
	content := ca74ContentFixture()
	content.kind = character.SuperHero
	svc.AppearanceMutationContent = content
	_, err = svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, testOp(t, "c5050505-0505-4505-8505-050505050505"))
	if !errors.Is(err, ErrHeroAppearanceUnavailable) || st.saves != 0 {
		t.Fatalf("SuperHero err=%v saves=%d", err, st.saves)
	}
}

func TestCA74MID69ExplicitAssignmentNoOpReplayAndNoEconomyDependency(t *testing.T) {
	svc, st, mat, _ := ca74Service(ca74Hero(), []character.HeroLIVEEntitlement{liveEnt(40001074, true)})
	svc.MaterialCosts = nil
	op := testOp(t, "c6060606-0606-4606-8606-060606060606")
	got, err := svc.SetLIVEShow(context.Background(), testActor(t), 11, 40001074, false, op)
	if err != nil || !got.Mutated || got.IsShow || got.StateVersion != 2 || st.saves != 1 || st.lives[0].IsShow {
		t.Fatalf("assignment=%+v err=%v store=%+v", got, err, st.lives)
	}
	replay, err := svc.SetLIVEShow(context.Background(), testActor(t), 11, 40001074, false, op)
	if err != nil || !replay.Replayed || st.saves != 1 {
		t.Fatalf("replay=%+v err=%v saves=%d", replay, err, st.saves)
	}
	fresh, err := svc.SetLIVEShow(context.Background(), testActor(t), 11, 40001074, false, testOp(t, "c7070707-0707-4707-8707-070707070707"))
	if err != nil || fresh.Mutated || fresh.StateVersion != 2 || st.saves != 1 {
		t.Fatalf("fresh no-op=%+v err=%v saves=%d", fresh, err, st.saves)
	}
	if n, _, _, _ := mat.snapshot(); n != 0 {
		t.Fatalf("MID69 unexpectedly debited Economy %d", n)
	}
}

func TestCA74MID69RejectsUnownedAndWrongFamily(t *testing.T) {
	svc, st, _, _ := ca74Service(ca74Hero(), nil)
	svc.MaterialCosts = nil
	_, err := svc.SetLIVEShow(context.Background(), testActor(t), 11, 40001074, true, testOp(t, "c8080808-0808-4808-8808-080808080808"))
	if !errors.Is(err, ErrHeroAppearanceUnavailable) || st.saves != 0 {
		t.Fatalf("unowned err=%v saves=%d", err, st.saves)
	}
	content := ca74ContentFixture()
	content.kind = character.SuperHero
	svc.AppearanceMutationContent = content
	svc.LIVEMutationStore = &ca74Store{hero: ca74Hero(), lives: []character.HeroLIVEEntitlement{liveEnt(40001074, true)}}
	_, err = svc.SetLIVEShow(context.Background(), testActor(t), 11, 40001074, false, testOp(t, "c9090909-0909-4909-8909-090909090909"))
	if !errors.Is(err, ErrHeroAppearanceUnavailable) {
		t.Fatalf("SuperHero show err=%v", err)
	}
}

// CA7-4 atomic fixtures stage writes/debits in the shared transaction so
// concurrent operations prove Hero serialization rather than relying on test
// goroutine scheduling.
type ca74AtomicStore struct {
	mu    sync.Mutex
	hero  character.Hero
	lives []character.HeroLIVEEntitlement
	saves int
}

func (s *ca74AtomicStore) LockHeroByPartnerIDTx(_ context.Context, t tx.Tx, _ identity.PlayerID, _ int64) (character.Hero, error) {
	at, ok := t.(*ca45AtomicTx)
	if !ok {
		return character.Hero{}, errors.New("test CA7-4 atomic store: unexpected tx")
	}
	at.lockHero()
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.hero, nil
}
func (s *ca74AtomicStore) ListHeroLIVEEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroLIVEEntitlement, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]character.HeroLIVEEntitlement(nil), s.lives...), nil
}
func (s *ca74AtomicStore) SaveHeroLIVEEntitlementTx(_ context.Context, t tx.Tx, h character.Hero, ent character.HeroLIVEEntitlement, old int64) error {
	at, ok := t.(*ca45AtomicTx)
	if !ok {
		return errors.New("test CA7-4 atomic store: unexpected tx")
	}
	s.mu.Lock()
	if s.hero.StateVersion != old || h.StateVersion != old+1 {
		s.mu.Unlock()
		return errors.New("test CA7-4 atomic store: bad version")
	}
	s.mu.Unlock()
	at.stage(func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		s.hero = h
		s.lives = replaceLIVEEntitlement(s.lives, ent)
		s.saves++
	})
	return nil
}

type ca74AtomicMaterial struct {
	mu     sync.Mutex
	debits int
}

func (m *ca74AtomicMaterial) DebitMaterialCostTx(_ context.Context, t tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	at, ok := t.(*ca45AtomicTx)
	if !ok || len(cost.Scalars) != 1 || len(cost.Stacks) != 1 {
		return appi5.MaterialDebitResult{}, errors.New("test CA7-4 atomic material: unexpected input")
	}
	at.stage(func() { m.mu.Lock(); m.debits++; m.mu.Unlock() })
	return appi5.MaterialDebitResult{}, nil
}
func (m *ca74AtomicMaterial) count() int { m.mu.Lock(); defer m.mu.Unlock(); return m.debits }

func ca74AtomicService(st *ca74AtomicStore, mat *ca74AtomicMaterial, db *ca45AtomicDB) Service {
	rec := newCA45AtomicReceipts()
	content := ca74ContentFixture()
	core := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 12, StateVersion: 1, CreatedAt: time.Unix(90, 0).UTC(), UpdatedAt: time.Unix(90, 0).UTC()}}
	return Service{Runner: tx.Runner{DB: db}, Store: core, Fencer: ca45AtomicFence{}, Content: gate(true), Receipts: rec, ReceiptRead: rec, MaterialCosts: mat, AppearanceMutationContent: content, LIVEMutationStore: st}
}

func TestCA74ConcurrentSameModelUnlockConsumesExactlyOnce(t *testing.T) {
	heroMu := &sync.Mutex{}
	st := &ca74AtomicStore{hero: ca74Hero()}
	mat := &ca74AtomicMaterial{}
	svc := ca74AtomicService(st, mat, &ca45AtomicDB{heroMu: heroMu})
	ops := []operation.Context{testOp(t, "ca0a0a0a-0a0a-4a0a-8a0a-0a0a0a0a0a0a"), testOp(t, "cb0b0b0b-0b0b-4b0b-8b0b-0b0b0b0b0b0b")}
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for _, op := range ops {
		op := op
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, op)
			errs <- err
		}()
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if mat.count() != 1 {
		t.Fatalf("debits=%d", mat.count())
	}
	st.mu.Lock()
	defer st.mu.Unlock()
	if st.saves != 1 || st.hero.StateVersion != 2 || len(st.lives) != 1 || !st.lives[0].IsShow {
		t.Fatalf("hero=%+v lives=%+v saves=%d", st.hero, st.lives, st.saves)
	}
}

func TestCA74UnlockAndShowOrderOnlyProducesValidSerialOutcomes(t *testing.T) {
	heroMu := &sync.Mutex{}
	st := &ca74AtomicStore{hero: ca74Hero()}
	mat := &ca74AtomicMaterial{}
	svc := ca74AtomicService(st, mat, &ca45AtomicDB{heroMu: heroMu})
	var wg sync.WaitGroup
	results := make(chan error, 2)
	wg.Add(2)
	go func() {
		defer wg.Done()
		_, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, testOp(t, "cc0c0c0c-0c0c-4c0c-8c0c-0c0c0c0c0c0c"))
		results <- err
	}()
	go func() {
		defer wg.Done()
		_, err := svc.SetLIVEShow(context.Background(), testActor(t), 11, 40001074, false, testOp(t, "cd0d0d0d-0d0d-4d0d-8d0d-0d0d0d0d0d0d"))
		results <- err
	}()
	wg.Wait()
	close(results)
	failures := 0
	for err := range results {
		if err != nil {
			if !errors.Is(err, ErrHeroAppearanceUnavailable) {
				t.Fatalf("unexpected ordering error %v", err)
			}
			failures++
		}
	}
	if failures > 1 || mat.count() != 1 {
		t.Fatalf("failures=%d debits=%d", failures, mat.count())
	}
	st.mu.Lock()
	defer st.mu.Unlock()
	if len(st.lives) != 1 || st.hero.StateVersion < 2 || st.hero.StateVersion > 3 {
		t.Fatalf("final hero=%+v lives=%+v", st.hero, st.lives)
	}
}

func TestCA74MID68SameOperationFingerprintConflictRejectsDifferentRequest(t *testing.T) {
	svc, st, mat, _ := ca74Service(ca74Hero(), nil)
	op := testOp(t, "ce0e0e0e-0e0e-4e0e-8e0e-0e0e0e0e0e0e")
	if _, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, op); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001109, op); err == nil {
		t.Fatal("same receipt identity accepted a different MID68 fingerprint")
	} else {
		var conflict *receipt.ConflictError
		if !errors.As(err, &conflict) {
			t.Fatalf("conflict err=%v", err)
		}
	}
	if n, _, _, _ := mat.snapshot(); n != 1 || st.saves != 1 || st.hero.StateVersion != 2 {
		t.Fatalf("conflict mutated state debits=%d saves=%d version=%d", n, st.saves, st.hero.StateVersion)
	}
}

func TestCA74MID68UnknownCommitReconcilesReceiptWithoutSecondMutation(t *testing.T) {
	heroMu := &sync.Mutex{}
	st := &ca74AtomicStore{hero: ca74Hero()}
	mat := &ca74AtomicMaterial{}
	db := &ca45AtomicDB{heroMu: heroMu, commitErr: errors.New("commit acknowledgement lost")}
	svc := ca74AtomicService(st, mat, db)
	got, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, testOp(t, "cf0f0f0f-0f0f-4f0f-8f0f-0f0f0f0f0f0f"))
	if err != nil {
		t.Fatal(err)
	}
	if !got.Replayed || !got.Mutated || got.StateVersion != 2 {
		t.Fatalf("unknown-commit result=%+v", got)
	}
	if mat.count() != 1 || db.count() != 1 {
		t.Fatalf("unknown-commit repeated transaction/debit begins=%d debits=%d", db.count(), mat.count())
	}
	st.mu.Lock()
	defer st.mu.Unlock()
	if st.saves != 1 || st.hero.StateVersion != 2 || len(st.lives) != 1 {
		t.Fatalf("unknown-commit state hero=%+v lives=%+v saves=%d", st.hero, st.lives, st.saves)
	}
}

func TestCA74ConcurrentDifferentModelUnlocksSerializeAndEachDebitOnce(t *testing.T) {
	heroMu := &sync.Mutex{}
	st := &ca74AtomicStore{hero: ca74Hero()}
	mat := &ca74AtomicMaterial{}
	svc := ca74AtomicService(st, mat, &ca45AtomicDB{heroMu: heroMu})
	type call struct {
		model int64
		op    operation.Context
	}
	calls := []call{
		{40001074, testOp(t, "d0101010-1010-4010-8010-101010101010")},
		{40001109, testOp(t, "d0202020-2020-4020-8020-202020202020")},
	}
	var wg sync.WaitGroup
	errs := make(chan error, len(calls))
	for _, c := range calls {
		c := c
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, c.model, c.op)
			errs <- err
		}()
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if mat.count() != 2 {
		t.Fatalf("distinct unlock debits=%d", mat.count())
	}
	st.mu.Lock()
	defer st.mu.Unlock()
	if st.saves != 2 || st.hero.StateVersion != 3 || len(st.lives) != 2 {
		t.Fatalf("hero=%+v lives=%+v saves=%d", st.hero, st.lives, st.saves)
	}
}

func TestCA74ConcurrentShowAssignmentsSerializeDesiredState(t *testing.T) {
	t.Run("same desired", func(t *testing.T) {
		heroMu := &sync.Mutex{}
		st := &ca74AtomicStore{hero: ca74Hero(), lives: []character.HeroLIVEEntitlement{liveEnt(40001074, true)}}
		mat := &ca74AtomicMaterial{}
		svc := ca74AtomicService(st, mat, &ca45AtomicDB{heroMu: heroMu})
		ops := []operation.Context{testOp(t, "d0303030-3030-4030-8030-303030303030"), testOp(t, "d0404040-4040-4040-8040-404040404040")}
		var wg sync.WaitGroup
		errs := make(chan error, 2)
		for _, op := range ops {
			op := op
			wg.Add(1)
			go func() {
				defer wg.Done()
				_, err := svc.SetLIVEShow(context.Background(), testActor(t), 11, 40001074, false, op)
				errs <- err
			}()
		}
		wg.Wait()
		close(errs)
		for err := range errs {
			if err != nil {
				t.Fatal(err)
			}
		}
		st.mu.Lock()
		defer st.mu.Unlock()
		if st.saves != 1 || st.hero.StateVersion != 2 || len(st.lives) != 1 || st.lives[0].IsShow {
			t.Fatalf("hero=%+v lives=%+v saves=%d", st.hero, st.lives, st.saves)
		}
	})

	t.Run("opposite desired", func(t *testing.T) {
		heroMu := &sync.Mutex{}
		st := &ca74AtomicStore{hero: ca74Hero(), lives: []character.HeroLIVEEntitlement{liveEnt(40001074, true)}}
		mat := &ca74AtomicMaterial{}
		svc := ca74AtomicService(st, mat, &ca45AtomicDB{heroMu: heroMu})
		type call struct {
			show bool
			op   operation.Context
		}
		calls := []call{{false, testOp(t, "d0505050-5050-4050-8050-505050505050")}, {true, testOp(t, "d0606060-6060-4060-8060-606060606060")}}
		var wg sync.WaitGroup
		errs := make(chan error, 2)
		for _, c := range calls {
			c := c
			wg.Add(1)
			go func() {
				defer wg.Done()
				_, err := svc.SetLIVEShow(context.Background(), testActor(t), 11, 40001074, c.show, c.op)
				errs <- err
			}()
		}
		wg.Wait()
		close(errs)
		for err := range errs {
			if err != nil {
				t.Fatal(err)
			}
		}
		st.mu.Lock()
		defer st.mu.Unlock()
		if st.saves < 1 || st.saves > 2 || st.hero.StateVersion != int64(1+st.saves) {
			t.Fatalf("opposite assignments did not serialize: hero=%+v lives=%+v saves=%d", st.hero, st.lives, st.saves)
		}
	})
}

func TestCA74HeroVersionTransitionPreservesCA6PracticeProposalFence(t *testing.T) {
	// CA6 proposals retain Hero ActorStateVersion. A real CA7-4 mutation must
	// therefore make the retained version stale, while a semantic no-op must not.
	svc, st, _, _ := ca74Service(ca74Hero(), nil)
	proposalActorVersion := st.hero.StateVersion
	if _, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, testOp(t, "d0707070-7070-4070-8070-707070707070")); err != nil {
		t.Fatal(err)
	}
	if st.hero.StateVersion == proposalActorVersion {
		t.Fatalf("real CA7-4 mutation did not stale CA6 proposal version=%d", proposalActorVersion)
	}
	postMutationVersion := st.hero.StateVersion
	if _, err := svc.UnlockLIVE(context.Background(), testActor(t), 11, 40001074, testOp(t, "d0808080-8080-4080-8080-808080808080")); err != nil {
		t.Fatal(err)
	}
	if st.hero.StateVersion != postMutationVersion {
		t.Fatalf("semantic no-op unexpectedly invalidated CA6 proposal version %d -> %d", postMutationVersion, st.hero.StateVersion)
	}
}

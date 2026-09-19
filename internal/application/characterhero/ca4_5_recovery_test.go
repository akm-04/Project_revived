package characterhero

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ca45AtomicTx struct {
	mu        sync.Mutex
	staged    []func()
	committed bool
	commitErr error
	heroMu    *sync.Mutex
	heroLock  bool
}

func (t *ca45AtomicTx) QueryRow(context.Context, string, ...any) tx.Row {
	return fakeRow{err: errors.New("unexpected query")}
}
func (t *ca45AtomicTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return fakeTag(1), nil
}
func (t *ca45AtomicTx) stage(fn func()) {
	t.mu.Lock()
	defer t.mu.Unlock()
	t.staged = append(t.staged, fn)
}
func (t *ca45AtomicTx) lockHero() {
	t.mu.Lock()
	if t.heroMu == nil || t.heroLock {
		t.mu.Unlock()
		return
	}
	t.heroLock = true
	m := t.heroMu
	t.mu.Unlock()
	m.Lock()
}
func (t *ca45AtomicTx) releaseHero() {
	t.mu.Lock()
	if !t.heroLock || t.heroMu == nil {
		t.mu.Unlock()
		return
	}
	m := t.heroMu
	t.heroLock = false
	t.mu.Unlock()
	m.Unlock()
}
func (t *ca45AtomicTx) Commit(context.Context) error {
	t.mu.Lock()
	fns := append([]func(){}, t.staged...)
	t.committed = true
	t.mu.Unlock()
	for _, fn := range fns {
		fn()
	}
	t.releaseHero()
	return t.commitErr
}
func (t *ca45AtomicTx) Rollback(context.Context) error {
	t.mu.Lock()
	if !t.committed {
		t.staged = nil
	}
	t.mu.Unlock()
	t.releaseHero()
	return nil
}

type ca45AtomicDB struct {
	mu        sync.Mutex
	begins    int
	commitErr error
	heroMu    *sync.Mutex
}

func (d *ca45AtomicDB) Begin(context.Context, tx.Options) (tx.Tx, error) {
	d.mu.Lock()
	d.begins++
	d.mu.Unlock()
	return &ca45AtomicTx{commitErr: d.commitErr, heroMu: d.heroMu}, nil
}
func (d *ca45AtomicDB) count() int { d.mu.Lock(); defer d.mu.Unlock(); return d.begins }

type ca45AtomicHeroStore struct {
	heroes map[int64]character.Hero
	saves  int
}

func (s *ca45AtomicHeroStore) ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error) {
	out := make([]character.Hero, 0, len(s.heroes))
	for _, h := range s.heroes {
		out = append(out, h)
	}
	return out, nil
}
func (s *ca45AtomicHeroStore) LockHeroByPartnerIDTx(_ context.Context, t tx.Tx, _ identity.PlayerID, id int64) (character.Hero, error) {
	at, ok := t.(*ca45AtomicTx)
	if !ok {
		return character.Hero{}, errors.New("test CA4-5 atomic store: unexpected tx")
	}
	at.lockHero()
	h, ok := s.heroes[id]
	if !ok {
		return character.Hero{}, ErrHeroNotFound
	}
	return h, nil
}
func (s *ca45AtomicHeroStore) SaveHeroProgressionTx(ctx context.Context, t tx.Tx, h character.Hero, old int64) error {
	return s.SaveHeroStateTx(ctx, t, h, old)
}
func (s *ca45AtomicHeroStore) SaveHeroStateTx(_ context.Context, t tx.Tx, h character.Hero, old int64) error {
	at, ok := t.(*ca45AtomicTx)
	if !ok {
		return errors.New("test CA4-5 atomic store: unexpected tx")
	}
	cur, ok := s.heroes[h.PartnerID]
	if !ok || cur.StateVersion != old || h.StateVersion != old+1 {
		return errors.New("test CA4-5 atomic store: bad version")
	}
	at.stage(func() { s.heroes[h.PartnerID] = h; s.saves++ })
	return nil
}

type ca45AtomicMaterial struct {
	mu          sync.Mutex
	debits      int
	item, count int64
}

func (m *ca45AtomicMaterial) DebitMaterialCostTx(_ context.Context, t tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	at, ok := t.(*ca45AtomicTx)
	if !ok {
		return appi5.MaterialDebitResult{}, errors.New("test CA4-5 atomic material: unexpected tx")
	}
	if len(cost.Stacks) != 1 || len(cost.Scalars) != 0 {
		return appi5.MaterialDebitResult{}, errors.New("test CA4-5 atomic material: unexpected cost")
	}
	line := cost.Stacks[0]
	at.stage(func() { m.mu.Lock(); m.debits++; m.item, m.count = line.ItemID, line.Amount; m.mu.Unlock() })
	return appi5.MaterialDebitResult{}, nil
}
func (m *ca45AtomicMaterial) snapshot() (int, int64, int64) {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.debits, m.item, m.count
}

type ca45AtomicReceipts struct {
	mu      sync.Mutex
	m       map[receipt.Identity]receipt.Receipt
	failPut bool
}

func newCA45AtomicReceipts() *ca45AtomicReceipts {
	return &ca45AtomicReceipts{m: map[receipt.Identity]receipt.Receipt{}}
}
func (r *ca45AtomicReceipts) PutTx(_ context.Context, t tx.Tx, x receipt.Receipt) (receipt.PutResult, error) {
	if r.failPut {
		return receipt.PutResult{}, errors.New("test CA4-5 receipt write failure")
	}
	at, ok := t.(*ca45AtomicTx)
	if !ok {
		return receipt.PutResult{}, errors.New("test CA4-5 atomic receipt: unexpected tx")
	}
	r.mu.Lock()
	old, exists := r.m[x.Identity]
	r.mu.Unlock()
	if exists {
		return receipt.PutResult{Receipt: old}, nil
	}
	at.stage(func() { r.mu.Lock(); r.m[x.Identity] = x; r.mu.Unlock() })
	return receipt.PutResult{Receipt: x, Inserted: true}, nil
}
func (r *ca45AtomicReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	x, ok := r.m[id]
	return x, ok, nil
}
func (r *ca45AtomicReceipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	x, ok := r.m[id]
	return x, ok, nil
}
func (r *ca45AtomicReceipts) count() int { r.mu.Lock(); defer r.mu.Unlock(); return len(r.m) }

type ca45MissingReceiptReader struct{}

func (ca45MissingReceiptReader) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

type ca45AtomicFence struct{}

func (ca45AtomicFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

func ca45AtomicEnhanceFixture(t *testing.T, h character.Hero, commitErr error) (Service, *ca45AtomicHeroStore, *ca45AtomicMaterial, *ca45AtomicReceipts, *ca45AtomicDB) {
	t.Helper()
	svc, _, _, _ := equipmentServiceFixture(t, h, nil)
	heroMu := &sync.Mutex{}
	st := &ca45AtomicHeroStore{heroes: map[int64]character.Hero{h.PartnerID: h}}
	mat := &ca45AtomicMaterial{}
	rec := newCA45AtomicReceipts()
	db := &ca45AtomicDB{commitErr: commitErr, heroMu: heroMu}
	svc.Runner = tx.Runner{DB: db}
	svc.Fencer = ca45AtomicFence{}
	svc.ProgressionStore = st
	svc.MaterialCosts = mat
	svc.Receipts = rec
	svc.ReceiptRead = rec
	return svc, st, mat, rec, db
}

func TestCA45MID304LateReceiptFailureRollsBackHeroAndDebitTogether(t *testing.T) {
	now := testOp(t, "d1010101-0101-4101-8101-010101010101").StartedAt
	h := heroAt(11, 9001, 9001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment[0] = 1
	svc, st, mat, rec, _ := ca45AtomicEnhanceFixture(t, h, nil)
	rec.failPut = true
	if _, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "d2020202-0202-4202-8202-020202020202")); err == nil {
		t.Fatal("expected receipt failure")
	}
	if st.heroes[11].Equipment[0] != 1 || st.saves != 0 {
		t.Fatalf("Hero mutation escaped rollback: %+v saves=%d", st.heroes[11], st.saves)
	}
	if n, _, _ := mat.snapshot(); n != 0 || rec.count() != 0 {
		t.Fatalf("debit/receipt escaped rollback debits=%d receipts=%d", n, rec.count())
	}
}

func TestCA45MID304AmbiguousCommitReconcilesOnlyThroughOuterReceipt(t *testing.T) {
	now := testOp(t, "d3030303-0303-4303-8303-030303030303").StartedAt
	h := heroAt(11, 9001, 9001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment[0] = 1
	svc, st, mat, rec, db := ca45AtomicEnhanceFixture(t, h, errors.New("commit acknowledgement lost"))
	got, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "d4040404-0404-4404-8404-040404040404"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment[0] != 2 || st.heroes[11].Equipment[0] != 2 || st.saves != 1 || rec.count() != 1 || db.count() != 1 {
		t.Fatalf("reconcile drift got=%+v hero=%+v saves=%d receipts=%d begins=%d", got, st.heroes[11], st.saves, rec.count(), db.count())
	}
	if n, _, count := mat.snapshot(); n != 1 || count != 1 {
		t.Fatalf("debit=%d count=%d", n, count)
	}
}

func TestCA45MID304AmbiguousCommitWithoutOuterReceiptIsUnknownNoBlindReplay(t *testing.T) {
	now := testOp(t, "d5050505-0505-4505-8505-050505050505").StartedAt
	h := heroAt(11, 9001, 9001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment[0] = 1
	svc, st, mat, _, db := ca45AtomicEnhanceFixture(t, h, errors.New("commit acknowledgement lost"))
	svc.ReceiptRead = ca45MissingReceiptReader{}
	_, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "d6060606-0606-4606-8606-060606060606"))
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatalf("expected UNKNOWN COMMIT, got %v", err)
	}
	if st.heroes[11].Equipment[0] != 2 || st.saves != 1 || db.count() != 1 {
		t.Fatalf("ambiguous commit replayed/drift hero=%+v saves=%d begins=%d", st.heroes[11], st.saves, db.count())
	}
	if n, _, _ := mat.snapshot(); n != 1 {
		t.Fatalf("debits=%d", n)
	}
}

func TestCA45MID304ConcurrentSameHeroSerializesWithoutLostUpdate(t *testing.T) {
	now := testOp(t, "d7070707-0707-4707-8707-070707070707").StartedAt
	h := heroAt(11, 9001, 9001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment[0] = 1
	svc, st, mat, _, _ := ca45AtomicEnhanceFixture(t, h, nil)
	ops := []operation.Context{testOp(t, "d8080808-0808-4808-8808-080808080808"), testOp(t, "d9090909-0909-4909-8909-090909090909")}
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for _, op := range ops {
		wg.Add(1)
		go func(op operation.Context) {
			defer wg.Done()
			_, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, op)
			errs <- err
		}(op)
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if st.heroes[11].Equipment[0] != 3 || st.saves != 2 {
		t.Fatalf("lost update hero=%+v saves=%d", st.heroes[11], st.saves)
	}
	if n, _, count := mat.snapshot(); n != 2 || count != 1 {
		t.Fatalf("debits=%d lastCount=%d", n, count)
	}
}

func TestCA45SuperMID54AmbiguousCommitReconcilesThroughReceipt(t *testing.T) {
	now := testOp(t, "da010101-0101-4101-8101-010101010101").StartedAt
	h := heroAt(11, 9001, 9001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	svc, st, mat, rec, db := ca45AtomicEnhanceFixture(t, h, errors.New("commit acknowledgement lost"))
	got, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, testOp(t, "da020202-0202-4202-8202-020202020202"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment[0] != 1 || st.heroes[11].Equipment[0] != 1 || st.saves != 1 || rec.count() != 1 || db.count() != 1 {
		t.Fatalf("MID54 reconcile drift got=%+v hero=%+v saves=%d receipts=%d begins=%d", got, st.heroes[11], st.saves, rec.count(), db.count())
	}
	if n, item, count := mat.snapshot(); n != 1 || item != 20001366 || count != 1 {
		t.Fatalf("MID54 debit=%d item=%d count=%d", n, item, count)
	}
}

func TestCA45SuperMID54AmbiguousCommitWithoutReceiptIsUnknownNoBlindReplay(t *testing.T) {
	now := testOp(t, "da030303-0303-4303-8303-030303030303").StartedAt
	h := heroAt(11, 9001, 9001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	svc, st, mat, _, db := ca45AtomicEnhanceFixture(t, h, errors.New("commit acknowledgement lost"))
	svc.ReceiptRead = ca45MissingReceiptReader{}
	_, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, testOp(t, "da040404-0404-4404-8404-040404040404"))
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatalf("expected UNKNOWN COMMIT, got %v", err)
	}
	if st.heroes[11].Equipment[0] != 1 || st.saves != 1 || db.count() != 1 {
		t.Fatalf("MID54 ambiguous commit replayed/drift hero=%+v saves=%d begins=%d", st.heroes[11], st.saves, db.count())
	}
	if n, _, _ := mat.snapshot(); n != 1 {
		t.Fatalf("MID54 debits=%d", n)
	}
}

func TestCA45ConcurrentSuperEquipAndEnhanceSerializeWithoutLostSlots(t *testing.T) {
	now := testOp(t, "da050505-0505-4505-8505-050505050505").StartedAt
	h := heroAt(11, 9001, 9001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment[0] = 1 // enhance slot 1; equip slot 2 concurrently
	svc, st, mat, _, _ := ca45AtomicEnhanceFixture(t, h, nil)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	wg.Add(2)
	go func() {
		defer wg.Done()
		_, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "da060606-0606-4606-8606-060606060606"))
		errs <- err
	}()
	go func() {
		defer wg.Done()
		_, err := svc.EquipItem(context.Background(), testActor(t), 11, 2, testOp(t, "da070707-0707-4707-8707-070707070707"))
		errs <- err
	}()
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if st.heroes[11].Equipment[0] != 2 || st.heroes[11].Equipment[1] != 1 || st.saves != 2 {
		t.Fatalf("lost slot update hero=%+v saves=%d", st.heroes[11], st.saves)
	}
	if n, _, _ := mat.snapshot(); n != 2 {
		t.Fatalf("combined debits=%d", n)
	}
}

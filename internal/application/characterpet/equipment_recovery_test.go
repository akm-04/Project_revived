package characterpet

import (
	"context"
	"errors"
	"sync"
	"testing"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ca4aAtomicTx struct {
	mu        sync.Mutex
	commits   []func()
	committed bool
	commitErr error
	petMu     *sync.Mutex
	petLocked bool
}

func (t *ca4aAtomicTx) QueryRow(context.Context, string, ...any) tx.Row { return caRow{} }
func (t *ca4aAtomicTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return caTag(1), nil
}
func (t *ca4aAtomicTx) stage(fn func()) {
	t.mu.Lock()
	defer t.mu.Unlock()
	t.commits = append(t.commits, fn)
}
func (t *ca4aAtomicTx) lockPet() {
	t.mu.Lock()
	if t.petMu == nil || t.petLocked {
		t.mu.Unlock()
		return
	}
	t.petLocked = true
	mu := t.petMu
	t.mu.Unlock()
	mu.Lock()
}
func (t *ca4aAtomicTx) releasePet() {
	t.mu.Lock()
	if !t.petLocked || t.petMu == nil {
		t.mu.Unlock()
		return
	}
	mu := t.petMu
	t.petLocked = false
	t.mu.Unlock()
	mu.Unlock()
}
func (t *ca4aAtomicTx) Commit(context.Context) error {
	t.mu.Lock()
	fns := append([]func(){}, t.commits...)
	t.committed = true
	t.mu.Unlock()
	for _, fn := range fns {
		fn()
	}
	t.releasePet()
	return t.commitErr
}
func (t *ca4aAtomicTx) Rollback(context.Context) error {
	// A cleanup rollback after an ambiguous commit cannot undo a transaction
	// which the database already committed.
	t.mu.Lock()
	if !t.committed {
		t.commits = nil
	}
	t.mu.Unlock()
	t.releasePet()
	return nil
}

type ca4aAtomicDB struct {
	commitErr error
	petMu     *sync.Mutex
}

func (d ca4aAtomicDB) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return &ca4aAtomicTx{commitErr: d.commitErr, petMu: d.petMu}, nil
}

type ca4aAtomicStore struct{ *caStore }

func (s *ca4aAtomicStore) LockPetByIDTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, id int64) (character.Pet, bool, error) {
	if at, ok := t.(*ca4aAtomicTx); ok {
		at.lockPet()
	}
	return s.caStore.LockPetByIDTx(ctx, t, pid, id)
}

func (s *ca4aAtomicStore) SavePetStateTx(_ context.Context, t tx.Tx, p character.Pet, old int64) error {
	if p.StateVersion != old+1 {
		return errors.New("test atomic store: bad version")
	}
	at, ok := t.(*ca4aAtomicTx)
	if !ok {
		return errors.New("test atomic store: unexpected tx")
	}
	at.stage(func() { s.byID[p.PetID] = p })
	return nil
}

type ca4aAtomicMaterial struct {
	mu     sync.Mutex
	debits int
}

func (m *ca4aAtomicMaterial) DebitMaterialCostTx(_ context.Context, t tx.Tx, _ identity.PlayerID, _ appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	at, ok := t.(*ca4aAtomicTx)
	if !ok {
		return appi5.MaterialDebitResult{}, errors.New("test atomic material: unexpected tx")
	}
	at.stage(func() {
		m.mu.Lock()
		m.debits++
		m.mu.Unlock()
	})
	return appi5.MaterialDebitResult{}, nil
}
func (m *ca4aAtomicMaterial) count() int {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.debits
}

type ca4aAtomicReceipts struct {
	mu      sync.Mutex
	m       map[receipt.Identity]receipt.Receipt
	failPut bool
}

func newCA4AAtomicReceipts() *ca4aAtomicReceipts {
	return &ca4aAtomicReceipts{m: map[receipt.Identity]receipt.Receipt{}}
}
func (r *ca4aAtomicReceipts) PutTx(_ context.Context, t tx.Tx, x receipt.Receipt) (receipt.PutResult, error) {
	if r.failPut {
		return receipt.PutResult{}, errors.New("test receipt write failure")
	}
	at, ok := t.(*ca4aAtomicTx)
	if !ok {
		return receipt.PutResult{}, errors.New("test atomic receipt: unexpected tx")
	}
	r.mu.Lock()
	old, exists := r.m[x.Identity]
	r.mu.Unlock()
	if exists {
		return receipt.PutResult{Receipt: old}, nil
	}
	at.stage(func() {
		r.mu.Lock()
		r.m[x.Identity] = x
		r.mu.Unlock()
	})
	return receipt.PutResult{Receipt: x, Inserted: true}, nil
}
func (r *ca4aAtomicReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	x, ok := r.m[id]
	return x, ok, nil
}
func (r *ca4aAtomicReceipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	x, ok := r.m[id]
	return x, ok, nil
}

func TestPetEquipItemLateReceiptFailureRollsBackPetAndDebitTogether(t *testing.T) {
	svc, base, _, _, content := petEquipmentFixture(t, character.PetEquipmentOrdinary, false)
	store := &ca4aAtomicStore{caStore: base}
	mat := &ca4aAtomicMaterial{}
	rec := newCA4AAtomicReceipts()
	rec.failPut = true
	svc.Runner = tx.Runner{DB: ca4aAtomicDB{}}
	svc.Store = store
	svc.MaterialCosts = mat
	svc.Receipts = rec
	svc.ReceiptRead = rec
	svc.Equipment = content
	before := base.byID[1]
	_, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, caOp(t, "91919191-9191-4191-8191-919191919191", 3300))
	if err == nil || err.Error() != "test receipt write failure" {
		t.Fatalf("err=%v", err)
	}
	if got := base.byID[1]; got != before {
		t.Fatalf("Pet mutation escaped rollback: before=%+v after=%+v", before, got)
	}
	if mat.count() != 0 {
		t.Fatalf("resource debit escaped rollback: %d", mat.count())
	}
	if len(rec.m) != 0 {
		t.Fatalf("receipt escaped rollback: %d", len(rec.m))
	}
}

func TestPetEquipItemAmbiguousCommitReceiptReconcilesWithoutSecondDebit(t *testing.T) {
	svc, base, _, _, content := petEquipmentFixture(t, character.PetEquipmentOrdinary, false)
	store := &ca4aAtomicStore{caStore: base}
	mat := &ca4aAtomicMaterial{}
	rec := newCA4AAtomicReceipts()
	svc.Runner = tx.Runner{DB: ca4aAtomicDB{commitErr: errors.New("transport lost after commit")}}
	svc.Store = store
	svc.MaterialCosts = mat
	svc.Receipts = rec
	svc.ReceiptRead = rec
	svc.Equipment = content
	op := caOp(t, "92929292-9292-4292-8292-929292929292", 3301)
	got, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.AlreadyEquipped || got.Equipment != (character.PetEquipmentSlots{1, 0, 0}) || mat.count() != 1 || len(rec.m) != 1 {
		t.Fatalf("reconciled result=%+v debits=%d receipts=%d", got, mat.count(), len(rec.m))
	}
	version := base.byID[1].StateVersion
	got2, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got2.Equipment[0] != 1 || mat.count() != 1 || base.byID[1].StateVersion != version {
		t.Fatalf("replay after reconciliation mutated again: got=%+v debits=%d version=%d/%d", got2, mat.count(), base.byID[1].StateVersion, version)
	}
}

type ca4aConcurrentProgression struct{ rev string }

func (c ca4aConcurrentProgression) PetProgressionActive(context.Context) (string, bool, error) {
	return c.rev, true, nil
}
func (c ca4aConcurrentProgression) PetProgressionRevision(context.Context, string) (bool, error) {
	return true, nil
}
func (c ca4aConcurrentProgression) PetProgressionTemplateTx(context.Context, tx.Queryer, string, int64) (ProgressionTemplate, error) {
	return ProgressionTemplate{}, errors.New("unexpected progression template read")
}
func (c ca4aConcurrentProgression) PetSkillSlotsTx(context.Context, tx.Queryer, string, int64) ([]SkillSlotDefinition, error) {
	return nil, errors.New("unexpected skill slot read")
}
func (c ca4aConcurrentProgression) PetExpItemTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return 0, errors.New("unexpected exp item read")
}
func (c ca4aConcurrentProgression) PetExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]ExpThreshold, error) {
	return nil, errors.New("unexpected exp policy read")
}
func (c ca4aConcurrentProgression) PetSkillBookCostTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return 0, errors.New("unexpected skill book read")
}
func (c ca4aConcurrentProgression) PetSkillSlotPolicyTx(context.Context, tx.Queryer, string, int64) (SkillSlotPolicy, error) {
	return SkillSlotPolicy{}, errors.New("unexpected skill policy read")
}
func (c ca4aConcurrentProgression) PetEvolutionCostTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return 0, errors.New("unexpected evolution read")
}
func (c ca4aConcurrentProgression) PetProgressionPolicyTx(context.Context, tx.Queryer, string) (ProgressionPolicy, error) {
	return ProgressionPolicy{}, errors.New("unexpected progression policy read")
}
func (c ca4aConcurrentProgression) CharacterMaxLevelTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return 0, errors.New("unexpected max-level read")
}

func TestPetEquipItemConcurrentSamePetSerializesWithoutDoubleDebit(t *testing.T) {
	svc, base, _, _, content := petEquipmentFixture(t, character.PetEquipmentOrdinary, false)
	store := &ca4aAtomicStore{caStore: base}
	mat := &ca4aAtomicMaterial{}
	rec := newCA4AAtomicReceipts()
	var petMu sync.Mutex
	svc.Runner = tx.Runner{DB: ca4aAtomicDB{petMu: &petMu}}
	svc.Store = store
	svc.MaterialCosts = mat
	svc.Receipts = rec
	svc.ReceiptRead = rec
	svc.Equipment = content
	svc.Progression = ca4aConcurrentProgression{rev: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
	actor := caActor(t)

	type callResult struct {
		got EquipItemResult
		err error
	}
	start := make(chan struct{})
	results := make(chan callResult, 2)
	ops := []operation.Context{
		caOp(t, "93939393-9393-4393-8393-939393939393", 3302),
		caOp(t, "94949494-9494-4494-8494-949494949494", 3303),
	}
	for _, op := range ops {
		op := op
		go func() {
			<-start
			got, err := svc.EquipItem(context.Background(), actor, 1, 1, op)
			results <- callResult{got: got, err: err}
		}()
	}
	close(start)
	r1, r2 := <-results, <-results
	if r1.err != nil || r2.err != nil {
		t.Fatalf("concurrent errors: %v / %v", r1.err, r2.err)
	}
	already := 0
	for _, r := range []callResult{r1, r2} {
		if r.got.AlreadyEquipped {
			already++
		}
		if r.got.Equipment[0] != 1 {
			t.Fatalf("non-converged equipment result: %+v", r.got)
		}
	}
	if already != 1 || mat.count() != 1 || base.byID[1].Equipment[0] != 1 || len(rec.m) != 2 {
		t.Fatalf("already=%d debits=%d pet=%+v receipts=%d", already, mat.count(), base.byID[1], len(rec.m))
	}
}

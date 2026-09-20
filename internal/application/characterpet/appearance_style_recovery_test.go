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

type ca75AtomicStore struct {
	*caStore
	mu               sync.Mutex
	ents             map[int64][]character.PetStyleEntitlement
	compositeSaves   int
	activeStyleSaves int
}

func (s *ca75AtomicStore) FindPetByOriginTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, origin int64) (character.Pet, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, p := range s.byID {
		if p.OriginTableID == origin {
			return p, true, nil
		}
	}
	return character.Pet{}, false, nil
}
func (s *ca75AtomicStore) LockPetByIDTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, id int64) (character.Pet, bool, error) {
	at, ok := t.(*ca4aAtomicTx)
	if !ok {
		return character.Pet{}, false, errors.New("test CA7-5 atomic store: unexpected tx")
	}
	at.lockPet()
	s.mu.Lock()
	defer s.mu.Unlock()
	p, found := s.byID[id]
	if found && p.PlayerID != pid {
		return character.Pet{}, false, nil
	}
	return p, found, nil
}
func (s *ca75AtomicStore) ListPetStyleEntitlements(_ context.Context, _ identity.PlayerID, petID int64) ([]character.PetStyleEntitlement, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]character.PetStyleEntitlement(nil), s.ents[petID]...), nil
}
func (s *ca75AtomicStore) ListPetStyleEntitlementsTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, petID int64) ([]character.PetStyleEntitlement, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]character.PetStyleEntitlement(nil), s.ents[petID]...), nil
}
func (s *ca75AtomicStore) SavePetAppearanceMutationTx(_ context.Context, t tx.Tx, p character.Pet, ent *character.PetStyleEntitlement, old int64) error {
	at, ok := t.(*ca4aAtomicTx)
	if !ok {
		return errors.New("test CA7-5 atomic store: unexpected tx")
	}
	s.mu.Lock()
	cur, found := s.byID[p.PetID]
	s.mu.Unlock()
	if !found || cur.StateVersion != old || p.StateVersion != old+1 {
		return errors.New("test CA7-5 atomic store: bad composite version")
	}
	at.stage(func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		s.byID[p.PetID] = p
		if ent != nil {
			rows := append([]character.PetStyleEntitlement(nil), s.ents[p.PetID]...)
			exists := false
			for _, x := range rows {
				if x.StyleItemID == ent.StyleItemID {
					exists = true
					break
				}
			}
			if !exists {
				rows = append(rows, *ent)
			}
			s.ents[p.PetID] = rows
		}
		s.compositeSaves++
	})
	return nil
}
func (s *ca75AtomicStore) SavePetActiveStyleTx(_ context.Context, t tx.Tx, p character.Pet, old int64) error {
	at, ok := t.(*ca4aAtomicTx)
	if !ok {
		return errors.New("test CA7-5 atomic store: unexpected tx")
	}
	s.mu.Lock()
	cur, found := s.byID[p.PetID]
	s.mu.Unlock()
	if !found || cur.StateVersion != old || p.StateVersion != old+1 {
		return errors.New("test CA7-5 atomic store: bad active version")
	}
	at.stage(func() { s.mu.Lock(); s.byID[p.PetID] = p; s.activeStyleSaves++; s.mu.Unlock() })
	return nil
}
func (s *ca75AtomicStore) pet(id int64) character.Pet {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.byID[id]
}
func (s *ca75AtomicStore) styleRows(id int64) []character.PetStyleEntitlement {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]character.PetStyleEntitlement(nil), s.ents[id]...)
}
func (s *ca75AtomicStore) saveCounts() (int, int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.compositeSaves, s.activeStyleSaves
}

type ca75AtomicMaterial struct {
	mu     sync.Mutex
	debits map[int64]int
}

func (m *ca75AtomicMaterial) DebitMaterialCostTx(_ context.Context, t tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	at, ok := t.(*ca4aAtomicTx)
	if !ok {
		return appi5.MaterialDebitResult{}, errors.New("test CA7-5 atomic material: unexpected tx")
	}
	if len(cost.Stacks) != 1 || cost.Stacks[0].Amount != 1 {
		return appi5.MaterialDebitResult{}, errors.New("test CA7-5 atomic material: unexpected cost")
	}
	item := cost.Stacks[0].ItemID
	at.stage(func() {
		m.mu.Lock()
		if m.debits == nil {
			m.debits = map[int64]int{}
		}
		m.debits[item]++
		m.mu.Unlock()
	})
	return appi5.MaterialDebitResult{}, nil
}
func (m *ca75AtomicMaterial) count(item int64) int {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.debits[item]
}

func ca75AtomicService(pets []character.Pet, ents map[int64][]character.PetStyleEntitlement, commitErr error) (Service, *ca75AtomicStore, *ca75AtomicMaterial, *ca4aAtomicReceipts) {
	byID := map[int64]character.Pet{}
	for _, p := range pets {
		byID[p.PetID] = p
	}
	rows := map[int64][]character.PetStyleEntitlement{}
	for id, in := range ents {
		rows[id] = append([]character.PetStyleEntitlement(nil), in...)
	}
	st := &ca75AtomicStore{caStore: &caStore{byID: byID}, ents: rows}
	mat := &ca75AtomicMaterial{debits: map[int64]int{}}
	rec := newCA4AAtomicReceipts()
	var petMu sync.Mutex
	content := ca75ContentFixture()
	svc := Service{Runner: tx.Runner{DB: ca4aAtomicDB{commitErr: commitErr, petMu: &petMu}}, Store: st, Fencer: caFence{}, Receipts: rec, ReceiptRead: rec, MaterialCosts: mat, AppearanceStore: st, Appearance: content, AppearanceMutationStore: st}
	return svc, st, mat, rec
}

func TestCA75UnknownCommitAcquireReconcilesReceiptWithoutSecondDebit(t *testing.T) {
	svc, st, mat, rec := ca75AtomicService([]character.Pet{ca75Pet(11, ca75PetOriginA, 0, 4)}, nil, errors.New("transport lost after commit"))
	op := caOp(t, "75000000-0000-4000-8000-000000000101", 300)
	got, err := svc.AcquirePetStyle(context.Background(), caActor(t), ca75StyleA, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got.Replayed || got.StateVersion != 5 || mat.count(ca75StyleA) != 1 || len(rec.m) != 1 {
		t.Fatalf("got=%+v debit=%d receipts=%d", got, mat.count(ca75StyleA), len(rec.m))
	}
	c, a := st.saveCounts()
	if c != 1 || a != 0 {
		t.Fatalf("saves=%d/%d", c, a)
	}
	got2, err := svc.AcquirePetStyle(context.Background(), caActor(t), ca75StyleA, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got2.Replayed || st.pet(11).StateVersion != 5 || mat.count(ca75StyleA) != 1 {
		t.Fatalf("replay=%+v pet=%+v debit=%d", got2, st.pet(11), mat.count(ca75StyleA))
	}
}

func TestCA75UnknownCommitSelectReconcilesReceiptWithoutSecondMutation(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, _, rec := ca75AtomicService([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA)}}, errors.New("transport lost after commit"))
	op := caOp(t, "75000000-0000-4000-8000-000000000114", 313)
	got, err := svc.SelectPetStyle(context.Background(), caActor(t), 11, ca75StyleA, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got.Replayed || !got.Mutated || got.ActiveStyle != ca75StyleA || got.StateVersion != 5 || len(rec.m) != 1 {
		t.Fatalf("got=%+v receipts=%d", got, len(rec.m))
	}
	c, a := st.saveCounts()
	if c != 0 || a != 1 || st.pet(11).StateVersion != 5 || st.pet(11).ActiveStyle != ca75StyleA {
		t.Fatalf("saves=%d/%d pet=%+v", c, a, st.pet(11))
	}
	got2, err := svc.SelectPetStyle(context.Background(), caActor(t), 11, ca75StyleA, op)
	if err != nil {
		t.Fatal(err)
	}
	_, a2 := st.saveCounts()
	if !got2.Replayed || a2 != 1 || st.pet(11).StateVersion != 5 {
		t.Fatalf("replay=%+v saves=%d pet=%+v", got2, a2, st.pet(11))
	}
}

func TestCA75UnknownCommitCancelReconcilesReceiptWithoutSecondMutation(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, ca75StyleA, 4)
	svc, st, _, rec := ca75AtomicService([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA)}}, errors.New("transport lost after commit"))
	op := caOp(t, "75000000-0000-4000-8000-000000000115", 314)
	got, err := svc.CancelPetStyle(context.Background(), caActor(t), 11, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got.Replayed || !got.Mutated || got.ActiveStyle != 0 || got.StateVersion != 5 || len(rec.m) != 1 {
		t.Fatalf("got=%+v receipts=%d", got, len(rec.m))
	}
	c, a := st.saveCounts()
	if c != 0 || a != 1 || st.pet(11).StateVersion != 5 || st.pet(11).ActiveStyle != 0 {
		t.Fatalf("saves=%d/%d pet=%+v", c, a, st.pet(11))
	}
	got2, err := svc.CancelPetStyle(context.Background(), caActor(t), 11, op)
	if err != nil {
		t.Fatal(err)
	}
	_, a2 := st.saveCounts()
	if !got2.Replayed || a2 != 1 || st.pet(11).StateVersion != 5 {
		t.Fatalf("replay=%+v saves=%d pet=%+v", got2, a2, st.pet(11))
	}
}

func TestCA75ConcurrentFreshSameItemAcquireConsumesAndMutatesOnce(t *testing.T) {
	svc, st, mat, _ := ca75AtomicService([]character.Pet{ca75Pet(11, ca75PetOriginA, 0, 4)}, nil, nil)
	actor := caActor(t)
	type result struct {
		got PetStyleAcquireResult
		err error
	}
	start := make(chan struct{})
	out := make(chan result, 2)
	ops := []operation.Context{caOp(t, "75000000-0000-4000-8000-000000000102", 301), caOp(t, "75000000-0000-4000-8000-000000000103", 302)}
	for _, op := range ops {
		op := op
		go func() {
			<-start
			got, err := svc.AcquirePetStyle(context.Background(), actor, ca75StyleA, op)
			out <- result{got, err}
		}()
	}
	close(start)
	r1, r2 := <-out, <-out
	for _, r := range []result{r1, r2} {
		if r.err != nil {
			t.Fatal(r.err)
		}
		if r.got.ActiveStyle != 0 || len(r.got.PetStyles) != 1 || r.got.PetStyles[0] != ca75StyleA {
			t.Fatalf("result=%+v", r.got)
		}
	}
	consumed := 0
	for _, r := range []result{r1, r2} {
		if r.got.Consumed {
			consumed++
		}
	}
	c, a := st.saveCounts()
	if consumed != 1 || mat.count(ca75StyleA) != 1 || c != 1 || a != 0 || st.pet(11).StateVersion != 5 || len(st.styleRows(11)) != 1 {
		t.Fatalf("consumed=%d debit=%d saves=%d/%d pet=%+v rows=%v", consumed, mat.count(ca75StyleA), c, a, st.pet(11), st.styleRows(11))
	}
}

func TestCA75ConcurrentSameStyleSelectBumpsOnce(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, _, _ := ca75AtomicService([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA)}}, nil)
	actor := caActor(t)
	type result struct {
		got PetStyleSelectResult
		err error
	}
	start := make(chan struct{})
	out := make(chan result, 2)
	ops := []operation.Context{caOp(t, "75000000-0000-4000-8000-000000000104", 303), caOp(t, "75000000-0000-4000-8000-000000000105", 304)}
	for _, op := range ops {
		op := op
		go func() {
			<-start
			got, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleA, op)
			out <- result{got, err}
		}()
	}
	close(start)
	r1, r2 := <-out, <-out
	mutated := 0
	for _, r := range []result{r1, r2} {
		if r.err != nil {
			t.Fatal(r.err)
		}
		if r.got.Mutated {
			mutated++
		}
	}
	c, a := st.saveCounts()
	if mutated != 1 || c != 0 || a != 1 || st.pet(11).StateVersion != 5 || st.pet(11).ActiveStyle != ca75StyleA {
		t.Fatalf("mutated=%d saves=%d/%d pet=%+v", mutated, c, a, st.pet(11))
	}
}

func TestCA75ConcurrentDifferentStyleSelectOneWinnerOneConflict(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, _, _ := ca75AtomicService([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA), ca75Ent(11, ca75StyleB)}}, nil)
	actor := caActor(t)
	type result struct {
		style int64
		err   error
	}
	start := make(chan struct{})
	out := make(chan result, 2)
	calls := []struct {
		style int64
		op    operation.Context
	}{{ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000106", 305)}, {ca75StyleB, caOp(t, "75000000-0000-4000-8000-000000000107", 306)}}
	for _, c := range calls {
		c := c
		go func() {
			<-start
			_, err := svc.SelectPetStyle(context.Background(), actor, 11, c.style, c.op)
			out <- result{c.style, err}
		}()
	}
	close(start)
	r1, r2 := <-out, <-out
	success, conflict := 0, 0
	var winner int64
	for _, r := range []result{r1, r2} {
		if r.err == nil {
			success++
			winner = r.style
		} else if errors.Is(r.err, ErrPetStyleSwitchConflict) {
			conflict++
		} else {
			t.Fatalf("style=%d err=%v", r.style, r.err)
		}
	}
	_, a := st.saveCounts()
	if success != 1 || conflict != 1 || a != 1 || st.pet(11).StateVersion != 5 || st.pet(11).ActiveStyle != winner {
		t.Fatalf("success/conflict=%d/%d winner=%d saves=%d pet=%+v", success, conflict, winner, a, st.pet(11))
	}
}

func TestCA75ConcurrentSelectCancelSerializableOrdering(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, _, _ := ca75AtomicService([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA)}}, nil)
	actor := caActor(t)
	start := make(chan struct{})
	errs := make(chan error, 2)
	go func() {
		<-start
		_, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000108", 307))
		errs <- err
	}()
	go func() {
		<-start
		_, err := svc.CancelPetStyle(context.Background(), actor, 11, caOp(t, "75000000-0000-4000-8000-000000000109", 308))
		errs <- err
	}()
	close(start)
	if err := <-errs; err != nil {
		t.Fatal(err)
	}
	if err := <-errs; err != nil {
		t.Fatal(err)
	}
	got := st.pet(11)
	_, a := st.saveCounts()
	if got.ActiveStyle == ca75StyleA {
		if got.StateVersion != 5 || a != 1 {
			t.Fatalf("cancel-first final=%+v saves=%d", got, a)
		}
	} else if got.ActiveStyle == 0 {
		if got.StateVersion != 6 || a != 2 {
			t.Fatalf("select-first final=%+v saves=%d", got, a)
		}
	} else {
		t.Fatalf("invalid final=%+v", got)
	}
}

func TestCA75ConcurrentAcquireSelectInitiallyUnownedSerializesDeterministically(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, mat, _ := ca75AtomicService([]character.Pet{p}, nil, nil)
	actor := caActor(t)
	start := make(chan struct{})
	errs := make(chan error, 2)
	go func() {
		<-start
		_, err := svc.AcquirePetStyle(context.Background(), actor, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000110", 309))
		errs <- err
	}()
	go func() {
		<-start
		_, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000111", 310))
		errs <- err
	}()
	close(start)
	e1, e2 := <-errs, <-errs
	rejected := 0
	for _, err := range []error{e1, e2} {
		if err != nil {
			if errors.Is(err, ErrPetAppearanceUnavailable) {
				rejected++
			} else {
				t.Fatal(err)
			}
		}
	}
	got := st.pet(11)
	c, a := st.saveCounts()
	if mat.count(ca75StyleA) != 1 || c != 1 || len(st.styleRows(11)) != 1 {
		t.Fatalf("debit=%d composite=%d rows=%v", mat.count(ca75StyleA), c, st.styleRows(11))
	}
	if rejected == 1 {
		if got.ActiveStyle != 0 || got.StateVersion != 5 || a != 0 {
			t.Fatalf("select-first reject final=%+v activeSaves=%d", got, a)
		}
	} else {
		if got.ActiveStyle != ca75StyleA || got.StateVersion != 6 || a != 1 {
			t.Fatalf("acquire-first final=%+v activeSaves=%d errs=%v/%v", got, a, e1, e2)
		}
	}
}

// Cross-Pet proof uses a lock registry rather than the same-pet mutex above.
type ca75MultiTx struct {
	mu       sync.Mutex
	commits  []func()
	locks    []*sync.Mutex
	locked   map[int64]bool
	registry *ca75LockRegistry
}

func (t *ca75MultiTx) QueryRow(context.Context, string, ...any) tx.Row { return caRow{} }
func (t *ca75MultiTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return caTag(1), nil
}
func (t *ca75MultiTx) stage(fn func()) { t.mu.Lock(); t.commits = append(t.commits, fn); t.mu.Unlock() }
func (t *ca75MultiTx) lockPet(id int64) {
	t.mu.Lock()
	if t.locked == nil {
		t.locked = map[int64]bool{}
	}
	if t.locked[id] {
		t.mu.Unlock()
		return
	}
	t.locked[id] = true
	t.mu.Unlock()
	m := t.registry.get(id)
	m.Lock()
	t.mu.Lock()
	t.locks = append(t.locks, m)
	t.mu.Unlock()
}
func (t *ca75MultiTx) release() {
	t.mu.Lock()
	ls := append([]*sync.Mutex(nil), t.locks...)
	t.locks = nil
	t.mu.Unlock()
	for i := len(ls) - 1; i >= 0; i-- {
		ls[i].Unlock()
	}
}
func (t *ca75MultiTx) Commit(context.Context) error {
	t.mu.Lock()
	fns := append([]func(){}, t.commits...)
	t.mu.Unlock()
	for _, fn := range fns {
		fn()
	}
	t.release()
	return nil
}
func (t *ca75MultiTx) Rollback(context.Context) error { t.release(); return nil }

type ca75LockRegistry struct {
	mu sync.Mutex
	m  map[int64]*sync.Mutex
}

func (r *ca75LockRegistry) get(id int64) *sync.Mutex {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.m == nil {
		r.m = map[int64]*sync.Mutex{}
	}
	if r.m[id] == nil {
		r.m[id] = &sync.Mutex{}
	}
	return r.m[id]
}

type ca75MultiDB struct{ reg *ca75LockRegistry }

func (d ca75MultiDB) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return &ca75MultiTx{registry: d.reg}, nil
}

type ca75MultiStore struct{ *ca75AtomicStore }

func (s *ca75MultiStore) LockPetByIDTx(_ context.Context, t tx.Tx, pid identity.PlayerID, id int64) (character.Pet, bool, error) {
	mt, ok := t.(*ca75MultiTx)
	if !ok {
		return character.Pet{}, false, errors.New("multi tx expected")
	}
	mt.lockPet(id)
	s.mu.Lock()
	defer s.mu.Unlock()
	p, found := s.byID[id]
	if found && p.PlayerID != pid {
		return character.Pet{}, false, nil
	}
	return p, found, nil
}
func (s *ca75MultiStore) SavePetAppearanceMutationTx(_ context.Context, t tx.Tx, p character.Pet, ent *character.PetStyleEntitlement, old int64) error {
	mt, ok := t.(*ca75MultiTx)
	if !ok {
		return errors.New("multi tx expected")
	}
	s.mu.Lock()
	cur, found := s.byID[p.PetID]
	s.mu.Unlock()
	if !found || cur.StateVersion != old || p.StateVersion != old+1 {
		return errors.New("bad multi version")
	}
	mt.stage(func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		s.byID[p.PetID] = p
		if ent != nil {
			s.ents[p.PetID] = append(s.ents[p.PetID], *ent)
		}
		s.compositeSaves++
	})
	return nil
}
func (s *ca75MultiStore) SavePetActiveStyleTx(_ context.Context, t tx.Tx, p character.Pet, old int64) error {
	mt, ok := t.(*ca75MultiTx)
	if !ok {
		return errors.New("multi tx expected")
	}
	mt.stage(func() { s.mu.Lock(); s.byID[p.PetID] = p; s.activeStyleSaves++; s.mu.Unlock() })
	return nil
}

type ca75MultiReceipts struct {
	mu sync.Mutex
	m  map[receipt.Identity]receipt.Receipt
}

func (r *ca75MultiReceipts) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, v := range r.m {
		_ = v
	}
	return receipt.Receipt{}, false, nil
}
func (r *ca75MultiReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	v, ok := r.m[id]
	return v, ok, nil
}
func (r *ca75MultiReceipts) PutTx(_ context.Context, t tx.Tx, x receipt.Receipt) (receipt.PutResult, error) {
	mt, ok := t.(*ca75MultiTx)
	if !ok {
		return receipt.PutResult{}, errors.New("multi tx expected")
	}
	r.mu.Lock()
	old, exists := r.m[x.Identity]
	r.mu.Unlock()
	if exists {
		return receipt.PutResult{Receipt: old}, nil
	}
	mt.stage(func() { r.mu.Lock(); r.m[x.Identity] = x; r.mu.Unlock() })
	return receipt.PutResult{Receipt: x, Inserted: true}, nil
}

type ca75BarrierMaterial struct {
	mu      sync.Mutex
	reached int
	release chan struct{}
	debits  map[int64]int
}

func newCA75BarrierMaterial() *ca75BarrierMaterial {
	return &ca75BarrierMaterial{release: make(chan struct{}), debits: map[int64]int{}}
}
func (m *ca75BarrierMaterial) DebitMaterialCostTx(_ context.Context, t tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	mt, ok := t.(*ca75MultiTx)
	if !ok {
		return appi5.MaterialDebitResult{}, errors.New("multi tx expected")
	}
	item := cost.Stacks[0].ItemID
	m.mu.Lock()
	m.reached++
	if m.reached == 2 {
		close(m.release)
	}
	ch := m.release
	m.mu.Unlock()
	<-ch
	mt.stage(func() { m.mu.Lock(); m.debits[item]++; m.mu.Unlock() })
	return appi5.MaterialDebitResult{}, nil
}

func TestCA75CrossPetAcquireHoldsSeparatePetLocksBeforeI5(t *testing.T) {
	p1 := ca75Pet(11, ca75PetOriginA, 0, 4)
	p2 := ca75Pet(12, ca75PetOriginB, 0, 7)
	base := &ca75AtomicStore{caStore: &caStore{byID: map[int64]character.Pet{11: p1, 12: p2}}, ents: map[int64][]character.PetStyleEntitlement{}}
	st := &ca75MultiStore{ca75AtomicStore: base}
	rec := &ca75MultiReceipts{m: map[receipt.Identity]receipt.Receipt{}}
	mat := newCA75BarrierMaterial()
	reg := &ca75LockRegistry{}
	svc := Service{Runner: tx.Runner{DB: ca75MultiDB{reg}}, Store: st, Fencer: caFence{}, Receipts: rec, ReceiptRead: rec, MaterialCosts: mat, AppearanceStore: st, Appearance: ca75ContentFixture(), AppearanceMutationStore: st}
	actor := caActor(t)
	start := make(chan struct{})
	errs := make(chan error, 2)
	go func() {
		<-start
		_, err := svc.AcquirePetStyle(context.Background(), actor, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000112", 311))
		errs <- err
	}()
	go func() {
		<-start
		_, err := svc.AcquirePetStyle(context.Background(), actor, ca75StyleOther, caOp(t, "75000000-0000-4000-8000-000000000113", 312))
		errs <- err
	}()
	close(start)
	if err := <-errs; err != nil {
		t.Fatal(err)
	}
	if err := <-errs; err != nil {
		t.Fatal(err)
	}
	mat.mu.Lock()
	reached := mat.reached
	d1, d2 := mat.debits[ca75StyleA], mat.debits[ca75StyleOther]
	mat.mu.Unlock()
	if reached != 2 || d1 != 1 || d2 != 1 || st.pet(11).StateVersion != 5 || st.pet(12).StateVersion != 8 {
		t.Fatalf("reached=%d debits=%d/%d p1=%+v p2=%+v", reached, d1, d2, st.pet(11), st.pet(12))
	}
}

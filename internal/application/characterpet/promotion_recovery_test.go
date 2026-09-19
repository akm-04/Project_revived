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

type petPromotionAtomicStrict struct {
	mu      sync.Mutex
	applied int
	prepErr error
}

func (s *petPromotionAtomicStrict) PrepareStrictRestorationTx(_ context.Context, _ tx.Tx, _ identity.ActorContext, _ appi5.StrictRestorationRequest, _ operation.Context) (*appi5.PreparedStrictRestoration, error) {
	if s.prepErr != nil {
		return nil, s.prepErr
	}
	return &appi5.PreparedStrictRestoration{}, nil
}
func (s *petPromotionAtomicStrict) ApplyStrictRestorationTx(_ context.Context, t tx.Tx, _ *appi5.PreparedStrictRestoration) (appi5.GrantResult, error) {
	at, ok := t.(*ca4aAtomicTx)
	if !ok {
		return appi5.GrantResult{}, errors.New("test promotion restoration: unexpected tx")
	}
	at.stage(func() {
		s.mu.Lock()
		s.applied++
		s.mu.Unlock()
	})
	return appi5.GrantResult{Awards: []appi5.Award{{TableID: 50001007, ItemNum: 1}}}, nil
}
func (s *petPromotionAtomicStrict) count() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.applied
}

type missingPetPromotionReceiptReader struct{}

func (missingPetPromotionReceiptReader) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

func configureAtomicPetPromotion(t *testing.T, commitErr error, failReceipt bool) (Service, *caStore, *ca4aAtomicReceipts, *petPromotionAtomicStrict) {
	t.Helper()
	svc, base, eq, _ := petPromotionFixture(t)
	store := &ca4aAtomicStore{caStore: base}
	rec := newCA4AAtomicReceipts()
	rec.failPut = failReceipt
	strict := &petPromotionAtomicStrict{}
	svc.Runner = tx.Runner{DB: ca4aAtomicDB{commitErr: commitErr}}
	svc.Store = store
	svc.Receipts = rec
	svc.ReceiptRead = rec
	svc.StrictRestoration = strict
	svc.Equipment = eq
	return svc, base, rec, strict
}

func TestPetAdvanceLateOuterReceiptFailureRollsBackStateAndRestoration(t *testing.T) {
	svc, base, rec, strict := configureAtomicPetPromotion(t, nil, true)
	before := base.byID[1]
	_, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "61616161-6161-4161-8161-616161616161", 4200))
	if err == nil || err.Error() != "test receipt write failure" {
		t.Fatalf("err=%v", err)
	}
	if got := base.byID[1]; got != before {
		t.Fatalf("Pet state escaped rollback: before=%+v after=%+v", before, got)
	}
	if strict.count() != 0 || len(rec.m) != 0 {
		t.Fatalf("nested restoration/receipt escaped rollback: restoration=%d receipts=%d", strict.count(), len(rec.m))
	}
}

func TestPetAdvanceAmbiguousCommitOuterReceiptReconcilesWithoutReapply(t *testing.T) {
	svc, base, rec, strict := configureAtomicPetPromotion(t, errors.New("transport lost after commit"), false)
	op := caOp(t, "62626262-6262-4262-8262-626262626262", 4201)
	got, err := svc.Advance(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.ToColor != 2 || !got.Replayed || base.byID[1].Color != 2 || strict.count() != 1 || len(rec.m) != 1 {
		t.Fatalf("reconciled=%+v pet=%+v restoration=%d receipts=%d", got, base.byID[1], strict.count(), len(rec.m))
	}
	version := base.byID[1].StateVersion
	got2, err := svc.Advance(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got2.Replayed || base.byID[1].StateVersion != version || strict.count() != 1 {
		t.Fatalf("replay mutated again: got=%+v version=%d/%d restoration=%d", got2, base.byID[1].StateVersion, version, strict.count())
	}
}

func TestPetAdvanceAmbiguousCommitWithoutOuterReceiptIsUnknownNoBlindReplay(t *testing.T) {
	svc, base, _, strict := configureAtomicPetPromotion(t, errors.New("transport lost after commit"), false)
	svc.ReceiptRead = missingPetPromotionReceiptReader{}
	_, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "63636363-6363-4363-8363-636363636363", 4202))
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatalf("err=%T %v", err, err)
	}
	if base.byID[1].Color != 2 || base.byID[1].StateVersion != 2 || strict.count() != 1 {
		t.Fatalf("ambiguous committed state=%+v restoration=%d", base.byID[1], strict.count())
	}
}

func TestPetAdvancePreexistingNestedRestorationWithoutOuterFailsClosed(t *testing.T) {
	svc, st, _, strict := petPromotionFixture(t)
	strict.prepErr = appi5.ErrStrictRestorationAlreadySettled
	before := st.byID[1]
	_, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "64646464-6464-4464-8464-646464646464", 4203))
	if !errors.Is(err, appi5.ErrStrictRestorationAlreadySettled) || st.byID[1] != before || strict.applyN != 0 {
		t.Fatalf("err=%v pet=%+v apply=%d", err, st.byID[1], strict.applyN)
	}
}

func TestPetAdvanceConcurrentSamePetSerializesSingleTransition(t *testing.T) {
	svc, base, eq, _ := petPromotionFixture(t)
	p := base.byID[1]
	// After the first color-1 promotion, the ordinary slot is clear. Supplying
	// valid color-2 topology makes the second request revalidate and reject on
	// prerequisites rather than failing because test content is incomplete.
	eq.positions[[3]int64{p.TableID, 2, 1}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 1, ItemID: 80001003, Classification: character.PetEquipmentOrdinary}
	eq.positions[[3]int64{p.TableID, 2, 2}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 2, ItemID: 90001002, Classification: character.PetEquipmentAwakening}
	eq.positions[[3]int64{p.TableID, 2, 3}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 3, Classification: character.PetEquipmentEmpty}

	store := &ca4aAtomicStore{caStore: base}
	rec := newCA4AAtomicReceipts()
	strict := &petPromotionAtomicStrict{}
	var petMu sync.Mutex
	svc.Runner = tx.Runner{DB: ca4aAtomicDB{petMu: &petMu}}
	svc.Store = store
	svc.Receipts = rec
	svc.ReceiptRead = rec
	svc.StrictRestoration = strict
	svc.Equipment = eq
	svc.Progression = ca4aConcurrentProgression{rev: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}

	type result struct {
		got AdvanceResult
		err error
	}
	start := make(chan struct{})
	out := make(chan result, 2)
	ops := []operation.Context{
		caOp(t, "65656565-6565-4565-8565-656565656565", 4204),
		caOp(t, "66666666-6666-4666-8666-666666666666", 4205),
	}
	for _, op := range ops {
		op := op
		go func() {
			<-start
			got, err := svc.Advance(context.Background(), caActor(t), 1, op)
			out <- result{got: got, err: err}
		}()
	}
	close(start)
	r1, r2 := <-out, <-out
	success, rejected := 0, 0
	for _, r := range []result{r1, r2} {
		switch {
		case r.err == nil:
			success++
			if r.got.FromColor != 1 || r.got.ToColor != 2 {
				t.Fatalf("unexpected successful transition=%+v", r.got)
			}
		case errors.Is(r.err, ErrPetPromotionPrerequisites):
			rejected++
		default:
			t.Fatalf("unexpected concurrent err=%v result=%+v", r.err, r.got)
		}
	}
	if success != 1 || rejected != 1 || base.byID[1].Color != 2 || base.byID[1].StateVersion != 2 || strict.count() != 1 {
		t.Fatalf("success=%d rejected=%d pet=%+v restoration=%d", success, rejected, base.byID[1], strict.count())
	}
}

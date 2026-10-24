package i5

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type exchangeContent struct {
	*testContent
	stackDefs map[int64]economy.StackDefinition
}

func (c *exchangeContent) ResolveResourceTx(ctx context.Context, q tx.Queryer, revision string, line grant.Line) (ResourcePolicy, error) {
	if line.Kind == grant.StackItem {
		def, ok := c.stackDefs[line.ItemID]
		if !ok {
			return ResourcePolicy{}, economy.ErrUnknownResource
		}
		return ResourcePolicy{Kind: grant.StackItem, WireTableID: line.ItemID, Stack: &def, PolicyVersion: revision}, nil
	}
	return c.testContent.ResolveResourceTx(ctx, q, revision, line)
}

type exchangeStore struct {
	*testStore
	stacks map[int64]economy.StackState
}

func (s *exchangeStore) LockStackTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, itemID int64, _ time.Time) (economy.StackState, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, fmt.Sprintf("stack:%d", itemID))
	st, ok := s.stacks[itemID]
	if !ok || st.PlayerID != pid {
		return economy.StackState{}, false, nil
	}
	return st, true, nil
}

func (s *exchangeStore) SaveStackTx(_ context.Context, _ tx.Tx, st economy.StackState, _ bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.stacks == nil {
		s.stacks = map[int64]economy.StackState{}
	}
	s.stacks[st.ItemID] = st
	s.saveStackCalls++
	return nil
}

func (s *exchangeStore) DeleteStackTx(_ context.Context, _ tx.Tx, st economy.StackState) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.stacks, st.ItemID)
	s.deleteStackCalls++
	return nil
}

func exchangeStack(pid identity.PlayerID, itemID, qty int64, now time.Time) economy.StackState {
	return economy.StackState{PlayerID: pid, ItemID: itemID, Quantity: qty, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
}

func exchangePlan(pid identity.PlayerID, itemID, amount int64, key string) grant.Plan {
	return grant.Plan{
		PlayerID: pid,
		Source:   grant.SourceIdentity{Domain: "character.hero", Operation: "promotion-restore", BusinessKey: key, Occurrence: "color:1->2", PolicyVersion: "ca4-test"},
		Lines:    []grant.Line{{Kind: grant.StackItem, ItemID: itemID, Amount: amount}},
	}
}

func exchangeService(t *testing.T) (Service, *exchangeStore, *memoryReceipts, identity.ActorContext, operationFixture) {
	t.Helper()
	actor := testActor(t)
	now := time.Unix(1700000100, 0).UTC()
	base := &testStore{policies: map[grant.LineKind]ResourcePolicy{}}
	store := &exchangeStore{testStore: base, stacks: map[int64]economy.StackState{
		100: exchangeStack(actor.PlayerID, 100, 5, now),
		200: exchangeStack(actor.PlayerID, 200, 1, now),
	}}
	content := &exchangeContent{testContent: &testContent{policies: map[grant.LineKind]ResourcePolicy{}}, stackDefs: map[int64]economy.StackDefinition{
		100: {ItemID: 100, StackCap: 99, OverflowToMail: true},
		200: {ItemID: 200, StackCap: 99, OverflowToMail: true},
	}}
	rs := newMemoryReceipts()
	svc := Service{Store: store, Content: content, Receipts: rs, ReceiptRead: rs}
	return svc, store, rs, actor, operationFixture{revision: testContentRevisionA}
}

// operationFixture keeps CA4 exchange tests explicit about the pinned immutable
// content revision rather than relying on active-content lookup.
type operationFixture struct{ revision string }

func (f operationFixture) op(t *testing.T, n byte) operation.Context {
	t.Helper()
	return mustBindTestContent(t, testOperation(n), f.revision)
}

func TestMaterialExchangePrepareApplyAtomicallyComposesDebitAndRestoration(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	req := MaterialExchangeRequest{
		Cost:              MaterialCost{Stacks: []StackMaterialCost{{ItemID: 100, Amount: 2}}},
		Restoration:       exchangePlan(actor.PlayerID, 200, 3, "partner:77"),
		AllowOverflowMail: true,
	}
	prepared, err := svc.PrepareMaterialExchangeTx(context.Background(), &testTx{}, actor, req, fixture.op(t, 31))
	if err != nil {
		t.Fatal(err)
	}
	if got := store.stacks[100].Quantity; got != 5 {
		t.Fatalf("prepare mutated debit stack: %d", got)
	}
	if got := store.stacks[200].Quantity; got != 1 {
		t.Fatalf("prepare mutated restoration stack: %d", got)
	}
	res, err := svc.ApplyMaterialExchangeTx(context.Background(), &testTx{}, prepared)
	if err != nil {
		t.Fatal(err)
	}
	if got := store.stacks[100].Quantity; got != 3 {
		t.Fatalf("debit quantity=%d", got)
	}
	if got := store.stacks[200].Quantity; got != 4 {
		t.Fatalf("restoration quantity=%d", got)
	}
	if len(res.Debit.Stacks) != 1 || len(res.Restoration.Awards) != 1 || res.Restoration.ReceiptID == "" {
		t.Fatalf("bad result: %#v", res)
	}
}

func TestMaterialExchangeRejectsCrossSideCollisionBeforeWrites(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	req := MaterialExchangeRequest{
		Cost:              MaterialCost{Stacks: []StackMaterialCost{{ItemID: 100, Amount: 1}}},
		Restoration:       exchangePlan(actor.PlayerID, 100, 1, "partner:77"),
		AllowOverflowMail: true,
	}
	_, err := svc.PrepareMaterialExchangeTx(context.Background(), &testTx{}, actor, req, fixture.op(t, 32))
	if !errors.Is(err, ErrMaterialExchangeResourceCollision) {
		t.Fatalf("err=%v", err)
	}
	if store.stacks[100].Quantity != 5 || store.saveStackCalls != 0 || store.deleteStackCalls != 0 {
		t.Fatal("collision mutated state")
	}
}

func TestMaterialExchangeExistingNestedGrantFailsBeforeDebit(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	plan := exchangePlan(actor.PlayerID, 200, 1, "partner:77")
	if _, err := svc.SettleGrantTx(context.Background(), &testTx{}, actor, plan, fixture.op(t, 33), GrantTxOptions{AllowOverflowMail: true}); err != nil {
		t.Fatal(err)
	}
	before := store.stacks[100].Quantity
	req := MaterialExchangeRequest{Cost: MaterialCost{Stacks: []StackMaterialCost{{ItemID: 100, Amount: 1}}}, Restoration: plan, AllowOverflowMail: true}
	_, err := svc.PrepareMaterialExchangeTx(context.Background(), &testTx{}, actor, req, fixture.op(t, 34))
	if !errors.Is(err, ErrMaterialExchangeGrantAlreadySettled) {
		t.Fatalf("err=%v", err)
	}
	if store.stacks[100].Quantity != before {
		t.Fatal("existing nested receipt allowed debit")
	}
}

func TestMaterialExchangePrepareCanonicalizesInterleavedDebitAndGrantLocks(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	// Debit 200 while restoring 100: source ids intentionally oppose call-side
	// ordering. D01 requires the complete union to respect global ranks first
	// (Mail 610, Economy owner 700) and then stack identity order (722).
	req := MaterialExchangeRequest{
		Cost:              MaterialCost{Stacks: []StackMaterialCost{{ItemID: 200, Amount: 1}}},
		Restoration:       exchangePlan(actor.PlayerID, 100, 1, "partner:77"),
		AllowOverflowMail: true,
	}
	txv := &testTx{}
	if _, err := svc.PrepareMaterialExchangeTx(context.Background(), txv, actor, req, fixture.op(t, 35)); err != nil {
		t.Fatal(err)
	}
	store.mu.Lock()
	trace := append([]string(nil), store.lockTrace...)
	store.mu.Unlock()
	wantPrefix := []string{"mail:NORMAL", "economy-owner", "stack:100", "stack:200"}
	if len(trace) < len(wantPrefix) {
		t.Fatalf("lock trace too short: %v", trace)
	}
	for i, want := range wantPrefix {
		if trace[i] != want {
			t.Fatalf("lock[%d]=%q want %q trace=%v", i, trace[i], want, trace)
		}
	}
}

func TestMaterialExchangeOverflowMailIsPlannedBeforeMutationAndAppliedByGrant(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	store.stacks[200] = exchangeStack(actor.PlayerID, 200, 98, time.Unix(1700000100, 0).UTC())
	req := MaterialExchangeRequest{
		Cost:              MaterialCost{Stacks: []StackMaterialCost{{ItemID: 100, Amount: 1}}},
		Restoration:       exchangePlan(actor.PlayerID, 200, 3, "partner:77"),
		AllowOverflowMail: true,
	}
	txv := &testTx{}
	prepared, err := svc.PrepareMaterialExchangeTx(context.Background(), txv, actor, req, fixture.op(t, 36))
	if err != nil {
		t.Fatal(err)
	}
	if store.stacks[100].Quantity != 5 || store.stacks[200].Quantity != 98 || len(store.insertedMail) != 0 {
		t.Fatal("prepare performed canonical writes")
	}
	store.mu.Lock()
	trace := append([]string(nil), store.lockTrace...)
	store.mu.Unlock()
	if len(trace) < 3 || trace[0] != "mail:NORMAL" || trace[1] != "economy-owner" {
		t.Fatalf("overflow Mail lock was not planned before economy/stack locks: %v", trace)
	}
	if _, err := svc.ApplyMaterialExchangeTx(context.Background(), txv, prepared); err != nil {
		t.Fatal(err)
	}
	if got := store.stacks[100].Quantity; got != 4 {
		t.Fatalf("debit quantity=%d", got)
	}
	if got := store.stacks[200].Quantity; got != 99 {
		t.Fatalf("restored stack quantity=%d", got)
	}
	if len(store.insertedMail) != 1 || len(store.insertedMail[0].Attachments) != 1 || store.insertedMail[0].Attachments[0].Line.Amount != 2 {
		t.Fatalf("overflow mail mismatch: %#v", store.insertedMail)
	}
}

func TestMaterialExchangePreparedReplayCannotDoubleDebitOrCredit(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	req := MaterialExchangeRequest{
		Cost:              MaterialCost{Stacks: []StackMaterialCost{{ItemID: 100, Amount: 1}}},
		Restoration:       exchangePlan(actor.PlayerID, 200, 1, "partner:77"),
		AllowOverflowMail: true,
	}
	txv := &testTx{}
	prepared, err := svc.PrepareMaterialExchangeTx(context.Background(), txv, actor, req, fixture.op(t, 37))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.ApplyMaterialExchangeTx(context.Background(), txv, prepared); err != nil {
		t.Fatal(err)
	}
	debitAfter, creditAfter := store.stacks[100].Quantity, store.stacks[200].Quantity
	if _, err := svc.ApplyMaterialExchangeTx(context.Background(), txv, prepared); !errors.Is(err, ErrMaterialExchangeGrantAlreadySettled) {
		t.Fatalf("replay err=%v", err)
	}
	if store.stacks[100].Quantity != debitAfter || store.stacks[200].Quantity != creditAfter {
		t.Fatalf("prepared replay duplicated effects: debit %d->%d credit %d->%d", debitAfter, store.stacks[100].Quantity, creditAfter, store.stacks[200].Quantity)
	}
}

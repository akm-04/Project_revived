package i5

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type heroEquipmentTestContent struct{ *testContent }

func (c *heroEquipmentTestContent) ResolveResourceTx(ctx context.Context, q tx.Queryer, revision string, line grant.Line) (ResourcePolicy, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.seenRevisions = append(c.seenRevisions, revision)
	c.resolveCalls++
	switch line.Kind {
	case grant.ScalarCurrency:
		if line.ResourceKey != "mana" {
			return ResourcePolicy{}, economy.ErrUnknownResource
		}
		return ResourcePolicy{Kind: grant.ScalarCurrency, PolicyVersion: revision}, nil
	case grant.StackItem:
		if line.ItemID <= 0 {
			return ResourcePolicy{}, economy.ErrUnknownResource
		}
		return ResourcePolicy{Kind: grant.StackItem, Stack: &economy.StackDefinition{ItemID: line.ItemID, StackCap: 999999}, PolicyVersion: revision}, nil
	default:
		return ResourcePolicy{}, economy.ErrUnknownResource
	}
}

type heroEquipmentTestStore struct {
	*testStore
	stacks map[int64]economy.StackState
}

func (s *heroEquipmentTestStore) LockStackTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, itemID int64, _ time.Time) (economy.StackState, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, fmt.Sprintf("stack:%d", itemID))
	st, ok := s.stacks[itemID]
	if !ok || st.PlayerID != pid {
		return economy.StackState{}, false, nil
	}
	return st, true, nil
}

func (s *heroEquipmentTestStore) SaveStackTx(_ context.Context, _ tx.Tx, st economy.StackState, _ bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	old, ok := s.stacks[st.ItemID]
	if !ok || old.StateVersion != st.StateVersion-1 {
		return errors.New("stack optimistic conflict")
	}
	s.stacks[st.ItemID] = st
	s.saveStackCalls++
	return nil
}

func (s *heroEquipmentTestStore) DeleteStackTx(_ context.Context, _ tx.Tx, st economy.StackState) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	old, ok := s.stacks[st.ItemID]
	if !ok || old.StateVersion != st.StateVersion-1 {
		return errors.New("stack delete optimistic conflict")
	}
	delete(s.stacks, st.ItemID)
	s.deleteStackCalls++
	return nil
}

func heroEquipmentFixture(t *testing.T) (HeroEquipmentResourceDebiter, *heroEquipmentTestStore, *heroEquipmentTestContent, identity.PlayerID, operation.Context) {
	t.Helper()
	now := time.Unix(1701000000, 0).UTC()
	pid := identity.PlayerID(77)
	base := &testStore{
		scalar:       economy.ScalarBalance{PlayerID: pid, ResourceKey: "mana", Amount: 1000, StateVersion: 3, UpdatedAt: now.Add(-time.Hour)},
		scalarExists: true,
		progression:  testPlayerProgression(pid, 80, now),
	}
	store := &heroEquipmentTestStore{testStore: base, stacks: map[int64]economy.StackState{
		100: testHeroEquipmentStack(pid, 100, 5, now),
		20:  testHeroEquipmentStack(pid, 20, 7, now),
	}}
	content := &heroEquipmentTestContent{testContent: &testContent{}}
	op := mustBindTestContent(t, operation.Context{ID: testUUID(201), StartedAt: now}, testContentRevisionA)
	return HeroEquipmentResourceDebiter{Store: store, Content: content}, store, content, pid, op
}

func testPlayerProgression(pid identity.PlayerID, level int64, now time.Time) player.Progression {
	return player.Progression{PlayerID: pid, Level: level, Exp: 0, StateVersion: 1, UpdatedAt: now.Add(-time.Minute)}
}

func testHeroEquipmentStack(pid identity.PlayerID, itemID, qty int64, now time.Time) economy.StackState {
	return economy.StackState{PlayerID: pid, ItemID: itemID, Quantity: qty, StateVersion: 2, AcquiredAt: now.Add(-24 * time.Hour), UpdatedAt: now.Add(-time.Hour)}
}

func TestHeroEquipmentPrepareLocksCanonicalSuffixAndSnapshotsAbsentStacks(t *testing.T) {
	d, store, content, pid, op := heroEquipmentFixture(t)
	plan, err := d.PrepareHeroEquipmentResourcesTx(context.Background(), &testTx{}, pid, HeroEquipmentResourceRequest{PotentialStackItemIDs: []int64{100, 3, 20}}, op)
	if err != nil {
		t.Fatal(err)
	}
	if got := plan.PlayerLevel(); got != 80 {
		t.Fatalf("level=%d", got)
	}
	if got := plan.Mana(); got != 1000 {
		t.Fatalf("mana=%d", got)
	}
	if got, ok := plan.StackQuantity(3); !ok || got != 0 {
		t.Fatalf("absent stack snapshot=(%d,%v)", got, ok)
	}
	if got, ok := plan.StackQuantity(20); !ok || got != 7 {
		t.Fatalf("stack20=(%d,%v)", got, ok)
	}
	wantIDs := []int64{100, 20, 3} // canonical decimal identity order
	if got := plan.PreparedStackItemIDs(); !reflect.DeepEqual(got, wantIDs) {
		t.Fatalf("ids=%v want %v", got, wantIDs)
	}
	wantLocks := []string{"economy-owner", "progression", "scalar:mana", "stack:100", "stack:20", "stack:3"}
	if !reflect.DeepEqual(store.lockTrace, wantLocks) {
		t.Fatalf("locks=%v want %v", store.lockTrace, wantLocks)
	}
	if content.resolveCalls != 4 { // three stack identities + Mana
		t.Fatalf("content resolve calls=%d", content.resolveCalls)
	}
	if store.saveScalarCalls != 0 || store.saveStackCalls != 0 || store.deleteStackCalls != 0 {
		t.Fatal("prepare performed writes")
	}
}

func TestHeroEquipmentApplyUsesPreparedSubsetWithoutNewReadOrLock(t *testing.T) {
	d, store, content, pid, op := heroEquipmentFixture(t)
	plan, err := d.PrepareHeroEquipmentResourcesTx(context.Background(), &testTx{}, pid, HeroEquipmentResourceRequest{PotentialStackItemIDs: []int64{20, 100, 3}}, op)
	if err != nil {
		t.Fatal(err)
	}
	locksBefore := append([]string(nil), store.lockTrace...)
	resolvesBefore := content.resolveCalls
	got, err := d.ApplyHeroEquipmentResourceDebitTx(context.Background(), &testTx{}, plan, HeroEquipmentResourceDebit{
		Mana:   250,
		Stacks: []HeroEquipmentStackDebit{{ItemID: 100, Count: 5}, {ItemID: 20, Count: 2}},
	})
	if err != nil {
		t.Fatal(err)
	}
	if got.PlayerLevel != 80 || got.Mana.Amount != 750 {
		t.Fatalf("result=%+v", got)
	}
	if len(store.lockTrace) != len(locksBefore) || !reflect.DeepEqual(store.lockTrace, locksBefore) {
		t.Fatalf("apply acquired locks: before=%v after=%v", locksBefore, store.lockTrace)
	}
	if content.resolveCalls != resolvesBefore {
		t.Fatalf("apply resolved content: before=%d after=%d", resolvesBefore, content.resolveCalls)
	}
	if _, ok := store.stacks[100]; ok {
		t.Fatal("fully consumed stack was not deleted")
	}
	if store.stacks[20].Quantity != 5 {
		t.Fatalf("stack20 qty=%d", store.stacks[20].Quantity)
	}
	if store.scalar.Amount != 750 {
		t.Fatalf("mana=%d", store.scalar.Amount)
	}
	if _, err := d.ApplyHeroEquipmentResourceDebitTx(context.Background(), &testTx{}, plan, HeroEquipmentResourceDebit{}); err == nil {
		t.Fatal("second apply unexpectedly accepted")
	}
}

func TestHeroEquipmentApplyRejectsOutsideClosureAbsentAndInsufficientWithoutWrites(t *testing.T) {
	tests := []struct {
		name  string
		debit HeroEquipmentResourceDebit
		want  error
	}{
		{name: "outside", debit: HeroEquipmentResourceDebit{Stacks: []HeroEquipmentStackDebit{{ItemID: 999, Count: 1}}}},
		{name: "absent", debit: HeroEquipmentResourceDebit{Stacks: []HeroEquipmentStackDebit{{ItemID: 3, Count: 1}}}, want: economy.ErrInsufficientBalance},
		{name: "mana", debit: HeroEquipmentResourceDebit{Mana: 1001}, want: economy.ErrInsufficientBalance},
		{name: "stack", debit: HeroEquipmentResourceDebit{Stacks: []HeroEquipmentStackDebit{{ItemID: 20, Count: 8}}}, want: economy.ErrInsufficientBalance},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			d, store, _, pid, op := heroEquipmentFixture(t)
			plan, err := d.PrepareHeroEquipmentResourcesTx(context.Background(), &testTx{}, pid, HeroEquipmentResourceRequest{PotentialStackItemIDs: []int64{20, 3}}, op)
			if err != nil {
				t.Fatal(err)
			}
			_, err = d.ApplyHeroEquipmentResourceDebitTx(context.Background(), &testTx{}, plan, tt.debit)
			if err == nil {
				t.Fatal("expected error")
			}
			if tt.want != nil && !errors.Is(err, tt.want) {
				t.Fatalf("err=%v want %v", err, tt.want)
			}
			if store.saveScalarCalls != 0 || store.saveStackCalls != 0 || store.deleteStackCalls != 0 {
				t.Fatal("failed apply performed writes")
			}
		})
	}
}

func TestHeroEquipmentZeroDebitIsValidAndEffectFree(t *testing.T) {
	d, store, content, pid, op := heroEquipmentFixture(t)
	plan, err := d.PrepareHeroEquipmentResourcesTx(context.Background(), &testTx{}, pid, HeroEquipmentResourceRequest{PotentialStackItemIDs: []int64{20, 3}}, op)
	if err != nil {
		t.Fatal(err)
	}
	locks := len(store.lockTrace)
	resolves := content.resolveCalls
	got, err := d.ApplyHeroEquipmentResourceDebitTx(context.Background(), &testTx{}, plan, HeroEquipmentResourceDebit{})
	if err != nil {
		t.Fatal(err)
	}
	if got.PlayerLevel != 80 || got.Mana.Amount != 1000 || len(got.Stacks) != 0 {
		t.Fatalf("result=%+v", got)
	}
	if len(store.lockTrace) != locks || content.resolveCalls != resolves || store.saveScalarCalls != 0 || store.saveStackCalls != 0 || store.deleteStackCalls != 0 {
		t.Fatal("zero debit had side effects")
	}
}

func TestHeroEquipmentPrepareRejectsDuplicateClosureIdentity(t *testing.T) {
	d, _, _, pid, op := heroEquipmentFixture(t)
	_, err := d.PrepareHeroEquipmentResourcesTx(context.Background(), &testTx{}, pid, HeroEquipmentResourceRequest{PotentialStackItemIDs: []int64{20, 20}}, op)
	if err == nil {
		t.Fatal("expected duplicate identity error")
	}
}

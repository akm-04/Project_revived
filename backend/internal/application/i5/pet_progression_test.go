package i5

import (
	"context"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type petExpTestStore struct {
	HeroProgressionStore
	events      []string
	progression player.Progression
	stacks      map[int64]economy.StackState
}

func (s *petExpTestStore) LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error {
	s.events = append(s.events, "lock:economy")
	return nil
}
func (s *petExpTestStore) LockProgressionTx(context.Context, tx.Tx, identity.PlayerID) (player.Progression, error) {
	s.events = append(s.events, "lock:progression")
	return s.progression, nil
}
func (s *petExpTestStore) LockScalarTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) (economy.ScalarBalance, bool, error) {
	return economy.ScalarBalance{}, false, fmt.Errorf("unexpected scalar lock")
}
func (s *petExpTestStore) SaveScalarTx(context.Context, tx.Tx, economy.ScalarBalance, bool) error {
	return fmt.Errorf("unexpected scalar write")
}
func (s *petExpTestStore) LockStackTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, id int64, _ time.Time) (economy.StackState, bool, error) {
	s.events = append(s.events, fmt.Sprintf("lock:stack:%d", id))
	st, ok := s.stacks[id]
	return st, ok, nil
}
func (s *petExpTestStore) SaveStackTx(_ context.Context, _ tx.Tx, st economy.StackState, _ bool) error {
	s.events = append(s.events, fmt.Sprintf("write:save:%d", st.ItemID))
	s.stacks[st.ItemID] = st
	return nil
}
func (s *petExpTestStore) DeleteStackTx(_ context.Context, _ tx.Tx, st economy.StackState) error {
	s.events = append(s.events, fmt.Sprintf("write:delete:%d", st.ItemID))
	delete(s.stacks, st.ItemID)
	return nil
}

type petExpTestContent struct{ ContentRuntime }

func (petExpTestContent) ResolveResourceTx(_ context.Context, _ tx.Queryer, _ string, line grant.Line) (ResourcePolicy, error) {
	if line.Kind != grant.StackItem || line.ItemID <= 0 || line.Amount <= 0 {
		return ResourcePolicy{}, economy.ErrUnknownResource
	}
	def := economy.StackDefinition{ItemID: line.ItemID}
	return ResourcePolicy{Kind: grant.StackItem, Stack: &def}, nil
}

type petExpTestTx struct{ tx.Tx }

func TestPetExpPrepareLocksWithoutWritingAndApplyWritesWithoutLocking(t *testing.T) {
	now := time.Unix(3000, 123).UTC()
	pid := identity.PlayerID(7)
	store := &petExpTestStore{
		progression: player.Progression{PlayerID: pid, Level: 42},
		stacks: map[int64]economy.StackState{
			50001087: {PlayerID: pid, ItemID: 50001087, Quantity: 5, StateVersion: 1, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Hour)},
			50001089: {PlayerID: pid, ItemID: 50001089, Quantity: 2, StateVersion: 1, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Hour)},
		},
	}
	set, err := policy.NewSet(policy.Ref{Name: "content", Version: testContentRevisionA})
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{StartedAt: now, Policies: set}
	d := PetExpDebiter{Store: store, Content: petExpTestContent{}}
	plan, err := d.PreparePetExpDebitTx(context.Background(), petExpTestTx{}, pid, []PetExpItemDebit{{ItemID: 50001089, Count: 1}, {ItemID: 50001087, Count: 2}}, op)
	if err != nil {
		t.Fatal(err)
	}
	wantLocks := []string{"lock:economy", "lock:progression", "lock:stack:50001087", "lock:stack:50001089"}
	if fmt.Sprint(store.events) != fmt.Sprint(wantLocks) {
		t.Fatalf("prepare events=%v want=%v", store.events, wantLocks)
	}
	if plan.PlayerLevel() != 42 {
		t.Fatalf("player level=%d", plan.PlayerLevel())
	}
	beforeApply := len(store.events)
	res, err := d.ApplyPetExpDebitTx(context.Background(), petExpTestTx{}, plan)
	if err != nil {
		t.Fatal(err)
	}
	if res.PlayerLevel != 42 || len(res.Stacks) != 2 {
		t.Fatalf("result=%+v", res)
	}
	for _, ev := range store.events[beforeApply:] {
		if len(ev) >= 5 && ev[:5] == "lock:" {
			t.Fatalf("apply acquired lock: %v", store.events)
		}
	}
	if store.stacks[50001087].Quantity != 3 || store.stacks[50001089].Quantity != 1 {
		t.Fatalf("stacks after apply=%+v", store.stacks)
	}
}

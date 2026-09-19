package i5

import (
	"context"
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

type petDebitStore struct {
	MaterialCostStore
	stacks map[int64]economy.StackState
}

func (s *petDebitStore) LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}
func (s *petDebitStore) LockStackTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, id int64, _ time.Time) (economy.StackState, bool, error) {
	st, ok := s.stacks[id]
	return st, ok, nil
}
func (s *petDebitStore) SaveStackTx(_ context.Context, _ tx.Tx, st economy.StackState, _ bool) error {
	s.stacks[st.ItemID] = st
	return nil
}
func (s *petDebitStore) DeleteStackTx(_ context.Context, _ tx.Tx, st economy.StackState) error {
	delete(s.stacks, st.ItemID)
	return nil
}

type petDebitContent struct{ ContentRuntime }

func (petDebitContent) ResolveResourceTx(_ context.Context, _ tx.Queryer, revision string, line grant.Line) (ResourcePolicy, error) {
	d := economy.StackDefinition{ItemID: line.ItemID, StackCap: 999, OverflowToMail: false}
	return ResourcePolicy{Kind: grant.StackItem, Stack: &d, PolicyVersion: revision}, nil
}

type noopTx struct{}

func (noopTx) QueryRow(context.Context, string, ...any) tx.Row             { return testRow{} }
func (noopTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return testTag(1), nil }
func (noopTx) Commit(context.Context) error                                { return nil }
func (noopTx) Rollback(context.Context) error                              { return nil }

func petDebitOp(t *testing.T) operation.Context {
	set, err := policy.NewSet(policy.Ref{Name: "content", Version: testContentRevisionA})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{StartedAt: time.Unix(100, 0).UTC(), Policies: set}
}
func TestPetAcquisitionDebitPrefersEgg(t *testing.T) {
	st := &petDebitStore{stacks: map[int64]economy.StackState{10: {PlayerID: 7, ItemID: 10, Quantity: 2, StateVersion: 1, AcquiredAt: time.Unix(1, 0), UpdatedAt: time.Unix(1, 0)}, 20: {PlayerID: 7, ItemID: 20, Quantity: 99, StateVersion: 1, AcquiredAt: time.Unix(1, 0), UpdatedAt: time.Unix(1, 0)}}}
	got, err := (PetAcquisitionDebiter{Store: st, Content: petDebitContent{}}).DebitPetAcquisitionTx(context.Background(), noopTx{}, 7, 10, 20, 10, petDebitOp(t))
	if err != nil {
		t.Fatal(err)
	}
	if !got.UsedEgg || got.ItemID != 10 || got.Count != 1 || st.stacks[10].Quantity != 1 || st.stacks[20].Quantity != 99 {
		t.Fatalf("got=%+v stacks=%+v", got, st.stacks)
	}
}
func TestPetAcquisitionDebitFallsBackToEssence(t *testing.T) {
	st := &petDebitStore{stacks: map[int64]economy.StackState{20: {PlayerID: 7, ItemID: 20, Quantity: 15, StateVersion: 1, AcquiredAt: time.Unix(1, 0), UpdatedAt: time.Unix(1, 0)}}}
	got, err := (PetAcquisitionDebiter{Store: st, Content: petDebitContent{}}).DebitPetAcquisitionTx(context.Background(), noopTx{}, 7, 10, 20, 10, petDebitOp(t))
	if err != nil {
		t.Fatal(err)
	}
	if got.UsedEgg || got.ItemID != 20 || got.Count != 10 || st.stacks[20].Quantity != 5 {
		t.Fatalf("got=%+v stacks=%+v", got, st.stacks)
	}
}

type starterContent struct{ ContentRuntime }

func (starterContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return testContentRevisionA, nil
}
func (starterContent) ResolveFunctionGatePolicyTx(context.Context, tx.Queryer, string) (FunctionGatePolicy, error) {
	return FunctionGatePolicy{Revision: testContentRevisionA, Gates: []FunctionGate{{FunctionID: 38, GateKind: "PURE_LEVEL", RequiredLevel: 40, RawOpenValue: "1|40", SourceFactKey: "function:38", AnnouncementCapability: "PET_STARTER_CA3"}}}, nil
}
func (starterContent) ResolvePetStarterPolicyTx(context.Context, tx.Queryer, string) (PetStarterPolicy, error) {
	return PetStarterPolicy{StarterEggItemID: 50001050}, nil
}
func (starterContent) ResolveResourceTx(_ context.Context, _ tx.Queryer, revision string, line grant.Line) (ResourcePolicy, error) {
	d := economy.StackDefinition{ItemID: line.ItemID, StackCap: 99}
	return ResourcePolicy{Kind: grant.StackItem, Stack: &d, PolicyVersion: revision}, nil
}

type starterStore struct {
	Store
	progression    player.Progression
	stack          economy.StackState
	stackExists    bool
	unlockInserted bool
	saved          bool
	advanced       bool
}

func (s *starterStore) ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error) {
	return s.progression, nil
}
func (*starterStore) LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error { return nil }
func (s *starterStore) LockStackTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) (economy.StackState, bool, error) {
	return s.stack, s.stackExists, nil
}
func (*starterStore) LockFunctionStateTx(context.Context, tx.Tx, identity.PlayerID) (int64, error) {
	return 1, nil
}
func (*starterStore) InsertFunctionEligibilityTx(context.Context, tx.Tx, player.FunctionEligibility) (bool, error) {
	return true, nil
}
func (s *starterStore) InsertFunctionUnlockTx(context.Context, tx.Tx, player.FunctionUnlock) (bool, error) {
	return s.unlockInserted, nil
}
func (s *starterStore) SaveStackTx(_ context.Context, _ tx.Tx, st economy.StackState, _ bool) error {
	s.stack = st
	s.saved = true
	return nil
}
func (s *starterStore) AdvanceFunctionStateTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) error {
	s.advanced = true
	return nil
}

func TestPetStarterLoginReconcilerEnsureOneOnlyOnNewUnlock(t *testing.T) {
	op := operation.Context{StartedAt: time.Unix(100, 0).UTC()}
	actor := identity.ActorContext{PlayerID: 7}
	s := &starterStore{progression: player.Progression{PlayerID: 7, Level: 40, Exp: 0, StateVersion: 1, UpdatedAt: time.Unix(1, 0)}, unlockInserted: true}
	r := PetStarterLoginReconciler{Store: s, Content: starterContent{}}
	if err := r.ReconcileCharacterLogin(context.Background(), noopTx{}, actor, op); err != nil {
		t.Fatal(err)
	}
	if !s.saved || s.stack.Quantity != 1 || !s.advanced {
		t.Fatalf("store=%+v", s)
	}
	s2 := &starterStore{progression: s.progression, unlockInserted: false}
	if err := r.ReconcileCharacterLogin(context.Background(), noopTx{}, actor, op); err != nil {
		t.Fatal(err)
	}
	if s2.saved {
		t.Fatal("existing unlock regranted starter egg")
	}
}

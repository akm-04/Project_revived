package characterpet

import (
	"context"
	"errors"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type petEquipmentTestContent struct {
	positions     map[[3]int64]character.PetEquipmentPosition
	primitives    map[int64]character.EquipmentPrimitive
	edges         map[int64][]character.EquipmentRecipeEdge
	compatibility []character.EquipmentCompatibilityExpThreshold
	awakened      map[int64]bool
}

func (petEquipmentTestContent) PetEquipmentRevision(context.Context, string) (bool, error) {
	return true, nil
}
func (petEquipmentTestContent) EquipmentPrimitivesRevision(context.Context, string) (bool, error) {
	return true, nil
}
func (c petEquipmentTestContent) PetEquipmentPositionTx(_ context.Context, _ tx.Queryer, _ string, table, color, slot int64) (character.PetEquipmentPosition, error) {
	p, ok := c.positions[[3]int64{table, color, slot}]
	if !ok {
		return character.PetEquipmentPosition{}, errors.New("missing Pet equipment position")
	}
	return p, nil
}
func (c petEquipmentTestContent) EquipmentPrimitiveTx(_ context.Context, _ tx.Queryer, _ string, itemID int64) (character.EquipmentPrimitive, error) {
	p, ok := c.primitives[itemID]
	if !ok {
		return character.EquipmentPrimitive{}, errors.New("missing equipment primitive")
	}
	return p, nil
}
func (c petEquipmentTestContent) EquipmentRecipeEdgesTx(_ context.Context, _ tx.Queryer, _ string, itemID int64) ([]character.EquipmentRecipeEdge, error) {
	return append([]character.EquipmentRecipeEdge(nil), c.edges[itemID]...), nil
}
func (c petEquipmentTestContent) EquipmentCompatibilityExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]character.EquipmentCompatibilityExpThreshold, error) {
	return append([]character.EquipmentCompatibilityExpThreshold(nil), c.compatibility...), nil
}
func (c petEquipmentTestContent) PetTemplateAwakenedTx(_ context.Context, _ tx.Queryer, _ string, tableID int64) (bool, error) {
	return c.awakened[tableID], nil
}

func petEquipmentFixture(t *testing.T, classification character.PetEquipmentClassification, awakened bool) (Service, *caStore, *caMaterial, *caReceipts, *petEquipmentTestContent) {
	t.Helper()
	svc, st, prog, mat, _ := progressionFixture(t)
	p := st.byID[1]
	p.Level = 2
	p.Exp = 25
	p.Color = 1
	st.byID[1] = p
	prog.maxLevel = 2
	content := &petEquipmentTestContent{
		positions: map[[3]int64]character.PetEquipmentPosition{},
		primitives: map[int64]character.EquipmentPrimitive{
			80001001: {ItemID: 80001001, SourceItemType: 8, RequiredLevel: 2},
		},
		edges:         map[int64][]character.EquipmentRecipeEdge{},
		compatibility: []character.EquipmentCompatibilityExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}},
		awakened:      map[int64]bool{p.TableID: awakened},
	}
	content.positions[[3]int64{p.TableID, p.Color, 1}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: p.Color, Slot: 1, ItemID: 80001001, Classification: classification}
	content.positions[[3]int64{p.TableID, p.Color, 2}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: p.Color, Slot: 2, Classification: character.PetEquipmentEmpty}
	content.positions[[3]int64{p.TableID, p.Color, 3}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: p.Color, Slot: 3, Classification: character.PetEquipmentEmpty}
	svc.Equipment = content
	rec := svc.Receipts.(*caReceipts)
	return svc, st, mat, rec, content
}

func TestPetEquipItemDirectDebitAndSameOperationReplay(t *testing.T) {
	svc, st, mat, rec, _ := petEquipmentFixture(t, character.PetEquipmentOrdinary, false)
	op := caOp(t, "10101010-1010-4010-8010-101010101010", 3000)
	got, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.AlreadyEquipped || got.Equipment != (character.PetEquipmentSlots{1, 0, 0}) || mat.calls != 1 || len(mat.last.Stacks) != 1 || mat.last.Stacks[0].ItemID != 80001001 || mat.last.Stacks[0].Amount != 1 || len(rec.m) != 1 {
		t.Fatalf("got=%+v equipment=%+v debit=%+v calls=%d receipts=%d", got, st.byID[1].Equipment, mat.last, mat.calls, len(rec.m))
	}
	version := st.byID[1].StateVersion
	got2, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got2.Equipment[0] != 1 || mat.calls != 1 || st.byID[1].StateVersion != version || len(rec.m) != 1 {
		t.Fatalf("same-operation replay reapplied: got=%+v calls=%d version=%d/%d receipts=%d", got2, mat.calls, st.byID[1].StateVersion, version, len(rec.m))
	}
}

func TestPetEquipItemCrossRequestAlreadyEquippedIs30001SemanticResult(t *testing.T) {
	svc, st, mat, rec, _ := petEquipmentFixture(t, character.PetEquipmentOrdinary, false)
	p := st.byID[1]
	p.Equipment[0] = 1
	st.byID[1] = p
	got, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, caOp(t, "20202020-2020-4020-8020-202020202020", 3001))
	if err != nil {
		t.Fatal(err)
	}
	if !got.AlreadyEquipped || got.Equipment[0] != 1 || mat.calls != 0 || len(rec.m) != 1 {
		t.Fatalf("got=%+v calls=%d receipts=%d", got, mat.calls, len(rec.m))
	}
}

func TestPetEquipItemAwakeningGateAndCommittedFact(t *testing.T) {
	t.Run("unawakened-fails-closed", func(t *testing.T) {
		svc, st, mat, rec, _ := petEquipmentFixture(t, character.PetEquipmentAwakening, false)
		before := st.byID[1]
		_, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, caOp(t, "30303030-3030-4030-8030-303030303030", 3002))
		if !errors.Is(err, ErrPetAwakeningProviderUnavailable) {
			t.Fatalf("err=%v", err)
		}
		if mat.calls != 0 || st.byID[1] != before || len(rec.m) != 0 {
			t.Fatalf("unawakened path mutated state: calls=%d pet=%+v receipts=%d", mat.calls, st.byID[1], len(rec.m))
		}
	})
	t.Run("already-awakened-succeeds-and-exposes-fact", func(t *testing.T) {
		svc, _, mat, _, _ := petEquipmentFixture(t, character.PetEquipmentAwakening, true)
		got, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, caOp(t, "40404040-4040-4040-8040-404040404040", 3003))
		if err != nil {
			t.Fatal(err)
		}
		if mat.calls != 1 || got.UniqueEquipmentFact == nil || got.UniqueEquipmentFact.ItemID != 80001001 || got.UniqueEquipmentFact.Slot != 1 || got.UniqueEquipmentFact.PetID != 1 {
			t.Fatalf("got=%+v calls=%d", got, mat.calls)
		}
		if err := got.UniqueEquipmentFact.Validate(); err != nil {
			t.Fatal(err)
		}
	})
}

type petEquipmentI5Content struct{}

func (petEquipmentI5Content) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", nil
}
func (petEquipmentI5Content) ResolveResourceTx(_ context.Context, _ tx.Queryer, revision string, line grant.Line) (appi5.ResourcePolicy, error) {
	if len(revision) != 64 {
		return appi5.ResourcePolicy{}, errors.New("revision mismatch")
	}
	switch line.Kind {
	case grant.ScalarCurrency:
		if line.ResourceKey != "mana" {
			return appi5.ResourcePolicy{}, economy.ErrUnknownResource
		}
		return appi5.ResourcePolicy{Kind: grant.ScalarCurrency, PolicyVersion: revision}, nil
	case grant.StackItem:
		return appi5.ResourcePolicy{Kind: grant.StackItem, Stack: &economy.StackDefinition{ItemID: line.ItemID, StackCap: 999999}, PolicyVersion: revision}, nil
	default:
		return appi5.ResourcePolicy{}, economy.ErrUnknownResource
	}
}
func (petEquipmentI5Content) ResolveProgressionPolicyTx(context.Context, tx.Queryer, string) (player.ProgressionPolicy, error) {
	return player.ProgressionPolicy{}, errors.New("unexpected progression policy")
}
func (petEquipmentI5Content) ResolveFunctionGatePolicyTx(context.Context, tx.Queryer, string) (appi5.FunctionGatePolicy, error) {
	return appi5.FunctionGatePolicy{}, errors.New("unexpected function policy")
}
func (petEquipmentI5Content) ResolvePetStarterPolicyTx(context.Context, tx.Queryer, string) (appi5.PetStarterPolicy, error) {
	return appi5.PetStarterPolicy{}, errors.New("unexpected Pet starter policy")
}
func (petEquipmentI5Content) ResolveObjective(context.Context, string, string, int64, string) (appi5.ObjectiveDefinition, error) {
	return appi5.ObjectiveDefinition{}, errors.New("unexpected objective")
}
func (petEquipmentI5Content) ResolveObjectiveTx(context.Context, tx.Queryer, string, string, int64, string) (appi5.ObjectiveDefinition, error) {
	return appi5.ObjectiveDefinition{}, errors.New("unexpected objective")
}

type petEquipmentI5Store struct {
	mana        economy.ScalarBalance
	progression player.Progression
	stacks      map[int64]economy.StackState
	writes      int
}

func (*petEquipmentI5Store) LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}
func (s *petEquipmentI5Store) LockProgressionTx(context.Context, tx.Tx, identity.PlayerID) (player.Progression, error) {
	return s.progression, nil
}
func (s *petEquipmentI5Store) LockScalarTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, key string, _ time.Time) (economy.ScalarBalance, bool, error) {
	if key != "mana" {
		return economy.ScalarBalance{}, false, nil
	}
	return s.mana, true, nil
}
func (s *petEquipmentI5Store) SaveScalarTx(_ context.Context, _ tx.Tx, v economy.ScalarBalance, _ bool) error {
	s.mana = v
	s.writes++
	return nil
}
func (s *petEquipmentI5Store) LockStackTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, itemID int64, _ time.Time) (economy.StackState, bool, error) {
	v, ok := s.stacks[itemID]
	return v, ok, nil
}
func (s *petEquipmentI5Store) SaveStackTx(_ context.Context, _ tx.Tx, v economy.StackState, _ bool) error {
	s.stacks[v.ItemID] = v
	s.writes++
	return nil
}
func (s *petEquipmentI5Store) DeleteStackTx(_ context.Context, _ tx.Tx, v economy.StackState) error {
	delete(s.stacks, v.ItemID)
	s.writes++
	return nil
}

func TestPetOneKeyEquipServiceAppliesI5AndPetStateOnce(t *testing.T) {
	svc, st, prog, _, _ := progressionFixture(t)
	p := st.byID[1]
	p.Color = 1
	p.Level = 1
	p.Exp = 0
	st.byID[1] = p
	prog.maxLevel = 2
	prog.threshold = []ExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}}
	content := &petEquipmentTestContent{
		positions: map[[3]int64]character.PetEquipmentPosition{
			{p.TableID, p.Color, 1}: {PetTableID: p.TableID, Color: p.Color, Slot: 1, ItemID: 80001001, Classification: character.PetEquipmentOrdinary},
			{p.TableID, p.Color, 2}: {PetTableID: p.TableID, Color: p.Color, Slot: 2, Classification: character.PetEquipmentEmpty},
			{p.TableID, p.Color, 3}: {PetTableID: p.TableID, Color: p.Color, Slot: 3, Classification: character.PetEquipmentEmpty},
		},
		primitives: map[int64]character.EquipmentPrimitive{80001001: {ItemID: 80001001, SourceItemType: 8, RequiredLevel: 2}},
		edges:      map[int64][]character.EquipmentRecipeEdge{},
		compatibility: []character.EquipmentCompatibilityExpThreshold{
			{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55},
		},
		awakened: map[int64]bool{},
	}
	svc.Equipment = content
	now := time.Unix(3004, 0).UTC()
	pid := identity.PlayerID(7)
	i5store := &petEquipmentI5Store{
		mana:        economy.ScalarBalance{PlayerID: pid, ResourceKey: "mana", Amount: 100, StateVersion: 1, UpdatedAt: now},
		progression: player.Progression{PlayerID: pid, Level: 100, Exp: 0, StateVersion: 1, UpdatedAt: now},
		stacks: map[int64]economy.StackState{
			80001001: {PlayerID: pid, ItemID: 80001001, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now},
			50001087: {PlayerID: pid, ItemID: 50001087, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now},
		},
	}
	svc.EquipmentResources = appi5.HeroEquipmentResourceDebiter{Store: i5store, Content: petEquipmentI5Content{}}
	op := caOp(t, "50505050-5050-4050-8050-505050505050", 3004)
	got, err := svc.OneKeyEquip(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.NoWork || got.Equipment != (character.PetEquipmentSlots{1, 0, 0}) || got.Level != 2 || got.Exp != 55 {
		t.Fatalf("got=%+v", got)
	}
	if _, ok := i5store.stacks[80001001]; ok {
		t.Fatal("finished Pet equipment was not consumed")
	}
	if _, ok := i5store.stacks[50001087]; ok {
		t.Fatal("Pet EXP potion was not consumed")
	}
	version := st.byID[1].StateVersion
	writes := i5store.writes
	got2, err := svc.OneKeyEquip(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got2.Equipment[0] != 1 || got2.Exp != 55 || st.byID[1].StateVersion != version || i5store.writes != writes {
		t.Fatalf("same-operation replay reapplied: got=%+v version=%d/%d writes=%d/%d", got2, st.byID[1].StateVersion, version, i5store.writes, writes)
	}
}

func TestPetOneKeyEquipCanonicalNoWorkIsReceiptedSuccess(t *testing.T) {
	svc, st, prog, _, _ := progressionFixture(t)
	p := st.byID[1]
	p.Color = 1
	p.Equipment = character.PetEquipmentSlots{1, 1, 1}
	st.byID[1] = p
	prog.maxLevel = 2
	content := &petEquipmentTestContent{
		positions: map[[3]int64]character.PetEquipmentPosition{
			{p.TableID, p.Color, 1}: {PetTableID: p.TableID, Color: p.Color, Slot: 1, ItemID: 80001001, Classification: character.PetEquipmentOrdinary},
			{p.TableID, p.Color, 2}: {PetTableID: p.TableID, Color: p.Color, Slot: 2, ItemID: 80001002, Classification: character.PetEquipmentOrdinary},
			{p.TableID, p.Color, 3}: {PetTableID: p.TableID, Color: p.Color, Slot: 3, ItemID: 80001003, Classification: character.PetEquipmentOrdinary},
		},
		primitives:    map[int64]character.EquipmentPrimitive{},
		edges:         map[int64][]character.EquipmentRecipeEdge{},
		compatibility: []character.EquipmentCompatibilityExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}},
		awakened:      map[int64]bool{},
	}
	svc.Equipment = content
	now := time.Unix(3005, 0).UTC()
	pid := identity.PlayerID(7)
	i5store := &petEquipmentI5Store{
		mana:        economy.ScalarBalance{PlayerID: pid, ResourceKey: "mana", Amount: 100, StateVersion: 1, UpdatedAt: now},
		progression: player.Progression{PlayerID: pid, Level: 100, StateVersion: 1, UpdatedAt: now},
		stacks:      map[int64]economy.StackState{},
	}
	svc.EquipmentResources = appi5.HeroEquipmentResourceDebiter{Store: i5store, Content: petEquipmentI5Content{}}
	got, err := svc.OneKeyEquip(context.Background(), caActor(t), 1, caOp(t, "60606060-6060-4060-8060-606060606060", 3005))
	if err != nil {
		t.Fatal(err)
	}
	if !got.NoWork || got.Equipment != p.Equipment || st.byID[1].StateVersion != p.StateVersion || i5store.writes != 0 {
		t.Fatalf("got=%+v version=%d/%d writes=%d", got, st.byID[1].StateVersion, p.StateVersion, i5store.writes)
	}
}

type petFailMaterial struct{ calls int }

func (d *petFailMaterial) DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, appi5.MaterialCost, operation.Context) (appi5.MaterialDebitResult, error) {
	d.calls++
	return appi5.MaterialDebitResult{}, economy.ErrInsufficientBalance
}

func TestPetEquipItemValidationFailsBeforeDurableMutation(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(*Service, *caStore, *petEquipmentTestContent)
		petID  int64
		want   error
	}{
		{name: "not-owned", petID: 99, want: ErrPetNotFound},
		{name: "not-shown", petID: 1, mutate: func(_ *Service, st *caStore, _ *petEquipmentTestContent) {
			p := st.byID[1]
			p.IsShow = false
			st.byID[1] = p
		}, want: ErrPetNotShown},
		{name: "empty-mapping", petID: 1, mutate: func(_ *Service, st *caStore, c *petEquipmentTestContent) {
			p := st.byID[1]
			c.positions[[3]int64{p.TableID, p.Color, 1}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: p.Color, Slot: 1, Classification: character.PetEquipmentEmpty}
		}, want: ErrPetEquipmentUnavailable},
		{name: "level-too-low", petID: 1, mutate: func(_ *Service, st *caStore, c *petEquipmentTestContent) {
			p := st.byID[1]
			p.Level = 1
			p.Exp = 0
			st.byID[1] = p
			x := c.primitives[80001001]
			x.RequiredLevel = 2
			c.primitives[80001001] = x
		}, want: ErrPetEquipmentUnavailable},
	}
	for i, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			svc, st, mat, rec, content := petEquipmentFixture(t, character.PetEquipmentOrdinary, false)
			if tc.mutate != nil {
				tc.mutate(&svc, st, content)
			}
			before := st.byID[1]
			_, err := svc.EquipItem(context.Background(), caActor(t), tc.petID, 1, caOp(t, "70707070-7070-4070-8070-707070707070", int64(3100+i)))
			if !errors.Is(err, tc.want) {
				t.Fatalf("err=%v want=%v", err, tc.want)
			}
			if tc.petID == 1 && st.byID[1] != before {
				t.Fatalf("Pet mutated: before=%+v after=%+v", before, st.byID[1])
			}
			if mat.calls != 0 || len(rec.m) != 0 {
				t.Fatalf("precondition failure debited/receipted: calls=%d receipts=%d", mat.calls, len(rec.m))
			}
		})
	}
}

func TestPetEquipItemMissingFinishedItemDoesNotCollectSlot(t *testing.T) {
	svc, st, _, rec, _ := petEquipmentFixture(t, character.PetEquipmentOrdinary, false)
	fail := &petFailMaterial{}
	svc.MaterialCosts = fail
	before := st.byID[1]
	_, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, caOp(t, "80808080-8080-4080-8080-808080808080", 3200))
	if !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("err=%v", err)
	}
	if fail.calls != 1 || st.byID[1] != before || len(rec.m) != 0 {
		t.Fatalf("calls=%d before=%+v after=%+v receipts=%d", fail.calls, before, st.byID[1], len(rec.m))
	}
}

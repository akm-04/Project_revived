package characterhero

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type equipmentOpContent struct {
	positions      map[[3]int64]character.HeroEquipmentPosition
	superPositions map[[2]int64]character.SuperEquipmentPosition
	primitives     map[int64]character.EquipmentPrimitive
	edges          map[int64][]character.EquipmentRecipeEdge
}

func (equipmentOpContent) HeroEquipmentRevision(context.Context, string) (bool, error) {
	return true, nil
}
func (equipmentOpContent) SuperEquipmentRevision(context.Context, string) (bool, error) {
	return true, nil
}
func (equipmentOpContent) EquipmentPrimitivesRevision(context.Context, string) (bool, error) {
	return true, nil
}
func (c equipmentOpContent) HeroEquipmentPositionTx(_ context.Context, _ tx.Queryer, _ string, table, color, slot int64) (character.HeroEquipmentPosition, error) {
	p, ok := c.positions[[3]int64{table, color, slot}]
	if !ok {
		return character.HeroEquipmentPosition{}, errors.New("missing position")
	}
	return p, nil
}
func (c equipmentOpContent) SuperEquipmentPositionTx(_ context.Context, _ tx.Queryer, _ string, table, slot int64) (character.SuperEquipmentPosition, error) {
	p, ok := c.superPositions[[2]int64{table, slot}]
	if !ok {
		return character.SuperEquipmentPosition{}, errors.New("missing Super position")
	}
	return p, nil
}
func (equipmentOpContent) SuperEquipmentCapTx(_ context.Context, _ tx.Queryer, _ string, star int64) (character.SuperEquipmentEnhancementCap, error) {
	caps := map[int64]int64{1: 10, 2: 10, 3: 10, 4: 10, 5: 10, 6: 20, 7: 30, 8: 40, 9: 50, 10: 60}
	v, ok := caps[star]
	if !ok {
		return character.SuperEquipmentEnhancementCap{}, errors.New("missing Super cap")
	}
	return character.SuperEquipmentEnhancementCap{Star: star, MaxEnhancement: v, EffectiveClientReachable: star <= 8}, nil
}
func (equipmentOpContent) SuperEquipmentTierTx(_ context.Context, _ tx.Queryer, _ string, tier int64) (character.SuperEquipmentEnhancementTier, error) {
	mins := []int64{1, 6, 7, 8, 9, 10}
	counts := []int64{1, 1, 1, 1, 2, 2}
	if tier < 1 || tier > 6 {
		return character.SuperEquipmentEnhancementTier{}, errors.New("missing Super tier")
	}
	return character.SuperEquipmentEnhancementTier{Tier: tier, MinStar: mins[tier-1], DuplicateCount: counts[tier-1], EffectiveClientReachable: mins[tier-1] <= 8}, nil
}
func (c equipmentOpContent) EquipmentPrimitiveTx(_ context.Context, _ tx.Queryer, _ string, id int64) (character.EquipmentPrimitive, error) {
	p, ok := c.primitives[id]
	if !ok {
		return character.EquipmentPrimitive{}, errors.New("missing primitive")
	}
	return p, nil
}
func (c equipmentOpContent) EquipmentRecipeEdgesTx(_ context.Context, _ tx.Queryer, _ string, id int64) ([]character.EquipmentRecipeEdge, error) {
	return append([]character.EquipmentRecipeEdge(nil), c.edges[id]...), nil
}

type equipmentCostDebit struct {
	calls int
	item  int64
	count int64
}

func (d *equipmentCostDebit) DebitMaterialCostTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	d.calls++
	if len(cost.Stacks) != 1 || len(cost.Scalars) != 0 {
		return appi5.MaterialDebitResult{}, errors.New("unexpected cost")
	}
	d.item, d.count = cost.Stacks[0].ItemID, cost.Stacks[0].Amount
	return appi5.MaterialDebitResult{}, nil
}

type equipmentI5Content struct{}

func (equipmentI5Content) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return progRev, nil
}
func (equipmentI5Content) ResolveResourceTx(_ context.Context, _ tx.Queryer, revision string, line grant.Line) (appi5.ResourcePolicy, error) {
	if revision != progRev {
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
func (equipmentI5Content) ResolveProgressionPolicyTx(context.Context, tx.Queryer, string) (player.ProgressionPolicy, error) {
	return player.ProgressionPolicy{}, errors.New("unexpected progression policy")
}
func (equipmentI5Content) ResolveFunctionGatePolicyTx(context.Context, tx.Queryer, string) (appi5.FunctionGatePolicy, error) {
	return appi5.FunctionGatePolicy{}, errors.New("unexpected function policy")
}
func (equipmentI5Content) ResolvePetStarterPolicyTx(context.Context, tx.Queryer, string) (appi5.PetStarterPolicy, error) {
	return appi5.PetStarterPolicy{}, errors.New("unexpected pet policy")
}
func (equipmentI5Content) ResolveObjective(context.Context, string, string, int64, string) (appi5.ObjectiveDefinition, error) {
	return appi5.ObjectiveDefinition{}, errors.New("unexpected objective")
}
func (equipmentI5Content) ResolveObjectiveTx(context.Context, tx.Queryer, string, string, int64, string) (appi5.ObjectiveDefinition, error) {
	return appi5.ObjectiveDefinition{}, errors.New("unexpected objective")
}

type equipmentI5Store struct {
	pid         identity.PlayerID
	mana        economy.ScalarBalance
	progression player.Progression
	stacks      map[int64]economy.StackState
	writes      int
}

func (s *equipmentI5Store) LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}
func (s *equipmentI5Store) LockProgressionTx(context.Context, tx.Tx, identity.PlayerID) (player.Progression, error) {
	return s.progression, nil
}
func (s *equipmentI5Store) LockScalarTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, key string, _ time.Time) (economy.ScalarBalance, bool, error) {
	if key != "mana" {
		return economy.ScalarBalance{}, false, nil
	}
	return s.mana, true, nil
}
func (s *equipmentI5Store) SaveScalarTx(_ context.Context, _ tx.Tx, v economy.ScalarBalance, _ bool) error {
	s.mana = v
	s.writes++
	return nil
}
func (s *equipmentI5Store) LockStackTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, itemID int64, _ time.Time) (economy.StackState, bool, error) {
	v, ok := s.stacks[itemID]
	return v, ok, nil
}
func (s *equipmentI5Store) SaveStackTx(_ context.Context, _ tx.Tx, v economy.StackState, _ bool) error {
	s.stacks[v.ItemID] = v
	s.writes++
	return nil
}
func (s *equipmentI5Store) DeleteStackTx(_ context.Context, _ tx.Tx, v economy.StackState) error {
	delete(s.stacks, v.ItemID)
	s.writes++
	return nil
}

func equipmentServiceFixture(t *testing.T, hero character.Hero, i5 *equipmentI5Store) (Service, *progStore, *receipts, *equipmentCostDebit) {
	t.Helper()
	ps := &progStore{heroes: map[int64]character.Hero{hero.PartnerID: hero}}
	kind := hero.Kind
	if kind == "" {
		kind = character.NormalHero
	}
	pc := progContent{
		exp:      map[int64]int64{50001001: 60, 50001002: 300, 50001004: 1500, 50001005: 7500, 50005182: 10000},
		template: map[int64]character.HeroTemplateProgression{hero.TableID: {Kind: kind, OriginTableID: hero.OriginTableID, InitialStar: hero.Star}},
	}
	positions := map[[3]int64]character.HeroEquipmentPosition{}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{hero.TableID, hero.Color, slot}] = character.HeroEquipmentPosition{HeroTableID: hero.TableID, Color: hero.Color, Slot: slot}
	}
	positions[[3]int64{hero.TableID, hero.Color, 1}] = character.HeroEquipmentPosition{HeroTableID: hero.TableID, Color: hero.Color, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	superPositions := map[[2]int64]character.SuperEquipmentPosition{}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		superPositions[[2]int64{hero.TableID, slot}] = character.SuperEquipmentPosition{HeroTableID: hero.TableID, Slot: slot, ItemID: character.EquipmentTemplateID(20001365 + slot)}
	}
	primitives := map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, SourceItemType: 1, RequiredLevel: 2}}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		id := 20001365 + slot
		primitives[id] = character.EquipmentPrimitive{ItemID: character.EquipmentTemplateID(id), SourceItemType: 1, RequiredLevel: 89}
	}
	eq := equipmentOpContent{positions: positions, superPositions: superPositions, primitives: primitives, edges: map[int64][]character.EquipmentRecipeEdge{}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	cost := &equipmentCostDebit{}
	pe := &progEconomy{playerLevel: 100, remaining: map[int64]int64{}}
	now := time.Unix(1, 0).UTC()
	core := &store{root: character.HeroRoot{PlayerID: hero.PlayerID, NextPartnerID: 100, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	svc := Service{Runner: tx.Runner{DB: fakeDB{}}, Store: core, Fencer: &fence{}, Content: gate(true), Receipts: rr, ReceiptRead: rr, ProgressionStore: ps, Progression: pc, Economy: pe, Backpack: emptyBackpack{}, MaterialCosts: cost, Equipment: eq}
	if i5 != nil {
		svc.EquipmentResources = appi5.HeroEquipmentResourceDebiter{Store: i5, Content: equipmentI5Content{}}
	}
	return svc, ps, rr, cost
}

func TestEquipItemDirectDebitAndReceiptReplay(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 2, 25, now)
	svc, ps, _, cost := equipmentServiceFixture(t, h, nil)
	op := testOp(t, "66666666-6666-4666-8666-666666666666")
	got, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.AlreadyEquipped || got.Equipment[0] != 1 || cost.calls != 1 || cost.item != 20001005 || cost.count != 1 || ps.saves != 1 {
		t.Fatalf("got=%+v cost=%+v saves=%d", got, cost, ps.saves)
	}
	got2, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got2.Equipment[0] != 1 || cost.calls != 1 || ps.saves != 1 {
		t.Fatalf("receipt replay reapplied: got=%+v calls=%d saves=%d", got2, cost.calls, ps.saves)
	}
}

func TestEquipItemCrossRequestAlreadyEquippedIsZeroEffectReceipt(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 2, 25, now)
	h.Equipment[0] = 1
	svc, ps, rr, cost := equipmentServiceFixture(t, h, nil)
	got, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, testOp(t, "77777777-7777-4777-8777-777777777777"))
	if err != nil {
		t.Fatal(err)
	}
	if !got.AlreadyEquipped || cost.calls != 0 || ps.saves != 0 || len(rr.m) != 1 {
		t.Fatalf("got=%+v cost=%d saves=%d receipts=%d", got, cost.calls, ps.saves, len(rr.m))
	}
}

func TestOneKeyEquipComposesI5AndHeroStateWithReceiptReplay(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 1, 0, now)
	for i := 1; i < character.HeroEquipmentSlotCount; i++ {
		h.Equipment[i] = 1
	}
	pid := identity.PlayerID(7)
	i5 := &equipmentI5Store{
		pid:         pid,
		mana:        economy.ScalarBalance{PlayerID: pid, ResourceKey: "mana", Amount: 100, StateVersion: 1, UpdatedAt: now},
		progression: player.Progression{PlayerID: pid, Level: 100, Exp: 0, StateVersion: 1, UpdatedAt: now},
		stacks: map[int64]economy.StackState{
			20001005: {PlayerID: pid, ItemID: 20001005, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now},
			50001001: {PlayerID: pid, ItemID: 50001001, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now},
		},
	}
	svc, ps, _, _ := equipmentServiceFixture(t, h, i5)
	op := testOp(t, "88888888-8888-4888-8888-888888888888")
	got, err := svc.OneKeyEquip(context.Background(), testActor(t), 11, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.NoWork || got.Equipment[0] != 1 || got.Level != 3 || got.Exp != 60 || ps.saves != 1 {
		t.Fatalf("got=%+v saves=%d", got, ps.saves)
	}
	if _, ok := i5.stacks[20001005]; ok {
		t.Fatal("equipment stack not consumed")
	}
	if _, ok := i5.stacks[50001001]; ok {
		t.Fatal("potion stack not consumed")
	}
	writes := i5.writes
	got2, err := svc.OneKeyEquip(context.Background(), testActor(t), 11, op)
	if err != nil {
		t.Fatal(err)
	}
	if got2.Equipment[0] != 1 || got2.Exp != 60 || ps.saves != 1 || i5.writes != writes {
		t.Fatalf("receipt replay reapplied: got=%+v saves=%d writes=%d/%d", got2, ps.saves, i5.writes, writes)
	}
}

func TestCA45EquipmentReceiptValidationIsFamilyQualified(t *testing.T) {
	base := heroEquipmentReceipt{PartnerID: 11, Level: 89, Exp: 0, Equipment: character.HeroEquipmentSlots{3, 1, 0, 0, 0, 0}}
	payload, err := json.Marshal(base)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := decodeHeroEquipmentReceipt(receipt.Receipt{ResultSchema: heroEquipmentMID54NormalV1, ResultPayload: payload}); err == nil {
		t.Fatal("Normal v1 receipt accepted Super-style enhancement value")
	}
	base.Family = character.SuperHero
	payload, err = json.Marshal(base)
	if err != nil {
		t.Fatal(err)
	}
	got, err := decodeHeroEquipmentReceipt(receipt.Receipt{ResultSchema: heroEquipmentMID54SuperV2, ResultPayload: payload})
	if err != nil {
		t.Fatal(err)
	}
	if got.Family != character.SuperHero || got.Equipment[0] != 3 {
		t.Fatalf("got=%+v", got)
	}
	base.Family = character.NormalHero
	payload, _ = json.Marshal(base)
	if _, err := decodeHeroEquipmentReceipt(receipt.Receipt{ResultSchema: heroEquipmentMID54SuperV2, ResultPayload: payload}); err == nil {
		t.Fatal("Super v2 receipt accepted mismatched family")
	}
}

func TestCA45EquipmentReceiptValidationRejectsTamperedPayload(t *testing.T) {
	for _, tc := range []heroEquipmentReceipt{
		{Family: character.SuperHero, PartnerID: 0, Equipment: character.HeroEquipmentSlots{1, 0, 0, 0, 0, 0}},
		{Family: character.SuperHero, PartnerID: 11, Equipment: character.HeroEquipmentSlots{-1, 0, 0, 0, 0, 0}},
	} {
		payload, err := json.Marshal(tc)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := decodeHeroEquipmentReceipt(receipt.Receipt{ResultSchema: heroEquipmentMID54SuperV2, ResultPayload: payload}); err == nil {
			t.Fatalf("tampered Super receipt accepted: %+v", tc)
		}
	}
	if _, err := decodeHeroEquipmentReceipt(receipt.Receipt{ResultSchema: heroEquipmentMID54SuperV2, ResultPayload: []byte(`{"family":"SUPER"`)}); err == nil {
		t.Fatal("malformed Super receipt payload accepted")
	}
}

func TestCA45SuperEquipItemUsesFixedTopologyAndFamilyReceiptReplay(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 11001, 11001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment[1] = 7 // prove unrelated enhanced raw state is legal and replay-safe
	h.Fumo = character.HeroFumoSlots{20, 160, 1120, 0, 0, 0}
	svc, ps, rr, cost := equipmentServiceFixture(t, h, nil)
	op := testOp(t, "b1010101-1010-4101-8101-101010101010")
	got, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment[0] != 1 || got.Equipment[1] != 7 || cost.calls != 1 || cost.item != 20001366 || cost.count != 1 || ps.saves != 1 {
		t.Fatalf("got=%+v cost=%+v saves=%d", got, cost, ps.saves)
	}
	saved := ps.heroes[11]
	if saved.Star != h.Star || saved.Level != h.Level || saved.Exp != h.Exp || saved.Color != h.Color || saved.Fumo != h.Fumo || saved.OriginTableID != h.OriginTableID {
		t.Fatalf("Super MID54 changed unrelated Hero state: before=%+v after=%+v", h, saved)
	}
	if len(rr.m) != 1 {
		t.Fatalf("receipts=%d", len(rr.m))
	}
	for _, r := range rr.m {
		if r.ResultSchema != heroEquipmentMID54SuperV2 {
			t.Fatalf("schema=%q", r.ResultSchema)
		}
		decoded, err := decodeHeroEquipmentReceipt(r)
		if err != nil {
			t.Fatal(err)
		}
		if decoded.Family != character.SuperHero || decoded.Equipment[1] != 7 {
			t.Fatalf("decoded=%+v", decoded)
		}
	}
	got2, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got2.Equipment[0] != 1 || got2.Equipment[1] != 7 || cost.calls != 1 || ps.saves != 1 {
		t.Fatal("replay reapplied")
	}
}

func TestCA45SuperEquipItemLevelGateAndAlreadyEquippedCompatibility(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 11001, 11001, 8, 88, 0, now)
	h.Kind = character.SuperHero
	svc, _, _, cost := equipmentServiceFixture(t, h, nil)
	if _, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, testOp(t, "b2020202-2020-4202-8202-202020202020")); !errors.Is(err, ErrHeroEquipmentUnavailable) {
		t.Fatalf("err=%v", err)
	}
	if cost.calls != 0 {
		t.Fatal("debit below level 89")
	}
	h.Level = 89
	h.Equipment[0] = 5
	svc, ps, _, cost := equipmentServiceFixture(t, h, nil)
	got, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, testOp(t, "b3030303-3030-4303-8303-303030303030"))
	if err != nil {
		t.Fatal(err)
	}
	if !got.AlreadyEquipped || got.Equipment[0] != 5 || cost.calls != 0 || ps.saves != 0 {
		t.Fatalf("got=%+v calls=%d saves=%d", got, cost.calls, ps.saves)
	}
}

func TestCA45OneKeySuperFailsClosed(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 11001, 11001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	i5 := &equipmentI5Store{pid: 7, mana: economy.ScalarBalance{PlayerID: 7, ResourceKey: "mana", Amount: 100, StateVersion: 1, UpdatedAt: now}, progression: player.Progression{PlayerID: 7, Level: 100, StateVersion: 1, UpdatedAt: now}, stacks: map[int64]economy.StackState{}}
	svc, _, _, _ := equipmentServiceFixture(t, h, i5)
	if _, err := svc.OneKeyEquip(context.Background(), testActor(t), 11, testOp(t, "b4040404-4040-4404-8404-404040404040")); !errors.Is(err, ErrHeroEquipmentUnavailable) {
		t.Fatalf("err=%v", err)
	}
}

func TestCA45EnhanceSuperEquipmentCrossTierAndReceiptReplay(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 9001, 9001, 6, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment = character.HeroEquipmentSlots{10, 7, 3, 1, 0, 0} // selected current enhancement=9
	svc, ps, rr, cost := equipmentServiceFixture(t, h, nil)
	op := testOp(t, "c1010101-0101-4101-8101-010101010101")
	got, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 2, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.PartnerID != 11 || got.Equipment != (character.HeroEquipmentSlots{12, 7, 3, 1, 0, 0}) {
		t.Fatalf("result=%+v", got)
	}
	if cost.calls != 1 || cost.item != 20001366 || cost.count != 2 || ps.saves != 1 {
		t.Fatalf("debit/save calls=%d item=%d count=%d saves=%d", cost.calls, cost.item, cost.count, ps.saves)
	}
	if len(rr.m) != 1 {
		t.Fatalf("receipts=%d", len(rr.m))
	}
	for _, r := range rr.m {
		if r.ResultSchema != heroEquipmentMID304SuperV1 {
			t.Fatalf("schema=%q", r.ResultSchema)
		}
		decoded, err := decodeSuperEquipmentEnhanceReceipt(r)
		if err != nil {
			t.Fatal(err)
		}
		if decoded.Equipment[0] != 12 || decoded.Equipment[1] != 7 {
			t.Fatalf("decoded=%+v", decoded)
		}
	}
	got2, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 2, op)
	if err != nil {
		t.Fatal(err)
	}
	if got2.Equipment != got.Equipment || cost.calls != 1 || ps.saves != 1 {
		t.Fatalf("replay result=%+v calls=%d saves=%d", got2, cost.calls, ps.saves)
	}
}

func TestCA45EnhanceSuperEquipmentMultiLevelDebitAcrossReachableTiers(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 9001, 9001, 8, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment[0] = 10 // enhancement 9 -> target 31 crosses 10/20/30
	svc, ps, _, cost := equipmentServiceFixture(t, h, nil)
	got, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 22, testOp(t, "c2020202-0202-4202-8202-020202020202"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment[0] != 32 || cost.item != 20001366 || cost.count != 22 || cost.calls != 1 || ps.saves != 1 {
		t.Fatalf("got=%+v cost=%d/%d/%d saves=%d", got, cost.item, cost.count, cost.calls, ps.saves)
	}
}

func TestCA45EnhanceSuperEquipmentExactStarCaps(t *testing.T) {
	for _, tc := range []struct{ star, cap int64 }{{1, 10}, {5, 10}, {6, 20}, {7, 30}, {8, 40}} {
		t.Run(fmt.Sprintf("star-%d", tc.star), func(t *testing.T) {
			now := time.Unix(1, 0).UTC()
			h := heroAt(11, 9001, 9001, tc.star, 89, 0, now)
			h.Kind = character.SuperHero
			h.Equipment[0] = tc.cap // current enhancement cap-1
			svc, ps, _, cost := equipmentServiceFixture(t, h, nil)
			got, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "c3030303-0303-4303-8303-030303030303"))
			if err != nil {
				t.Fatal(err)
			}
			if got.Equipment[0] != tc.cap+1 || cost.count != 1 || ps.saves != 1 {
				t.Fatalf("at cap boundary got=%d debit=%d saves=%d", got.Equipment[0], cost.count, ps.saves)
			}

			h2 := h
			h2.Equipment[0] = tc.cap + 1 // already at enhancement cap
			svc2, ps2, _, cost2 := equipmentServiceFixture(t, h2, nil)
			if _, err := svc2.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "c4040404-0404-4404-8404-040404040404")); !errors.Is(err, ErrHeroEquipmentUnavailable) {
				t.Fatalf("cap crossing err=%v", err)
			}
			if cost2.calls != 0 || ps2.saves != 0 {
				t.Fatalf("cap rejection mutated cost=%d saves=%d", cost2.calls, ps2.saves)
			}
		})
	}
}

func TestCA45EnhanceSuperEquipmentRejectsWrongFamilyUncollectedAndInvalidCount(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	base := heroAt(11, 9001, 9001, 8, 89, 0, now)
	base.Equipment[0] = 1

	normal := base
	normal.Kind = character.NormalHero
	svc, ps, _, cost := equipmentServiceFixture(t, normal, nil)
	if _, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "c5050505-0505-4505-8505-050505050505")); !errors.Is(err, ErrHeroEquipmentUnavailable) {
		t.Fatalf("normal family err=%v", err)
	}
	if cost.calls != 0 || ps.saves != 0 {
		t.Fatalf("normal rejection mutated cost=%d saves=%d", cost.calls, ps.saves)
	}

	super := base
	super.Kind = character.SuperHero
	super.Equipment[0] = 0
	svc, ps, _, cost = equipmentServiceFixture(t, super, nil)
	if _, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "c6060606-0606-4606-8606-060606060606")); !errors.Is(err, ErrHeroEquipmentUnavailable) {
		t.Fatalf("uncollected err=%v", err)
	}
	if cost.calls != 0 || ps.saves != 0 {
		t.Fatalf("uncollected rejection mutated cost=%d saves=%d", cost.calls, ps.saves)
	}

	super.Equipment[0] = 1
	svc, _, _, cost = equipmentServiceFixture(t, super, nil)
	if _, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 0, testOp(t, "c7070707-0707-4707-8707-070707070707")); err == nil {
		t.Fatal("enhance_times=0 accepted")
	}
	if cost.calls != 0 {
		t.Fatalf("invalid count debited=%d", cost.calls)
	}
}

func TestCA45EnhanceSuperEquipmentRejectsOutsideEffectiveStarRangeBeforeDebit(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 9001, 9001, 9, 89, 0, now)
	h.Kind = character.SuperHero
	h.Equipment[0] = 1
	svc, ps, _, cost := equipmentServiceFixture(t, h, nil)
	if _, err := svc.EnhanceSuperEquipment(context.Background(), testActor(t), 11, 1, 1, testOp(t, "c8080808-0808-4808-8808-080808080808")); err == nil {
		t.Fatal("effective-client-inactive star 9 accepted")
	}
	if cost.calls != 0 || ps.saves != 0 {
		t.Fatalf("star 9 rejection mutated cost=%d saves=%d", cost.calls, ps.saves)
	}
}

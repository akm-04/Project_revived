package characterhero

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type promotionFumoContent struct {
	targets map[int64]character.HeroFumoTarget
}

func (promotionFumoContent) HeroFumoRevision(context.Context, string) (bool, error) { return true, nil }
func (c promotionFumoContent) HeroFumoTargetTx(_ context.Context, _ tx.Queryer, _ string, id character.EquipmentTemplateID) (character.HeroFumoTarget, error) {
	v, ok := c.targets[int64(id)]
	if !ok {
		return character.HeroFumoTarget{}, errors.New("missing fumo target")
	}
	return v, nil
}
func (promotionFumoContent) HeroFumoMaterialTx(context.Context, tx.Queryer, string, character.EquipmentTemplateID) (character.HeroFumoMaterial, error) {
	return character.HeroFumoMaterial{}, errors.New("unexpected fumo material")
}

type promotionContent struct {
	eligible map[int64]int64
	policy   character.HeroPromotionRestorationPolicy
}

func (promotionContent) HeroPromotionRestorationRevision(context.Context, string) (bool, error) {
	return true, nil
}
func (c promotionContent) HeroPromotionRestorationEligibilityTx(_ context.Context, _ tx.Queryer, _ string, id character.EquipmentTemplateID) (character.HeroPromotionRestorationEligibility, error) {
	q, ok := c.eligible[int64(id)]
	if !ok {
		return character.HeroPromotionRestorationEligibility{}, errors.New("not refundable")
	}
	return character.HeroPromotionRestorationEligibility{ItemID: id, SourceQuality: q}, nil
}
func (c promotionContent) HeroPromotionRestorationPolicyTx(context.Context, tx.Queryer, string) (character.HeroPromotionRestorationPolicy, error) {
	return c.policy, nil
}

type promotionMaxColor struct {
	value int64
	rev   string
}

func (p promotionMaxColor) MaxHeroColorTx(context.Context, tx.Queryer, identity.PlayerID, operation.Context) (int64, error) {
	return p.value, nil
}
func (p promotionMaxColor) MaxHeroColorPolicyRevision() string { return p.rev }

type promotionI5Content struct{ equipmentI5Content }

func (promotionI5Content) ResolveResourceTx(_ context.Context, _ tx.Queryer, revision string, line grant.Line) (appi5.ResourcePolicy, error) {
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
		return appi5.ResourcePolicy{Kind: grant.StackItem, WireTableID: line.ItemID, Stack: &economy.StackDefinition{ItemID: line.ItemID, StackCap: 999999, OverflowToMail: true}, PolicyVersion: revision}, nil
	default:
		return appi5.ResourcePolicy{}, economy.ErrUnknownResource
	}
}

type promotionI5Store struct {
	appi5.Store
	inner *equipmentI5Store
}

func (s *promotionI5Store) LockEconomyOwnerTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) error {
	return s.inner.LockEconomyOwnerTx(ctx, t, pid)
}
func (s *promotionI5Store) LockMailNamespaceCounterTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) error {
	return nil
}
func (s *promotionI5Store) LockProgressionTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (player.Progression, error) {
	return s.inner.LockProgressionTx(ctx, t, pid)
}
func (s *promotionI5Store) LockScalarTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, now time.Time) (economy.ScalarBalance, bool, error) {
	return s.inner.LockScalarTx(ctx, t, pid, key, now)
}
func (s *promotionI5Store) SaveScalarTx(ctx context.Context, t tx.Tx, v economy.ScalarBalance, exists bool) error {
	return s.inner.SaveScalarTx(ctx, t, v, exists)
}
func (s *promotionI5Store) LockStackTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, id int64, now time.Time) (economy.StackState, bool, error) {
	return s.inner.LockStackTx(ctx, t, pid, id, now)
}
func (s *promotionI5Store) SaveStackTx(ctx context.Context, t tx.Tx, v economy.StackState, exists bool) error {
	return s.inner.SaveStackTx(ctx, t, v, exists)
}
func (s *promotionI5Store) DeleteStackTx(ctx context.Context, t tx.Tx, v economy.StackState) error {
	return s.inner.DeleteStackTx(ctx, t, v)
}

type promotionFixture struct {
	svc    Service
	ps     *progStore
	i5     *equipmentI5Store
	i5svc  appi5.Service
	rr     *receipts
	eq     equipmentOpContent
	fumo   promotionFumoContent
	promo  promotionContent
	maxCol promotionMaxColor
}

func makePromotionFixture(t *testing.T, h character.Hero, positions map[[3]int64]character.HeroEquipmentPosition, primitives map[int64]character.EquipmentPrimitive, maxColor int64) promotionFixture {
	t.Helper()
	ps := &progStore{heroes: map[int64]character.Hero{h.PartnerID: h}}
	pc := progContent{
		exp:      map[int64]int64{50001001: 60, 50001002: 300, 50001004: 1500, 50001005: 7500, 50005182: 10000},
		template: map[int64]character.HeroTemplateProgression{h.TableID: {Kind: character.NormalHero, OriginTableID: h.OriginTableID, InitialStar: h.Star}},
	}
	eq := equipmentOpContent{positions: positions, primitives: primitives, edges: map[int64][]character.EquipmentRecipeEdge{}}
	fumo := promotionFumoContent{targets: map[int64]character.HeroFumoTarget{}}
	promo := promotionContent{eligible: map[int64]int64{}, policy: testRestorationPolicy()}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	now := time.Unix(1, 0).UTC()
	baseI5 := &equipmentI5Store{
		pid:         h.PlayerID,
		mana:        economy.ScalarBalance{PlayerID: h.PlayerID, ResourceKey: "mana", Amount: 1000, StateVersion: 1, UpdatedAt: now},
		progression: player.Progression{PlayerID: h.PlayerID, Level: 100, Exp: 0, StateVersion: 1, UpdatedAt: now},
		stacks:      map[int64]economy.StackState{},
	}
	storeI5 := &promotionI5Store{inner: baseI5}
	i5svc := appi5.Service{Store: storeI5, Content: promotionI5Content{}, Receipts: rr, ReceiptRead: rr}
	core := &store{root: character.HeroRoot{PlayerID: h.PlayerID, NextPartnerID: 100, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	max := promotionMaxColor{value: maxColor, rev: "test-max-color-v1"}
	svc := Service{
		Runner: tx.Runner{DB: fakeDB{}}, Store: core, Fencer: &fence{}, Content: gate(true), Receipts: rr, ReceiptRead: rr,
		ProgressionStore: ps, Progression: pc, Economy: &progEconomy{playerLevel: 100, remaining: map[int64]int64{}}, Backpack: emptyBackpack{},
		Equipment: eq, Fumo: fumo, Promotion: promo, PromotionResources: i5svc, StrictRestoration: i5svc,
		MaxHeroColorPolicy: max, RestorationModifier: characterasset.IdentityRestorationModifier{},
	}
	return promotionFixture{svc: svc, ps: ps, i5: baseI5, i5svc: i5svc, rr: rr, eq: eq, fumo: fumo, promo: promo, maxCol: max}
}

func emptyPromotionPositions(table, color int64) map[[3]int64]character.HeroEquipmentPosition {
	out := map[[3]int64]character.HeroEquipmentPosition{}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		out[[3]int64{table, color, slot}] = character.HeroEquipmentPosition{HeroTableID: table, Color: color, Slot: slot}
	}
	return out
}

func corruptPromotionReceiptBranch(t *testing.T, rr *receipts, branch HeroPromotionBranch) {
	t.Helper()
	if len(rr.m) != 1 {
		t.Fatalf("expected one receipt, got %d", len(rr.m))
	}
	for id, got := range rr.m {
		decoded, err := decodeHeroPromotionReceipt(got)
		if err != nil {
			t.Fatal(err)
		}
		decoded.Branch = branch
		payload, err := json.Marshal(decoded)
		if err != nil {
			t.Fatal(err)
		}
		got.ResultPayload = payload
		rr.m[id] = got
	}
}

func TestPowerUpHeroClearsOrdinaryAndPreservesSpecialFumoWithReceiptReplay(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Equipment[0], h.Equipment[1] = 1, 1
	h.Fumo[1] = 100
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	positions[[3]int64{h.TableID, 1, 2}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 2, ItemID: 20002001, OrdinaryEligible: false}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	positions[[3]int64{h.TableID, 2, 2}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: 2, ItemID: 20002001, OrdinaryEligible: false}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	fx.fumo.targets[20002001] = character.HeroFumoTarget{ItemID: 20002001, ThresholdIncrements: []int64{200}, TotalCap: 200, StageDeltaByAttr: []map[int64]string{{}}}
	fx.svc.Fumo = fx.fumo
	op := testOp(t, "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
	got, err := fx.svc.PowerUpHero(context.Background(), testActor(t), h.PartnerID, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.Branch != HeroPromotionMID51Promote || got.FromColor != 1 || got.ToColor != 2 || got.Equipment[0] != 0 || got.Fumo[0] != 0 || got.Equipment[1] != 1 || got.Fumo[1] != 100 || got.StateVersion != 2 {
		t.Fatalf("result=%+v", got)
	}
	if fx.ps.saves != 1 {
		t.Fatalf("saves=%d", fx.ps.saves)
	}
	replay, err := fx.svc.PowerUpHero(context.Background(), testActor(t), h.PartnerID, op)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || fx.ps.saves != 1 {
		t.Fatalf("replay=%+v saves=%d", replay, fx.ps.saves)
	}
}

func TestPowerUpHeroRejectsMID57ReceiptBranchOnReplay(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Equipment[0] = 1
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	op := testOp(t, "a1a1a1a1-a1a1-41a1-81a1-a1a1a1a1a1a1")
	if _, err := fx.svc.PowerUpHero(context.Background(), testActor(t), h.PartnerID, op); err != nil {
		t.Fatal(err)
	}
	corruptPromotionReceiptBranch(t, fx.rr, HeroPromotionMID57Promote)
	if _, err := fx.svc.PowerUpHero(context.Background(), testActor(t), h.PartnerID, op); err == nil || err.Error() != "character hero: MID51 receipt branch mismatch" {
		t.Fatalf("err=%v", err)
	}
}

func TestOneClickJinjieRejectsMID51ReceiptBranchOnReplay(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	fx.i5.stacks[20001005] = economy.StackState{PlayerID: h.PlayerID, ItemID: 20001005, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	op := testOp(t, "a2a2a2a2-a2a2-42a2-82a2-a2a2a2a2a2a2")
	if _, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, op); err != nil {
		t.Fatal(err)
	}
	corruptPromotionReceiptBranch(t, fx.rr, HeroPromotionMID51Promote)
	if _, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, op); err == nil || err.Error() != "character hero: MID57 receipt branch mismatch" {
		t.Fatalf("err=%v", err)
	}
}

func TestOneClickJinjieBelowCapRequiresCompletePlanAndPromotesAtomically(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	fx.i5.stacks[20001005] = economy.StackState{PlayerID: h.PlayerID, ItemID: 20001005, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	op := testOp(t, "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")
	got, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.Branch != HeroPromotionMID57Promote || got.ToColor != 2 || got.Equipment[0] != 0 || got.StateVersion != 2 || got.ManaAfter != nil {
		t.Fatalf("result=%+v", got)
	}
	if _, ok := fx.i5.stacks[20001005]; ok {
		t.Fatal("planned equipment resource was not consumed")
	}
	if len(fx.rr.m) != 1 {
		t.Fatalf("outer receipts=%d", len(fx.rr.m))
	}
	for _, rr := range fx.rr.m {
		if gotPolicy, ok := rr.OperationPolicyRefs.Get(heroPromotionMaxColorPolicyRef); !ok || gotPolicy != "test-max-color-v1" {
			t.Fatalf("max-color policy ref=(%q,%v)", gotPolicy, ok)
		}
	}
}

func TestOneClickJinjieAtCapCollectsWithoutPromotionOrFumoReset(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Color = 5
	positions := emptyPromotionPositions(h.TableID, 5)
	positions[[3]int64{h.TableID, 5, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 5, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	fx.i5.stacks[20001005] = economy.StackState{PlayerID: h.PlayerID, ItemID: 20001005, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	got, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, testOp(t, "cccccccc-cccc-4ccc-8ccc-cccccccccccc"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Branch != HeroPromotionMID57Collect || got.FromColor != 5 || got.ToColor != 5 || got.Equipment[0] != 1 || got.StateVersion != 2 || len(got.RestoreItems) != 0 {
		t.Fatalf("result=%+v", got)
	}
}

func TestOneClickJinjieNoMissingOrdinarySlotFailsClosed(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Equipment[0] = 1
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	_, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, testOp(t, "dddddddd-dddd-4ddd-8ddd-dddddddddddd"))
	if !errors.Is(err, ErrHeroPromotionPrerequisites) || fx.ps.saves != 0 || fx.i5.writes != 0 {
		t.Fatalf("err=%v saves=%d i5writes=%d", err, fx.ps.saves, fx.i5.writes)
	}
}

func TestPromotionRejectsRawFumoOnUncollectedOrdinarySlot(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Fumo[0] = 10
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	_, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, testOp(t, "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"))
	if !errors.Is(err, ErrHeroPromotionCorruptState) {
		t.Fatalf("err=%v", err)
	}
}

var _ appi5.Store = (*promotionI5Store)(nil)
var _ MaxHeroColorPolicyProvider = promotionMaxColor{}
var _ = grant.StackItem

func TestPowerUpHeroRestoresDestroyedOrdinaryFumoExactlyOnce(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Equipment[0] = 1
	h.Fumo[0] = 200
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	fx.fumo.targets[20001005] = character.HeroFumoTarget{ItemID: 20001005, ThresholdIncrements: []int64{200}, TotalCap: 200, StageDeltaByAttr: []map[int64]string{{}}}
	fx.promo.eligible[20001005] = 2
	fx.svc.Fumo = fx.fumo
	fx.svc.Promotion = fx.promo
	op := testOp(t, "abababab-abab-4bab-8bab-abababababab")
	got, err := fx.svc.PowerUpHero(context.Background(), testActor(t), h.PartnerID, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.Fumo[0] != 0 || len(got.RestoreItems) != 1 || got.RestoreItems[0].TableID != 50001007 || got.RestoreItems[0].ItemNum != 1 {
		t.Fatalf("result=%+v", got)
	}
	if st, ok := fx.i5.stacks[50001007]; !ok || st.Quantity != 1 {
		t.Fatalf("restoration stack=(%+v,%v)", st, ok)
	}
	writes := fx.i5.writes
	replay, err := fx.svc.PowerUpHero(context.Background(), testActor(t), h.PartnerID, op)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || fx.i5.writes != writes || fx.ps.saves != 1 {
		t.Fatalf("replay=%+v writes=%d/%d saves=%d", replay, fx.i5.writes, writes, fx.ps.saves)
	}
}

func TestOneClickJinjieCollectBranchReturnsAuthoritativeManaAfterWhenComposeManaDebited(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Color = 5
	positions := emptyPromotionPositions(h.TableID, 5)
	positions[[3]int64{h.TableID, 5, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 5, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	primitives := map[int64]character.EquipmentPrimitive{
		20001005: {ItemID: 20001005, RequiredLevel: 1, ComposeMana: 10},
		30000001: {ItemID: 30000001, RequiredLevel: 0},
	}
	fx := makePromotionFixture(t, h, positions, primitives, 5)
	fx.eq.edges[20001005] = []character.EquipmentRecipeEdge{{ParentItemID: 20001005, Ordinal: 1, ComponentItemID: 30000001, ComponentCount: 1}}
	fx.svc.Equipment = fx.eq
	fx.i5.stacks[30000001] = economy.StackState{PlayerID: h.PlayerID, ItemID: 30000001, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	got, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, testOp(t, "bcbcbcbc-bcbc-4cbc-8cbc-bcbcbcbcbcbc"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Branch != HeroPromotionMID57Collect || got.ManaAfter == nil || *got.ManaAfter != 990 || fx.i5.mana.Amount != 990 {
		t.Fatalf("result=%+v mana=%+v", got, fx.i5.mana)
	}
}

func TestOneClickJinjieIncompletePlanFailsBeforeAnyI5Write(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	positions[[3]int64{h.TableID, 1, 2}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 2, ItemID: 20001006, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{
		20001005: {ItemID: 20001005, RequiredLevel: 1},
		20001006: {ItemID: 20001006, RequiredLevel: 1},
	}, 5)
	fx.i5.stacks[20001005] = economy.StackState{PlayerID: h.PlayerID, ItemID: 20001005, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	_, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, testOp(t, "cdcdcdcd-cdcd-4dcd-8dcd-cdcdcdcdcdcd"))
	if !errors.Is(err, ErrHeroPromotionPrerequisites) || fx.i5.writes != 0 || fx.ps.saves != 0 {
		t.Fatalf("err=%v i5writes=%d saves=%d", err, fx.i5.writes, fx.ps.saves)
	}
}

func TestOneClickJinjiePotionEXPAndPromotionRemainOneHeroVersion(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 1, 0, now)
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 3}}, 5)
	fx.i5.stacks[20001005] = economy.StackState{PlayerID: h.PlayerID, ItemID: 20001005, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	fx.i5.stacks[50001001] = economy.StackState{PlayerID: h.PlayerID, ItemID: 50001001, Quantity: 1, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	got, err := fx.svc.OneClickJinjie(context.Background(), testActor(t), h.PartnerID, testOp(t, "dededede-dede-4ede-8ede-dededededede"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Level != 3 || got.Exp != 60 || got.StateVersion != 2 || got.ToColor != 2 {
		t.Fatalf("result=%+v", got)
	}
}

func TestPowerUpHeroPreexistingNestedRestorationReceiptFailsClosed(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Equipment[0] = 1
	h.Fumo[0] = 200
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	fx.fumo.targets[20001005] = character.HeroFumoTarget{ItemID: 20001005, ThresholdIncrements: []int64{200}, TotalCap: 200, StageDeltaByAttr: []map[int64]string{{}}}
	fx.promo.eligible[20001005] = 2
	fx.svc.Fumo = fx.fumo
	fx.svc.Promotion = fx.promo
	actor := testActor(t)
	bound, _, err := fx.svc.bindPromotionContent(context.Background(), testOp(t, "efefefef-efef-4fef-8fef-efefefefefef"), false)
	if err != nil {
		t.Fatal(err)
	}
	source, err := characterasset.HeroPromotionRestorationSource(h.PartnerID, 1, 2, HeroPromotionRestorationPolicyVersion)
	if err != nil {
		t.Fatal(err)
	}
	plan := grant.Plan{PlayerID: h.PlayerID, Source: source, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50001007, Amount: 1}}}
	if _, err := fx.i5svc.SettleGrantTx(context.Background(), &fakeTx{}, actor, plan, bound, appi5.GrantTxOptions{AllowOverflowMail: true}); err != nil {
		t.Fatal(err)
	}
	_, err = fx.svc.PowerUpHero(context.Background(), actor, h.PartnerID, testOp(t, "f1f1f1f1-f1f1-41f1-81f1-f1f1f1f1f1f1"))
	if !errors.Is(err, appi5.ErrStrictRestorationAlreadySettled) || fx.ps.saves != 0 {
		t.Fatalf("err=%v saves=%d", err, fx.ps.saves)
	}
}

func TestPowerUpHeroUnknownCommitReceiptReconcilesWithoutReapply(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Equipment[0] = 1
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	db := &commitErrorDB{err: errors.New("commit acknowledgement lost")}
	fx.svc.Runner = tx.Runner{DB: db}
	got, err := fx.svc.PowerUpHero(context.Background(), testActor(t), h.PartnerID, testOp(t, "f2f2f2f2-f2f2-42f2-82f2-f2f2f2f2f2f2"))
	if err != nil {
		t.Fatal(err)
	}
	if got.ToColor != 2 || db.begins != 1 || fx.ps.saves != 1 {
		t.Fatalf("got=%+v begins=%d saves=%d", got, db.begins, fx.ps.saves)
	}
}

func TestPowerUpHeroUnknownCommitWithoutOuterReceiptDoesNotBlindRetry(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 3, 60, now)
	h.Equipment[0] = 1
	positions := emptyPromotionPositions(h.TableID, 1)
	positions[[3]int64{h.TableID, 1, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 1, Slot: 1, ItemID: 20001005, OrdinaryEligible: true}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, 2, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: 2, Slot: slot}
	}
	fx := makePromotionFixture(t, h, positions, map[int64]character.EquipmentPrimitive{20001005: {ItemID: 20001005, RequiredLevel: 1}}, 5)
	db := &commitErrorDB{err: errors.New("commit acknowledgement lost")}
	fx.svc.Runner = tx.Runner{DB: db}
	fx.svc.ReceiptRead = missingProgressionReceiptReader{}
	_, err := fx.svc.PowerUpHero(context.Background(), testActor(t), h.PartnerID, testOp(t, "f3f3f3f3-f3f3-43f3-83f3-f3f3f3f3f3f3"))
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) || db.begins != 1 || fx.ps.saves != 1 {
		t.Fatalf("err=%v begins=%d saves=%d", err, db.begins, fx.ps.saves)
	}
}

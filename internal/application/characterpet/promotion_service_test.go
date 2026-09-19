package characterpet

import (
	"context"
	"errors"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/application/characterasset"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const petPromotionTestRevision = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

type petPromotionTestContent struct {
	eligible     map[int64]int64
	policy       character.PromotionRestorationPolicy
	wantRevision string
}

func (c petPromotionTestContent) PetPromotionRestorationRevision(_ context.Context, revision string) (bool, error) {
	return c.wantRevision == "" || revision == c.wantRevision, nil
}
func (c petPromotionTestContent) PetPromotionRestorationEligibilityTx(_ context.Context, _ tx.Queryer, revision string, itemID character.EquipmentTemplateID) (character.PetPromotionRestorationEligibility, error) {
	if c.wantRevision != "" && revision != c.wantRevision {
		return character.PetPromotionRestorationEligibility{}, errors.New("Pet promotion eligibility revision mismatch")
	}
	q, ok := c.eligible[int64(itemID)]
	if !ok {
		return character.PetPromotionRestorationEligibility{}, errors.New("missing Pet promotion eligibility")
	}
	return character.PetPromotionRestorationEligibility{ItemID: itemID, SourceQuality: q}, nil
}
func (c petPromotionTestContent) PromotionRestorationPolicyTx(_ context.Context, _ tx.Queryer, revision string) (character.PromotionRestorationPolicy, error) {
	if c.wantRevision != "" && revision != c.wantRevision {
		return character.PromotionRestorationPolicy{}, errors.New("Pet promotion policy revision mismatch")
	}
	return c.policy, nil
}

type petPromotionEquipmentContent struct {
	*petEquipmentTestContent
	wantRevision string
}

func (c petPromotionEquipmentContent) PetEquipmentRevision(_ context.Context, revision string) (bool, error) {
	return c.wantRevision == "" || revision == c.wantRevision, nil
}

func petPromotionPolicyForTest() character.PromotionRestorationPolicy {
	return character.PromotionRestorationPolicy{
		Fractions: []character.PromotionRestorationFraction{
			{Quality: 2, Numerator: 1, Denominator: 1},
			{Quality: 3, Numerator: 3, Denominator: 8},
			{Quality: 4, Numerator: 9, Denominator: 50},
			{Quality: 5, Numerator: 9, Denominator: 100},
			{Quality: 6, Numerator: 9, Denominator: 200},
		},
		Denominations: []character.PromotionRestorationDenomination{
			{ItemID: 50001007, Ordinal: 0, Value: 200},
			{ItemID: 50001006, Ordinal: 1, Value: 60},
			{ItemID: 50001003, Ordinal: 2, Value: 10},
		},
	}
}

type petPromotionStrictFake struct {
	prepareN  int
	applyN    int
	lastPlan  grant.Plan
	awards    []appi5.Award
	prepErr   error
	applyErr  error
	onPrepare func()
}

func (s *petPromotionStrictFake) PrepareStrictRestorationTx(_ context.Context, _ tx.Tx, _ identity.ActorContext, req appi5.StrictRestorationRequest, _ operation.Context) (*appi5.PreparedStrictRestoration, error) {
	s.prepareN++
	s.lastPlan = req.Plan
	if s.onPrepare != nil {
		s.onPrepare()
	}
	if s.prepErr != nil {
		return nil, s.prepErr
	}
	return &appi5.PreparedStrictRestoration{}, nil
}
func (s *petPromotionStrictFake) ApplyStrictRestorationTx(_ context.Context, _ tx.Tx, _ *appi5.PreparedStrictRestoration) (appi5.GrantResult, error) {
	s.applyN++
	if s.applyErr != nil {
		return appi5.GrantResult{}, s.applyErr
	}
	return appi5.GrantResult{Awards: append([]appi5.Award(nil), s.awards...)}, nil
}

func petPromotionPositions(tableID, color int64) map[[3]int64]character.PetEquipmentPosition {
	return map[[3]int64]character.PetEquipmentPosition{
		{tableID, color, 1}: {PetTableID: tableID, Color: color, Slot: 1, ItemID: 80001002, Classification: character.PetEquipmentOrdinary},
		{tableID, color, 2}: {PetTableID: tableID, Color: color, Slot: 2, ItemID: 90001001, Classification: character.PetEquipmentAwakening},
		{tableID, color, 3}: {PetTableID: tableID, Color: color, Slot: 3, Classification: character.PetEquipmentEmpty},
	}
}

func petPromotionFixture(t *testing.T) (Service, *caStore, *petEquipmentTestContent, *petPromotionStrictFake) {
	t.Helper()
	svc, st, _, _, _ := progressionFixture(t)
	p := st.byID[1]
	p.Equipment = character.PetEquipmentSlots{1, 1, 1}
	p.Fumo = character.PetFumoSlots{200, 123, 77}
	st.byID[1] = p
	eq := &petEquipmentTestContent{positions: petPromotionPositions(p.TableID, p.Color)}
	promo := petPromotionTestContent{eligible: map[int64]int64{80001002: 2}, policy: petPromotionPolicyForTest(), wantRevision: petPromotionTestRevision}
	strict := &petPromotionStrictFake{awards: []appi5.Award{{TableID: 50001007, ItemNum: 1}}}
	svc.Equipment = petPromotionEquipmentContent{petEquipmentTestContent: eq, wantRevision: petPromotionTestRevision}
	svc.Promotion = promo
	svc.StrictRestoration = strict
	svc.RestorationModifier = characterasset.IdentityRestorationModifier{}
	return svc, st, eq, strict
}

func TestPetAdvanceClearsOnlyOrdinaryAndReplaysOuterReceipt(t *testing.T) {
	svc, st, _, strict := petPromotionFixture(t)
	// MID785 has no material/Mana/Pet-EXP debit path. Keep unrelated debit ports
	// absent so a future accidental dependency fails this focused test.
	svc.Acquisition = nil
	svc.MaterialCosts = nil
	svc.Scalar = nil
	svc.PetExp = nil
	svc.EquipmentResources = nil
	strict.onPrepare = func() {
		if st.lockCalls == 0 {
			t.Fatal("strict restoration prepared before Pet430 owner lock")
		}
	}
	before := st.byID[1]
	op := caOp(t, "51515151-5151-4151-8151-515151515151", 4100)
	got, err := svc.Advance(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	after := st.byID[1]
	if got.FromColor != 1 || got.ToColor != 2 || got.StateVersion != before.StateVersion+1 || after.Color != 2 || after.StateVersion != before.StateVersion+1 {
		t.Fatalf("promotion result=%+v after=%+v", got, after)
	}
	if after.Equipment != (character.PetEquipmentSlots{0, 1, 1}) || after.Fumo != (character.PetFumoSlots{0, 123, 77}) {
		t.Fatalf("ordinary/special clearing mismatch: equipment=%v fumo=%v", after.Equipment, after.Fumo)
	}
	if after.Skills != before.Skills || after.Level != before.Level || after.Exp != before.Exp {
		t.Fatalf("promotion mutated raw progression/skills: before=%+v after=%+v", before, after)
	}
	wantLines := []grant.Line{{Kind: grant.StackItem, ItemID: 50001007, Amount: 1}}
	if strict.prepareN != 1 || strict.applyN != 1 || !reflect.DeepEqual(strict.lastPlan.Lines, wantLines) {
		t.Fatalf("restoration prepare/apply=%d/%d plan=%+v", strict.prepareN, strict.applyN, strict.lastPlan)
	}
	if len(got.RestoreItems) != 1 || got.RestoreItems[0].TableID != 50001007 || got.RestoreItems[0].ItemNum != 1 {
		t.Fatalf("restore result=%+v", got.RestoreItems)
	}

	got2, err := svc.Advance(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got2.Replayed || strict.prepareN != 1 || strict.applyN != 1 || st.byID[1] != after {
		t.Fatalf("same-operation replay reapplied: result=%+v prepare/apply=%d/%d pet=%+v", got2, strict.prepareN, strict.applyN, st.byID[1])
	}
}

func TestPetAdvancePrerequisitesAndQ1FailClosedBeforeMutation(t *testing.T) {
	t.Run("max-color", func(t *testing.T) {
		svc, st, _, strict := petPromotionFixture(t)
		p := st.byID[1]
		p.Color = 16
		st.byID[1] = p
		before := st.byID[1]
		_, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "52525252-5252-4252-8252-525252525252", 4101))
		if !errors.Is(err, ErrPetPromotionUnavailable) || st.byID[1] != before || strict.prepareN != 0 {
			t.Fatalf("err=%v pet=%+v strict=%d", err, st.byID[1], strict.prepareN)
		}
	})

	t.Run("ordinary-not-collected", func(t *testing.T) {
		svc, st, _, strict := petPromotionFixture(t)
		p := st.byID[1]
		p.Equipment[0] = 0
		st.byID[1] = p
		before := st.byID[1]
		_, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "53535353-5353-4353-8353-535353535353", 4102))
		if !errors.Is(err, ErrPetPromotionPrerequisites) || st.byID[1] != before || strict.prepareN != 0 {
			t.Fatalf("err=%v pet=%+v strict=%d", err, st.byID[1], strict.prepareN)
		}
	})

	t.Run("q1-nonzero", func(t *testing.T) {
		svc, st, _, strict := petPromotionFixture(t)
		svc.Promotion = petPromotionTestContent{eligible: map[int64]int64{80001002: 1}, policy: petPromotionPolicyForTest(), wantRevision: petPromotionTestRevision}
		before := st.byID[1]
		_, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "54545454-5454-4454-8454-545454545454", 4103))
		if !errors.Is(err, ErrPetPromotionQ1Unsupported) || st.byID[1] != before || strict.prepareN != 0 {
			t.Fatalf("err=%v pet=%+v strict=%d", err, st.byID[1], strict.prepareN)
		}
	})

	t.Run("q1-zero-is-allowed", func(t *testing.T) {
		svc, st, _, strict := petPromotionFixture(t)
		p := st.byID[1]
		p.Fumo[0] = 0
		st.byID[1] = p
		svc.Promotion = petPromotionTestContent{eligible: map[int64]int64{80001002: 1}, policy: petPromotionPolicyForTest(), wantRevision: petPromotionTestRevision}
		got, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "55555555-5555-4555-8555-555555555555", 4104))
		if err != nil {
			t.Fatal(err)
		}
		if got.ToColor != 2 || strict.prepareN != 0 || len(got.RestoreItems) != 0 {
			t.Fatalf("got=%+v strict=%d", got, strict.prepareN)
		}
	})
}

func TestPetAdvanceSpecialAndEmptySlotsAreNotOrdinaryPrerequisites(t *testing.T) {
	svc, st, _, strict := petPromotionFixture(t)
	p := st.byID[1]
	p.Equipment = character.PetEquipmentSlots{1, 0, 0}
	p.Fumo = character.PetFumoSlots{200, 123, 77}
	st.byID[1] = p
	got, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "58585858-5858-4858-8858-585858585858", 4107))
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment != (character.PetEquipmentSlots{0, 0, 0}) || got.Fumo != (character.PetFumoSlots{0, 123, 77}) || strict.prepareN != 1 {
		t.Fatalf("special/empty prerequisite or preservation mismatch: got=%+v strict=%d", got, strict.prepareN)
	}
}

func TestPetAdvanceFreshOperationRevalidatesCanonicalState(t *testing.T) {
	svc, st, eq, strict := petPromotionFixture(t)
	p := st.byID[1]
	eq.positions[[3]int64{p.TableID, 2, 1}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 1, ItemID: 80001003, Classification: character.PetEquipmentOrdinary}
	eq.positions[[3]int64{p.TableID, 2, 2}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 2, ItemID: 90001002, Classification: character.PetEquipmentAwakening}
	eq.positions[[3]int64{p.TableID, 2, 3}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 3, Classification: character.PetEquipmentEmpty}

	if _, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "59595959-5959-4959-8959-595959595959", 4108)); err != nil {
		t.Fatal(err)
	}
	afterFirst := st.byID[1]
	_, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "60606060-6060-4060-8060-606060606060", 4109))
	if !errors.Is(err, ErrPetPromotionPrerequisites) {
		t.Fatalf("fresh operation did not revalidate cleared ordinary state: err=%v", err)
	}
	if st.byID[1] != afterFirst || strict.prepareN != 1 || strict.applyN != 1 {
		t.Fatalf("fresh retry mutated again: before=%+v after=%+v prepare/apply=%d/%d", afterFirst, st.byID[1], strict.prepareN, strict.applyN)
	}
}

func TestPetPromotionRestorationUsesRawOrdinaryFumoIndependentOfCollectedBit(t *testing.T) {
	svc, st, _, strict := petPromotionFixture(t)
	p := st.byID[1]
	p.Equipment[0] = 0 // A10: restoration input is independent from collected bit.
	positions, err := svc.loadPetPromotionPositionsTx(context.Background(), caTx{}, petPromotionTestRevision, p)
	if err != nil {
		t.Fatal(err)
	}
	plan, err := svc.buildPetPromotionRestorationPlanTx(context.Background(), caTx{}, caActor(t), petPromotionTestRevision, p, positions, caOp(t, "56565656-5656-4656-8656-565656565656", 4105))
	if err != nil {
		t.Fatal(err)
	}
	if plan == nil || !reflect.DeepEqual(plan.Lines, []grant.Line{{Kind: grant.StackItem, ItemID: 50001007, Amount: 1}}) {
		t.Fatalf("plan=%+v", plan)
	}
	if strict.prepareN != 0 || strict.applyN != 0 {
		t.Fatalf("plan construction settled restoration: %d/%d", strict.prepareN, strict.applyN)
	}
}

func TestPetAdvanceRejectsCorruptCurrentColorTopology(t *testing.T) {
	svc, st, eq, strict := petPromotionFixture(t)
	p := st.byID[1]
	bad := eq.positions[[3]int64{p.TableID, p.Color, 1}]
	bad.Color = p.Color + 1
	eq.positions[[3]int64{p.TableID, p.Color, 1}] = bad
	before := st.byID[1]
	_, err := svc.Advance(context.Background(), caActor(t), 1, caOp(t, "57575757-5757-4757-8757-575757575757", 4106))
	if !errors.Is(err, ErrPetPromotionCorruptState) || st.byID[1] != before || strict.prepareN != 0 {
		t.Fatalf("err=%v pet=%+v strict=%d", err, st.byID[1], strict.prepareN)
	}
}

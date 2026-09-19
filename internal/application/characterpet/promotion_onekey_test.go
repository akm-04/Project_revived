package characterpet

import (
	"context"
	"errors"
	"reflect"
	"sync"
	"testing"
	"time"
	"unsafe"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type petPromotionResourcesNever struct{ prepareN, applyN int }

func (f *petPromotionResourcesNever) PreparePromotionResourcesTx(context.Context, tx.Tx, identity.ActorContext, appi5.PromotionResourceRequest, operation.Context) (*appi5.PreparedPromotionResources, error) {
	f.prepareN++
	return nil, errors.New("unexpected promotion resource prepare")
}
func (f *petPromotionResourcesNever) ApplyPromotionResourcesTx(context.Context, tx.Tx, *appi5.PreparedPromotionResources, appi5.PromotionResourceDebit) (appi5.PromotionResourceResult, error) {
	f.applyN++
	return appi5.PromotionResourceResult{}, errors.New("unexpected promotion resource apply")
}

func TestPetOneKeyAdvanceFreshNoMissingRejectsBeforeI5(t *testing.T) {
	svc, st, eq, _ := petPromotionFixture(t)
	p := st.byID[1]
	p.Equipment = character.PetEquipmentSlots{1, 1, 1}
	st.byID[1] = p
	// loadPetOneKeyContentTx still reads potion content and compatibility through
	// the accepted CA4-4A seams, but it must not discover/debit an I5 suffix when
	// there is no missing ordinary work.
	prog := svc.Progression.(*caProgression)
	prog.maxLevel = 2
	prog.threshold = []ExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}}
	eq.compatibility = []character.EquipmentCompatibilityExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}}
	never := &petPromotionResourcesNever{}
	svc.PromotionResources = never
	before := st.byID[1]
	_, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, caOp(t, "71717171-7171-4171-8171-717171717171", 4300))
	if !errors.Is(err, ErrPetPromotionPrerequisites) {
		t.Fatalf("err=%v", err)
	}
	if never.prepareN != 0 || never.applyN != 0 || st.byID[1] != before {
		t.Fatalf("no-work path touched I5/state: prepare/apply=%d/%d pet=%+v", never.prepareN, never.applyN, st.byID[1])
	}
}

func TestApplyPetOneKeyAdvanceStatePromoteClearsOrdinaryOnlyAndAppliesRealPetExp(t *testing.T) {
	p := character.Pet{PlayerID: identity.PlayerID(7), PetID: 1, TableID: 10030001, OriginTableID: 10030001, Star: 1, Level: 1, Exp: 0, Color: 1, IsShow: true, Equipment: character.PetEquipmentSlots{0, 1, 0}, Fumo: character.PetFumoSlots{200, 123, 77}, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: petPromotionTestRevision, StateVersion: 9, CreatedAt: caOp(t, "72727272-7272-4272-8272-727272727272", 4301).StartedAt, UpdatedAt: caOp(t, "72727272-7272-4272-8272-727272727272", 4301).StartedAt}
	positions := [character.PetEquipmentSlotCount]character.PetEquipmentPosition{
		{PetTableID: p.TableID, Color: 1, Slot: 1, ItemID: 80001002, Classification: character.PetEquipmentOrdinary},
		{PetTableID: p.TableID, Color: 1, Slot: 2, ItemID: 90001001, Classification: character.PetEquipmentAwakening},
		{PetTableID: p.TableID, Color: 1, Slot: 3, Classification: character.PetEquipmentEmpty},
	}
	plan := petEquipmentPlan{Selected: []int64{1}, StackDebits: map[int64]int64{80001002: 1, 50001087: 2}, PotionDebits: map[int64]int64{50001087: 2}, PotionEXPGranted: 30}
	thresholds := []ExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}}
	op := caOp(t, "73737373-7373-4373-8373-737373737373", 4302)
	got, err := applyPetOneKeyAdvanceState(p, positions, plan, true, 2, thresholds, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.Color != 2 || got.Level != 2 || got.Exp != 30 || got.StateVersion != 10 {
		t.Fatalf("progression/transition=%+v", got)
	}
	if got.Equipment != (character.PetEquipmentSlots{0, 1, 0}) || got.Fumo != (character.PetFumoSlots{0, 123, 77}) {
		t.Fatalf("ordinary/special/empty transition equipment=%v fumo=%v", got.Equipment, got.Fumo)
	}
	if got.Skills != p.Skills {
		t.Fatalf("one-key promotion mutated raw skills: before=%v after=%v", p.Skills, got.Skills)
	}
}

func TestApplyPetOneKeyAdvanceStateColor16CollectPreservesColorAndFumo(t *testing.T) {
	now := caOp(t, "74747474-7474-4474-8474-747474747474", 4303).StartedAt
	p := character.Pet{PlayerID: identity.PlayerID(7), PetID: 1, TableID: 10030001, OriginTableID: 10030001, Star: 1, Level: 2, Exp: 55, Color: 16, IsShow: true, Equipment: character.PetEquipmentSlots{0, 1, 0}, Fumo: character.PetFumoSlots{200, 123, 77}, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: petPromotionTestRevision, StateVersion: 4, CreatedAt: now, UpdatedAt: now}
	positions := [character.PetEquipmentSlotCount]character.PetEquipmentPosition{
		{PetTableID: p.TableID, Color: 16, Slot: 1, ItemID: 80001002, Classification: character.PetEquipmentOrdinary},
		{PetTableID: p.TableID, Color: 16, Slot: 2, ItemID: 90001001, Classification: character.PetEquipmentAwakening},
		{PetTableID: p.TableID, Color: 16, Slot: 3, Classification: character.PetEquipmentEmpty},
	}
	plan := petEquipmentPlan{Selected: []int64{1}, StackDebits: map[int64]int64{80001002: 1}, PotionDebits: map[int64]int64{}}
	got, err := applyPetOneKeyAdvanceState(p, positions, plan, false, 2, []ExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}}, caOp(t, "75757575-7575-4575-8575-757575757575", 4304))
	if err != nil {
		t.Fatal(err)
	}
	if got.Color != 16 || got.Equipment != (character.PetEquipmentSlots{1, 1, 0}) || got.Fumo != p.Fumo || got.StateVersion != 5 {
		t.Fatalf("max-color collect=%+v", got)
	}
}

func TestPetOneKeyAllOrNothingSlotEqualityAndResourceClosureBound(t *testing.T) {
	if equalPetSlots([]int64{1}, []int64{1, 3}) {
		t.Fatal("partial planner selection accepted as complete")
	}
	if !equalPetSlots([]int64{1, 3}, []int64{1, 3}) {
		t.Fatal("complete planner selection rejected")
	}
	closure := make([]int64, 46)
	for i := range closure {
		closure[i] = int64(1000 + i)
	}
	plan := &grant.Plan{PlayerID: identity.PlayerID(7), Source: grant.SourceIdentity{Domain: "TEST", Operation: "BOUND", BusinessKey: "x", PolicyVersion: "v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50001007, Amount: 1}, {Kind: grant.StackItem, ItemID: 50001006, Amount: 1}, {Kind: grant.StackItem, ItemID: 50001003, Amount: 1}}}
	if err := validatePetPromotionResourceBound(closure, plan); err == nil {
		t.Fatal("49-identity promotion closure accepted")
	}
	if err := validatePetPromotionResourceBound(closure[:45], plan); err != nil {
		t.Fatalf("48-identity promotion closure rejected: %v", err)
	}
}

func TestPetOneKeyReceiptBranchesAreStrictAndNeverInventWireState(t *testing.T) {
	base := OneKeyAdvanceResult{PetID: 1, Branch: petOneKeyBranchPromote, FromColor: 1, ToColor: 2, Level: 2, Exp: 55, Equipment: character.PetEquipmentSlots{0, 1, 0}, Fumo: character.PetFumoSlots{0, 12, 13}, RestoreItems: []appi5.Award{{TableID: 50001007, ItemNum: 1}}, StateVersion: 2}
	r := petOneKeyReceiptFromResult(base)
	if !reflect.DeepEqual(r.RestoreItems, base.RestoreItems) || r.Branch != petOneKeyBranchPromote {
		t.Fatalf("receipt=%+v", r)
	}
	collect := petOneKeyPromotionReceipt{PetID: 1, Branch: petOneKeyBranchCollect, FromColor: 16, ToColor: 16, Level: 2, Exp: 55, Equipment: character.PetEquipmentSlots{1, 1, 0}, Fumo: character.PetFumoSlots{9, 8, 7}, StateVersion: 3}
	if got := collect.result(false); got.Branch != petOneKeyBranchCollect || len(got.RestoreItems) != 0 || got.Fumo != collect.Fumo {
		t.Fatalf("collect result=%+v", got)
	}
}

// CA4-4B I4 keeps I5's prepared resource object intentionally opaque. These
// helpers populate only the read-only planning snapshot in tests, without
// adding a production constructor or widening the I5 API just for fixtures.
func setPetOneKeyPrivateField(dst reflect.Value, value reflect.Value) {
	reflect.NewAt(dst.Type(), unsafe.Pointer(dst.UnsafeAddr())).Elem().Set(value)
}

func preparedPromotionForPetOneKeyTest(t interface{ Helper() }, actor identity.ActorContext, playerLevel, mana int64, ids []int64, quantities map[int64]int64) *appi5.PreparedPromotionResources {
	t.Helper()
	p := &appi5.PreparedPromotionResources{}
	v := reflect.ValueOf(p).Elem()
	setPetOneKeyPrivateField(v.FieldByName("actor"), reflect.ValueOf(actor))
	setPetOneKeyPrivateField(v.FieldByName("playerLevel"), reflect.ValueOf(playerLevel))
	now := time.Unix(4400, 0).UTC()
	setPetOneKeyPrivateField(v.FieldByName("effectAt"), reflect.ValueOf(now))
	setPetOneKeyPrivateField(v.FieldByName("mana"), reflect.ValueOf(economy.ScalarBalance{PlayerID: actor.PlayerID, ResourceKey: "mana", Amount: mana, StateVersion: 1, UpdatedAt: now}))
	setPetOneKeyPrivateField(v.FieldByName("manaExists"), reflect.ValueOf(true))
	setPetOneKeyPrivateField(v.FieldByName("stackIDs"), reflect.ValueOf(append([]int64(nil), ids...)))

	stacksField := v.FieldByName("stacks")
	stacks := reflect.MakeMapWithSize(stacksField.Type(), len(ids))
	for _, id := range ids {
		elem := reflect.New(stacksField.Type().Elem()).Elem()
		qty := quantities[id]
		stateField := elem.FieldByName("state")
		setPetOneKeyPrivateField(stateField, reflect.ValueOf(economy.StackState{PlayerID: actor.PlayerID, ItemID: id, Quantity: qty, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}))
		setPetOneKeyPrivateField(elem.FieldByName("exists"), reflect.ValueOf(qty > 0))
		stacks.SetMapIndex(reflect.ValueOf(id), elem)
	}
	setPetOneKeyPrivateField(stacksField, stacks)
	return p
}

type petOneKeyPromotionResourcesFake struct {
	mu          sync.Mutex
	playerLevel int64
	mana        int64
	quantities  map[int64]int64
	awards      []appi5.Award
	prepareErr  error
	applyErr    error
	onPrepare   func()
	prepareN    int
	applyN      int
	committedN  int
	lastReq     appi5.PromotionResourceRequest
	lastDebit   appi5.PromotionResourceDebit
}

func (f *petOneKeyPromotionResourcesFake) PreparePromotionResourcesTx(_ context.Context, _ tx.Tx, actor identity.ActorContext, req appi5.PromotionResourceRequest, _ operation.Context) (*appi5.PreparedPromotionResources, error) {
	f.mu.Lock()
	f.prepareN++
	f.lastReq = req
	err := f.prepareErr
	onPrepare := f.onPrepare
	playerLevel, mana := f.playerLevel, f.mana
	quantities := make(map[int64]int64, len(f.quantities))
	for k, v := range f.quantities {
		quantities[k] = v
	}
	f.mu.Unlock()
	if onPrepare != nil {
		onPrepare()
	}
	if err != nil {
		return nil, err
	}
	return preparedPromotionForPetOneKeyTest(nilTestingT{}, actor, playerLevel, mana, req.PotentialStackItemIDs, quantities), nil
}

// nilTestingT supplies only the Helper method used by the fixture builder so
// Prepare can construct an opaque snapshot outside a *testing.T call frame.
type nilTestingT struct{}

func (nilTestingT) Helper() {}

func (f *petOneKeyPromotionResourcesFake) ApplyPromotionResourcesTx(_ context.Context, t tx.Tx, _ *appi5.PreparedPromotionResources, debit appi5.PromotionResourceDebit) (appi5.PromotionResourceResult, error) {
	f.mu.Lock()
	f.applyN++
	f.lastDebit = debit
	err := f.applyErr
	awards := append([]appi5.Award(nil), f.awards...)
	restorationRequested := f.lastReq.Restoration != nil
	f.mu.Unlock()
	if err != nil {
		return appi5.PromotionResourceResult{}, err
	}
	commit := func() { f.mu.Lock(); f.committedN++; f.mu.Unlock() }
	if at, ok := t.(*ca4aAtomicTx); ok {
		at.stage(commit)
	} else {
		commit()
	}
	out := appi5.PromotionResourceResult{}
	if restorationRequested && len(awards) != 0 {
		out.Restoration = &appi5.GrantResult{Awards: awards}
	}
	return out, nil
}

func (f *petOneKeyPromotionResourcesFake) counts() (prepare, apply, committed int) {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.prepareN, f.applyN, f.committedN
}

func configurePetOneKeyFixture(t *testing.T, color int64, quantity int64) (Service, *caStore, *petEquipmentTestContent, *petOneKeyPromotionResourcesFake) {
	t.Helper()
	svc, st, eq, _ := petPromotionFixture(t)
	p := st.byID[1]
	p.Color = color
	p.Equipment = character.PetEquipmentSlots{0, 1, 0}
	p.Fumo = character.PetFumoSlots{200, 123, 77}
	st.byID[1] = p
	eq.positions = petPromotionPositions(p.TableID, color)
	eq.primitives = map[int64]character.EquipmentPrimitive{80001002: {ItemID: 80001002, SourceItemType: 8, RequiredLevel: 1}}
	eq.edges = map[int64][]character.EquipmentRecipeEdge{}
	eq.compatibility = []character.EquipmentCompatibilityExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}}
	prog := svc.Progression.(*caProgression)
	prog.maxLevel = 2
	prog.threshold = []ExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}}
	resources := &petOneKeyPromotionResourcesFake{playerLevel: 100, mana: 100, quantities: map[int64]int64{80001002: quantity}, awards: []appi5.Award{{TableID: 50001007, ItemNum: 1}}}
	resources.onPrepare = func() {
		if st.lockCalls == 0 {
			t.Fatal("promotion resources prepared before Pet430 owner lock")
		}
	}
	svc.PromotionResources = resources
	return svc, st, eq, resources
}

func TestPetOneKeyAdvancePromoteUsesCompletePlanRestorationAndOuterReplay(t *testing.T) {
	svc, st, _, resources := configurePetOneKeyFixture(t, 1, 1)
	op := caOp(t, "76767676-7676-4676-8676-767676767676", 4401)
	before := st.byID[1]
	got, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.Branch != petOneKeyBranchPromote || got.FromColor != 1 || got.ToColor != 2 || got.StateVersion != before.StateVersion+1 {
		t.Fatalf("result=%+v", got)
	}
	after := st.byID[1]
	if after.Equipment != (character.PetEquipmentSlots{0, 1, 0}) || after.Fumo != (character.PetFumoSlots{0, 123, 77}) || after.Skills != before.Skills {
		t.Fatalf("promote transition before=%+v after=%+v", before, after)
	}
	prepare, apply, committed := resources.counts()
	if prepare != 1 || apply != 1 || committed != 1 || len(got.RestoreItems) != 1 {
		t.Fatalf("resource settlement prepare/apply/commit=%d/%d/%d restore=%+v", prepare, apply, committed, got.RestoreItems)
	}
	if resources.lastReq.Restoration == nil || !reflect.DeepEqual(resources.lastDebit.Stacks, []appi5.EquipmentStackDebit{{ItemID: 80001002, Count: 1}}) || resources.lastDebit.Mana != 0 {
		t.Fatalf("request/debit req=%+v debit=%+v", resources.lastReq, resources.lastDebit)
	}
	got2, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	p2, a2, c2 := resources.counts()
	if !got2.Replayed || p2 != 1 || a2 != 1 || c2 != 1 || st.byID[1] != after {
		t.Fatalf("same-operation replay reapplied: got=%+v counts=%d/%d/%d pet=%+v", got2, p2, a2, c2, st.byID[1])
	}
}

func TestPetOneKeyAdvanceColor16CollectHasNoRestorationAndPreservesFumo(t *testing.T) {
	svc, st, _, resources := configurePetOneKeyFixture(t, 16, 1)
	before := st.byID[1]
	got, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, caOp(t, "77777777-7777-4777-8777-777777777777", 4402))
	if err != nil {
		t.Fatal(err)
	}
	if got.Branch != petOneKeyBranchCollect || got.FromColor != 16 || got.ToColor != 16 || got.RestoreItems != nil {
		t.Fatalf("collect result=%+v", got)
	}
	after := st.byID[1]
	if after.Equipment != (character.PetEquipmentSlots{1, 1, 0}) || after.Fumo != before.Fumo || after.Color != 16 || after.Skills != before.Skills {
		t.Fatalf("collect transition before=%+v after=%+v", before, after)
	}
	if resources.lastReq.Restoration != nil {
		t.Fatalf("collect unexpectedly requested restoration: %+v", resources.lastReq.Restoration)
	}
}

func TestPetOneKeyAdvanceRejectsPartialPlanBeforeApply(t *testing.T) {
	svc, st, _, resources := configurePetOneKeyFixture(t, 1, 0)
	before := st.byID[1]
	_, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, caOp(t, "78787878-7878-4878-8878-787878787878", 4403))
	if !errors.Is(err, ErrPetPromotionPrerequisites) {
		t.Fatalf("err=%v", err)
	}
	prepare, apply, committed := resources.counts()
	if prepare != 1 || apply != 0 || committed != 0 || st.byID[1] != before {
		t.Fatalf("partial plan mutated: counts=%d/%d/%d before=%+v after=%+v", prepare, apply, committed, before, st.byID[1])
	}
}

func TestPetOneKeyAdvancePreexistingNestedRestorationFailsClosed(t *testing.T) {
	svc, st, _, resources := configurePetOneKeyFixture(t, 1, 1)
	resources.prepareErr = appi5.ErrStrictRestorationAlreadySettled
	before := st.byID[1]
	_, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, caOp(t, "79797979-7979-4979-8979-797979797979", 4404))
	if !errors.Is(err, appi5.ErrStrictRestorationAlreadySettled) || st.byID[1] != before {
		t.Fatalf("err=%v before=%+v after=%+v", err, before, st.byID[1])
	}
	_, apply, committed := resources.counts()
	if apply != 0 || committed != 0 {
		t.Fatalf("nested failure applied resources: %d/%d", apply, committed)
	}
}

func configureAtomicPetOneKey(t *testing.T, commitErr error, failReceipt bool) (Service, *caStore, *ca4aAtomicReceipts, *petOneKeyPromotionResourcesFake) {
	t.Helper()
	svc, base, eq, resources := configurePetOneKeyFixture(t, 1, 1)
	store := &ca4aAtomicStore{caStore: base}
	rec := newCA4AAtomicReceipts()
	rec.failPut = failReceipt
	svc.Runner = tx.Runner{DB: ca4aAtomicDB{commitErr: commitErr}}
	svc.Store = store
	svc.Receipts = rec
	svc.ReceiptRead = rec
	svc.Equipment = petPromotionEquipmentContent{petEquipmentTestContent: eq, wantRevision: petPromotionTestRevision}
	return svc, base, rec, resources
}

func TestPetOneKeyAdvanceLateOuterReceiptFailureRollsBackPetAndResources(t *testing.T) {
	svc, base, rec, resources := configureAtomicPetOneKey(t, nil, true)
	before := base.byID[1]
	_, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, caOp(t, "80808080-8080-4080-8080-808080808080", 4410))
	if err == nil || err.Error() != "test receipt write failure" {
		t.Fatalf("err=%v", err)
	}
	if base.byID[1] != before || len(rec.m) != 0 {
		t.Fatalf("rollback escaped pet=%+v receipts=%d", base.byID[1], len(rec.m))
	}
	prepare, apply, committed := resources.counts()
	if prepare != 1 || apply != 1 || committed != 0 {
		t.Fatalf("resource rollback counts=%d/%d/%d", prepare, apply, committed)
	}
}

func TestPetOneKeyAdvanceAmbiguousCommitOuterReceiptReconcilesWithoutReapply(t *testing.T) {
	svc, base, rec, resources := configureAtomicPetOneKey(t, errors.New("transport lost after commit"), false)
	op := caOp(t, "81818181-8181-4181-8181-818181818181", 4411)
	got, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got.Replayed || got.ToColor != 2 || base.byID[1].Color != 2 || len(rec.m) != 1 {
		t.Fatalf("reconciled=%+v pet=%+v receipts=%d", got, base.byID[1], len(rec.m))
	}
	p1, a1, c1 := resources.counts()
	if p1 != 1 || a1 != 1 || c1 != 1 {
		t.Fatalf("resource counts=%d/%d/%d", p1, a1, c1)
	}
	version := base.byID[1].StateVersion
	got2, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	p2, a2, c2 := resources.counts()
	if !got2.Replayed || base.byID[1].StateVersion != version || p2 != 1 || a2 != 1 || c2 != 1 {
		t.Fatalf("replay=%+v version=%d/%d counts=%d/%d/%d", got2, base.byID[1].StateVersion, version, p2, a2, c2)
	}
}

func TestPetOneKeyAdvanceAmbiguousCommitWithoutOuterReceiptIsUnknownNoBlindReplay(t *testing.T) {
	svc, base, _, resources := configureAtomicPetOneKey(t, errors.New("transport lost after commit"), false)
	svc.ReceiptRead = missingPetPromotionReceiptReader{}
	_, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, caOp(t, "82828282-8282-4282-8282-828282828282", 4412))
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatalf("err=%T %v", err, err)
	}
	_, _, committed := resources.counts()
	if base.byID[1].Color != 2 || base.byID[1].StateVersion != 2 || committed != 1 {
		t.Fatalf("committed ambiguous pet=%+v resources=%d", base.byID[1], committed)
	}
}

func TestPetOneKeyAdvanceConcurrentSamePetSerializesAndFreshRequestRevalidates(t *testing.T) {
	svc, base, eq, resources := configurePetOneKeyFixture(t, 1, 1)
	p := base.byID[1]
	eq.positions[[3]int64{p.TableID, 2, 1}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 1, ItemID: 80001003, Classification: character.PetEquipmentOrdinary}
	eq.positions[[3]int64{p.TableID, 2, 2}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 2, ItemID: 90001002, Classification: character.PetEquipmentAwakening}
	eq.positions[[3]int64{p.TableID, 2, 3}] = character.PetEquipmentPosition{PetTableID: p.TableID, Color: 2, Slot: 3, Classification: character.PetEquipmentEmpty}
	eq.primitives[80001003] = character.EquipmentPrimitive{ItemID: 80001003, SourceItemType: 8, RequiredLevel: 1}
	store := &ca4aAtomicStore{caStore: base}
	rec := newCA4AAtomicReceipts()
	var petMu sync.Mutex
	svc.Runner = tx.Runner{DB: ca4aAtomicDB{petMu: &petMu}}
	svc.Store = store
	svc.Receipts = rec
	svc.ReceiptRead = rec
	svc.Equipment = petPromotionEquipmentContent{petEquipmentTestContent: eq, wantRevision: petPromotionTestRevision}
	svc.Progression = &petOneKeyLockedProgression{p: svc.Progression.(*caProgression)}

	type result struct {
		got OneKeyAdvanceResult
		err error
	}
	start := make(chan struct{})
	out := make(chan result, 2)
	ops := []operation.Context{
		caOp(t, "83838383-8383-4383-8383-838383838383", 4413),
		caOp(t, "84848484-8484-4484-8484-848484848484", 4414),
	}
	for _, op := range ops {
		op := op
		go func() {
			<-start
			got, err := svc.OneKeyAdvance(context.Background(), caActor(t), 1, op)
			out <- result{got, err}
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
	_, _, committed := resources.counts()
	if success != 1 || rejected != 1 || base.byID[1].Color != 2 || base.byID[1].StateVersion != 2 || committed != 1 {
		t.Fatalf("success=%d rejected=%d pet=%+v resources=%d", success, rejected, base.byID[1], committed)
	}
}

type petOneKeyLockedProgression struct {
	mu sync.Mutex
	p  *caProgression
}

func (c *petOneKeyLockedProgression) PetProgressionActive(ctx context.Context) (string, bool, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetProgressionActive(ctx)
}
func (c *petOneKeyLockedProgression) PetProgressionRevision(ctx context.Context, rev string) (bool, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetProgressionRevision(ctx, rev)
}
func (c *petOneKeyLockedProgression) PetProgressionTemplateTx(ctx context.Context, q tx.Queryer, rev string, id int64) (ProgressionTemplate, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetProgressionTemplateTx(ctx, q, rev, id)
}
func (c *petOneKeyLockedProgression) PetSkillSlotsTx(ctx context.Context, q tx.Queryer, rev string, id int64) ([]SkillSlotDefinition, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetSkillSlotsTx(ctx, q, rev, id)
}
func (c *petOneKeyLockedProgression) PetExpItemTx(ctx context.Context, q tx.Queryer, rev string, id int64) (int64, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetExpItemTx(ctx, q, rev, id)
}
func (c *petOneKeyLockedProgression) PetExpPolicyTx(ctx context.Context, q tx.Queryer, rev string, max int64) ([]ExpThreshold, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetExpPolicyTx(ctx, q, rev, max)
}
func (c *petOneKeyLockedProgression) PetSkillBookCostTx(ctx context.Context, q tx.Queryer, rev string, level int64) (int64, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetSkillBookCostTx(ctx, q, rev, level)
}
func (c *petOneKeyLockedProgression) PetSkillSlotPolicyTx(ctx context.Context, q tx.Queryer, rev string, slot int64) (SkillSlotPolicy, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetSkillSlotPolicyTx(ctx, q, rev, slot)
}
func (c *petOneKeyLockedProgression) PetEvolutionCostTx(ctx context.Context, q tx.Queryer, rev string, target int64) (int64, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetEvolutionCostTx(ctx, q, rev, target)
}
func (c *petOneKeyLockedProgression) PetProgressionPolicyTx(ctx context.Context, q tx.Queryer, rev string) (ProgressionPolicy, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.PetProgressionPolicyTx(ctx, q, rev)
}
func (c *petOneKeyLockedProgression) CharacterMaxLevelTx(ctx context.Context, q tx.Queryer, rev string, level int64) (int64, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.p.CharacterMaxLevelTx(ctx, q, rev, level)
}

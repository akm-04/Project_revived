package characterpet

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const ca75TestRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

const (
	ca75PetOriginA = int64(10030001)
	ca75PetOriginB = int64(10040001)
	ca75StyleA     = int64(50001376)
	ca75StyleB     = int64(50009999)
	ca75StyleOther = int64(50001402)
)

type ca75Content struct {
	active bool
	styles map[int64]characterasset.AppearancePetStyleDefinition
}

func (c ca75Content) AppearanceActive(context.Context) (string, bool, error) {
	return ca75TestRevision, c.active, nil
}
func (c ca75Content) AppearanceRevision(context.Context, string) (bool, error) { return c.active, nil }
func (c ca75Content) AppearanceRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	return c.active, nil
}
func (ca75Content) AppearanceSkin(context.Context, string, int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	return characterasset.AppearanceSkinDefinition{}, false, nil
}
func (ca75Content) AppearanceSkinTx(context.Context, tx.Queryer, string, int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	return characterasset.AppearanceSkinDefinition{}, false, nil
}
func (ca75Content) AppearanceSkinItem(context.Context, string, int64) (characterasset.AppearanceSkinItemDefinition, bool, error) {
	return characterasset.AppearanceSkinItemDefinition{}, false, nil
}
func (ca75Content) AppearanceSkinItemTx(context.Context, tx.Queryer, string, int64) (characterasset.AppearanceSkinItemDefinition, bool, error) {
	return characterasset.AppearanceSkinItemDefinition{}, false, nil
}
func (ca75Content) AppearanceLIVE(context.Context, string, int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	return characterasset.AppearanceLIVEDefinition{}, false, nil
}
func (ca75Content) AppearanceLIVETx(context.Context, tx.Queryer, string, int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	return characterasset.AppearanceLIVEDefinition{}, false, nil
}
func (c ca75Content) AppearancePetStyle(_ context.Context, _ string, id int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	v, ok := c.styles[id]
	return v, ok, nil
}
func (c ca75Content) AppearancePetStyleTx(_ context.Context, _ tx.Queryer, _ string, id int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	v, ok := c.styles[id]
	return v, ok, nil
}

type ca75Store struct {
	*caStore
	ents           map[int64][]character.PetStyleEntitlement
	compositeSaves int
	activeSaves    int
	trace          *[]string
}

func (s *ca75Store) LockPetByIDTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, petID int64) (character.Pet, bool, error) {
	if s.trace != nil {
		*s.trace = append(*s.trace, "pet-lock")
	}
	return s.caStore.LockPetByIDTx(ctx, t, pid, petID)
}
func (s *ca75Store) ListPetStyleEntitlements(_ context.Context, _ identity.PlayerID, petID int64) ([]character.PetStyleEntitlement, error) {
	return append([]character.PetStyleEntitlement(nil), s.ents[petID]...), nil
}
func (s *ca75Store) ListPetStyleEntitlementsTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, petID int64) ([]character.PetStyleEntitlement, error) {
	return append([]character.PetStyleEntitlement(nil), s.ents[petID]...), nil
}
func (s *ca75Store) SavePetAppearanceMutationTx(_ context.Context, _ tx.Tx, p character.Pet, ent *character.PetStyleEntitlement, old int64) error {
	cur, ok := s.byID[p.PetID]
	if !ok || cur.StateVersion != old || p.StateVersion != old+1 {
		return errors.New("test CA7-5 store: invalid composite owner CAS")
	}
	s.byID[p.PetID] = p
	if ent != nil {
		rows := append([]character.PetStyleEntitlement(nil), s.ents[p.PetID]...)
		found := false
		for _, existing := range rows {
			if existing.StyleItemID == ent.StyleItemID {
				found = true
				break
			}
		}
		if !found {
			rows = append(rows, *ent)
		}
		s.ents[p.PetID] = rows
	}
	s.compositeSaves++
	return nil
}
func (s *ca75Store) SavePetActiveStyleTx(_ context.Context, _ tx.Tx, p character.Pet, old int64) error {
	cur, ok := s.byID[p.PetID]
	if !ok || cur.StateVersion != old || p.StateVersion != old+1 {
		return errors.New("test CA7-5 store: invalid active-style owner CAS")
	}
	s.byID[p.PetID] = p
	s.activeSaves++
	return nil
}

type ca75Material struct {
	calls int
	item  int64
	err   error
	trace *[]string
}

func (m *ca75Material) DebitMaterialCostTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	if m.trace != nil {
		*m.trace = append(*m.trace, "i5-debit")
	}
	if len(cost.Stacks) != 1 || cost.Stacks[0].Amount != 1 || len(cost.Scalars) != 0 {
		return appi5.MaterialDebitResult{}, errors.New("test CA7-5 material: unexpected cost")
	}
	m.calls++
	m.item = cost.Stacks[0].ItemID
	return appi5.MaterialDebitResult{}, m.err
}

func ca75Pet(petID, origin int64, active int64, version int64) character.Pet {
	now := time.Unix(100, 0).UTC()
	return character.Pet{
		PlayerID: 7, PetID: petID, TableID: origin, OriginTableID: origin,
		Star: 1, Level: 1, Exp: 0, Color: 1, Skills: character.DefaultPetSkillLevels(),
		Birthday: 1700000000, IsShow: true, ActiveStyle: active,
		CreationContentRevision: ca75TestRevision, StateVersion: version,
		CreatedAt: now, UpdatedAt: now,
	}
}

func ca75ContentFixture() ca75Content {
	return ca75Content{active: true, styles: map[int64]characterasset.AppearancePetStyleDefinition{
		ca75StyleA:     {StyleItemID: ca75StyleA, PetOriginTableID: ca75PetOriginA},
		ca75StyleB:     {StyleItemID: ca75StyleB, PetOriginTableID: ca75PetOriginA},
		ca75StyleOther: {StyleItemID: ca75StyleOther, PetOriginTableID: ca75PetOriginB},
	}}
}

func ca75Service(pets []character.Pet, ents map[int64][]character.PetStyleEntitlement) (Service, *ca75Store, *ca75Material, *caReceipts) {
	byID := make(map[int64]character.Pet, len(pets))
	for _, p := range pets {
		byID[p.PetID] = p
	}
	rows := make(map[int64][]character.PetStyleEntitlement, len(ents))
	for id, in := range ents {
		rows[id] = append([]character.PetStyleEntitlement(nil), in...)
	}
	base := &caStore{byID: byID}
	st := &ca75Store{caStore: base, ents: rows}
	rec := newCAReceipts()
	mat := &ca75Material{}
	content := ca75ContentFixture()
	svc := Service{
		Runner: tx.Runner{DB: caDB{}}, Store: st, Fencer: caFence{},
		Receipts: rec, ReceiptRead: rec, MaterialCosts: mat,
		AppearanceStore: st, Appearance: content, AppearanceMutationStore: st,
	}
	return svc, st, mat, rec
}

func ca75Ent(petID, styleID int64) character.PetStyleEntitlement {
	return character.PetStyleEntitlement{PlayerID: 7, PetID: petID, StyleItemID: styleID}
}

func TestCA75AcquireGrantOnlyConsumesOncePreservesActiveAndSortsStyles(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, ca75StyleB, 4)
	svc, st, mat, _ := ca75Service([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleB)}})
	got, err := svc.AcquirePetStyle(context.Background(), caActor(t), ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000001", 200))
	if err != nil {
		t.Fatal(err)
	}
	if got.ActiveStyle != ca75StyleB || !reflect.DeepEqual(got.PetStyles, []int64{ca75StyleA, ca75StyleB}) || !got.Mutated || !got.Consumed {
		t.Fatalf("result=%+v", got)
	}
	if mat.calls != 1 || mat.item != ca75StyleA || st.compositeSaves != 1 || st.activeSaves != 0 || st.byID[11].StateVersion != 5 || st.byID[11].ActiveStyle != ca75StyleB {
		t.Fatalf("mat=%d/%d composite=%d activeSaves=%d pet=%+v", mat.calls, mat.item, st.compositeSaves, st.activeSaves, st.byID[11])
	}
}

func TestCA75AcquireFreshOwnedConvergesWithoutDebitOrVersionBump(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, mat, rec := ca75Service([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA)}})
	got, err := svc.AcquirePetStyle(context.Background(), caActor(t), ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000002", 201))
	if err != nil {
		t.Fatal(err)
	}
	if got.Mutated || got.Consumed || got.StateVersion != 4 || got.ActiveStyle != 0 || !reflect.DeepEqual(got.PetStyles, []int64{ca75StyleA}) {
		t.Fatalf("result=%+v", got)
	}
	if mat.calls != 0 || st.compositeSaves != 0 || st.byID[11].StateVersion != 4 || len(rec.m) != 1 {
		t.Fatalf("mat=%d saves=%d pet=%+v receipts=%d", mat.calls, st.compositeSaves, st.byID[11], len(rec.m))
	}
}

func TestCA75AcquireNormalizesStaleRawSelectorBeforeGrant(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, ca75StyleA, 4)
	svc, st, mat, _ := ca75Service([]character.Pet{p}, nil)
	got, err := svc.AcquirePetStyle(context.Background(), caActor(t), ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000003", 202))
	if err != nil {
		t.Fatal(err)
	}
	if got.ActiveStyle != 0 || !got.Mutated || !got.Consumed || got.StateVersion != 5 || st.byID[11].ActiveStyle != 0 || st.byID[11].StateVersion != 5 || mat.calls != 1 || st.compositeSaves != 1 {
		t.Fatalf("result=%+v pet=%+v mat=%d saves=%d", got, st.byID[11], mat.calls, st.compositeSaves)
	}
}

func TestCA75AcquireOwnedStyleNormalizesDifferentStaleRawSelectorWithoutDebit(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, ca75StyleOther, 4)
	svc, st, mat, _ := ca75Service([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA)}})
	got, err := svc.AcquirePetStyle(context.Background(), caActor(t), ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000004", 203))
	if err != nil {
		t.Fatal(err)
	}
	if got.ActiveStyle != 0 || !got.Mutated || got.Consumed || got.StateVersion != 5 || st.byID[11].ActiveStyle != 0 || mat.calls != 0 || st.compositeSaves != 1 {
		t.Fatalf("result=%+v pet=%+v mat=%d saves=%d", got, st.byID[11], mat.calls, st.compositeSaves)
	}
}

func TestCA75AcquireInsufficientItemOccursAfterPetLockAndWritesNothing(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, mat, rec := ca75Service([]character.Pet{p}, nil)
	trace := []string{}
	st.trace, mat.trace = &trace, &trace
	mat.err = economy.ErrInsufficientBalance
	_, err := svc.AcquirePetStyle(context.Background(), caActor(t), ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000005", 204))
	if !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("err=%v", err)
	}
	if !reflect.DeepEqual(trace, []string{"pet-lock", "i5-debit"}) || st.compositeSaves != 0 || st.byID[11].StateVersion != 4 || len(st.ents[11]) != 0 || len(rec.m) != 0 {
		t.Fatalf("trace=%v saves=%d pet=%+v ents=%v receipts=%d", trace, st.compositeSaves, st.byID[11], st.ents[11], len(rec.m))
	}
}

func TestCA75SelectConflictCancelAndNoopVersionSemantics(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, _, rec := ca75Service([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA), ca75Ent(11, ca75StyleB)}})
	actor := caActor(t)

	sel, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000006", 205))
	if err != nil {
		t.Fatal(err)
	}
	if !sel.Mutated || sel.ActiveStyle != ca75StyleA || sel.StateVersion != 5 || st.activeSaves != 1 {
		t.Fatalf("select=%+v saves=%d", sel, st.activeSaves)
	}

	noop, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000007", 206))
	if err != nil {
		t.Fatal(err)
	}
	if noop.Mutated || noop.StateVersion != 5 || st.activeSaves != 1 {
		t.Fatalf("noop=%+v saves=%d", noop, st.activeSaves)
	}

	beforeReceipts := len(rec.m)
	_, err = svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleB, caOp(t, "75000000-0000-4000-8000-000000000008", 207))
	if !errors.Is(err, ErrPetStyleSwitchConflict) || st.byID[11].StateVersion != 5 || st.activeSaves != 1 || len(rec.m) != beforeReceipts {
		t.Fatalf("switch err=%v pet=%+v saves=%d receipts=%d", err, st.byID[11], st.activeSaves, len(rec.m))
	}

	cancel, err := svc.CancelPetStyle(context.Background(), actor, 11, caOp(t, "75000000-0000-4000-8000-000000000009", 208))
	if err != nil {
		t.Fatal(err)
	}
	if !cancel.Mutated || cancel.ActiveStyle != 0 || cancel.StateVersion != 6 || st.activeSaves != 2 {
		t.Fatalf("cancel=%+v saves=%d", cancel, st.activeSaves)
	}

	cancelNoop, err := svc.CancelPetStyle(context.Background(), actor, 11, caOp(t, "75000000-0000-4000-8000-000000000010", 209))
	if err != nil {
		t.Fatal(err)
	}
	if cancelNoop.Mutated || cancelNoop.StateVersion != 6 || st.activeSaves != 2 {
		t.Fatalf("cancelNoop=%+v saves=%d", cancelNoop, st.activeSaves)
	}

	afterCancel, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleB, caOp(t, "75000000-0000-4000-8000-000000000017", 217))
	if err != nil {
		t.Fatal(err)
	}
	if !afterCancel.Mutated || afterCancel.ActiveStyle != ca75StyleB || afterCancel.StateVersion != 7 || st.activeSaves != 3 {
		t.Fatalf("afterCancel=%+v saves=%d", afterCancel, st.activeSaves)
	}
}

func TestCA75CancelClearsStaleRawPositiveSelectorEvenWhenEffectiveAlreadyZero(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, ca75StyleOther, 4)
	svc, st, _, _ := ca75Service([]character.Pet{p}, nil)
	got, err := svc.CancelPetStyle(context.Background(), caActor(t), 11, caOp(t, "75000000-0000-4000-8000-000000000011", 210))
	if err != nil {
		t.Fatal(err)
	}
	if !got.Mutated || got.ActiveStyle != 0 || got.StateVersion != 5 || st.byID[11].ActiveStyle != 0 || st.activeSaves != 1 {
		t.Fatalf("result=%+v pet=%+v saves=%d", got, st.byID[11], st.activeSaves)
	}
}

func TestCA75RejectsUnownedOrWrongFamilySelectionWithoutReceipt(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, _, rec := ca75Service([]character.Pet{p}, map[int64][]character.PetStyleEntitlement{11: {ca75Ent(11, ca75StyleA)}})
	actor := caActor(t)
	_, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleB, caOp(t, "75000000-0000-4000-8000-000000000012", 211))
	if !errors.Is(err, ErrPetAppearanceUnavailable) {
		t.Fatalf("unowned err=%v", err)
	}
	_, err = svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleOther, caOp(t, "75000000-0000-4000-8000-000000000013", 212))
	if !errors.Is(err, ErrPetAppearanceUnavailable) {
		t.Fatalf("wrong-family err=%v", err)
	}
	if st.activeSaves != 0 || st.byID[11].StateVersion != 4 || len(rec.m) != 0 {
		t.Fatalf("saves=%d pet=%+v receipts=%d", st.activeSaves, st.byID[11], len(rec.m))
	}
}

func TestCA75ReceiptFingerprintConflictAndReplayDoNotReapply(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, mat, _ := ca75Service([]character.Pet{p}, nil)
	actor := caActor(t)
	op := caOp(t, "75000000-0000-4000-8000-000000000014", 213)
	first, err := svc.AcquirePetStyle(context.Background(), actor, ca75StyleA, op)
	if err != nil {
		t.Fatal(err)
	}
	replay, err := svc.AcquirePetStyle(context.Background(), actor, ca75StyleA, op)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || replay.StateVersion != first.StateVersion || mat.calls != 1 || st.compositeSaves != 1 {
		t.Fatalf("first=%+v replay=%+v mat=%d saves=%d", first, replay, mat.calls, st.compositeSaves)
	}
	_, err = svc.AcquirePetStyle(context.Background(), actor, ca75StyleB, op)
	var conflict *receipt.ConflictError
	if !errors.As(err, &conflict) {
		t.Fatalf("fingerprint err=%T %v", err, err)
	}
	if mat.calls != 1 || st.compositeSaves != 1 {
		t.Fatalf("conflict reapplied mat=%d saves=%d", mat.calls, st.compositeSaves)
	}
}

func TestCA75SelectAndCancelReceiptFingerprintsBindExactSemanticParams(t *testing.T) {
	p11 := ca75Pet(11, ca75PetOriginA, 0, 4)
	p12 := ca75Pet(12, ca75PetOriginA, ca75StyleA, 8)
	svc, st, _, _ := ca75Service([]character.Pet{p11, p12}, map[int64][]character.PetStyleEntitlement{
		11: {ca75Ent(11, ca75StyleA), ca75Ent(11, ca75StyleB)},
		12: {ca75Ent(12, ca75StyleA)},
	})
	actor := caActor(t)

	selectOp := caOp(t, "75000000-0000-4000-8000-000000000018", 218)
	firstSelect, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleA, selectOp)
	if err != nil {
		t.Fatal(err)
	}
	if !firstSelect.Mutated || firstSelect.StateVersion != 5 || st.activeSaves != 1 {
		t.Fatalf("firstSelect=%+v saves=%d", firstSelect, st.activeSaves)
	}
	_, err = svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleB, selectOp)
	var selectConflict *receipt.ConflictError
	if !errors.As(err, &selectConflict) || st.activeSaves != 1 || st.byID[11].ActiveStyle != ca75StyleA || st.byID[11].StateVersion != 5 {
		t.Fatalf("select conflict err=%T %v saves=%d pet=%+v", err, err, st.activeSaves, st.byID[11])
	}

	cancelOp := caOp(t, "75000000-0000-4000-8000-000000000019", 219)
	firstCancel, err := svc.CancelPetStyle(context.Background(), actor, 12, cancelOp)
	if err != nil {
		t.Fatal(err)
	}
	if !firstCancel.Mutated || firstCancel.StateVersion != 9 || st.activeSaves != 2 {
		t.Fatalf("firstCancel=%+v saves=%d", firstCancel, st.activeSaves)
	}
	_, err = svc.CancelPetStyle(context.Background(), actor, 11, cancelOp)
	var cancelConflict *receipt.ConflictError
	if !errors.As(err, &cancelConflict) || st.activeSaves != 2 || st.byID[11].ActiveStyle != ca75StyleA || st.byID[11].StateVersion != 5 {
		t.Fatalf("cancel conflict err=%T %v saves=%d pet11=%+v", err, err, st.activeSaves, st.byID[11])
	}
}

func TestCA75ReloadProjectionTracksMutationAndNoopStateVersion(t *testing.T) {
	p := ca75Pet(11, ca75PetOriginA, 0, 4)
	svc, st, _, _ := ca75Service([]character.Pet{p}, nil)
	actor := caActor(t)
	acquired, err := svc.AcquirePetStyle(context.Background(), actor, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000015", 214))
	if err != nil {
		t.Fatal(err)
	}
	if acquired.StateVersion != 5 {
		t.Fatalf("acquired=%+v", acquired)
	}
	_, views, err := svc.RosterView(context.Background(), actor, time.Unix(215, 0).UTC())
	if err != nil {
		t.Fatal(err)
	}
	if len(views) != 1 || views[0].Appearance.OwnerStateVersion != 5 || views[0].Appearance.ActiveStyle != 0 || !reflect.DeepEqual(views[0].Appearance.OwnedStyles, []int64{ca75StyleA}) {
		t.Fatalf("views=%+v", views)
	}
	noop, err := svc.AcquirePetStyle(context.Background(), actor, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000016", 216))
	if err != nil {
		t.Fatal(err)
	}
	if noop.Mutated || noop.StateVersion != 5 || st.byID[11].StateVersion != 5 {
		t.Fatalf("noop=%+v pet=%+v", noop, st.byID[11])
	}

	selected, err := svc.SelectPetStyle(context.Background(), actor, 11, ca75StyleA, caOp(t, "75000000-0000-4000-8000-000000000020", 220))
	if err != nil {
		t.Fatal(err)
	}
	_, views, err = svc.RosterView(context.Background(), actor, time.Unix(221, 0).UTC())
	if err != nil {
		t.Fatal(err)
	}
	if selected.StateVersion != 6 || len(views) != 1 || views[0].Appearance.OwnerStateVersion != 6 || views[0].Appearance.ActiveStyle != ca75StyleA {
		t.Fatalf("selected=%+v views=%+v", selected, views)
	}

	canceled, err := svc.CancelPetStyle(context.Background(), actor, 11, caOp(t, "75000000-0000-4000-8000-000000000021", 222))
	if err != nil {
		t.Fatal(err)
	}
	_, views, err = svc.RosterView(context.Background(), actor, time.Unix(223, 0).UTC())
	if err != nil {
		t.Fatal(err)
	}
	if canceled.StateVersion != 7 || len(views) != 1 || views[0].Appearance.OwnerStateVersion != 7 || views[0].Appearance.ActiveStyle != 0 || !reflect.DeepEqual(views[0].Appearance.OwnedStyles, []int64{ca75StyleA}) {
		t.Fatalf("canceled=%+v views=%+v", canceled, views)
	}
}

func TestCA75PetStyleRetryPolicyUsesBoundedContentionBackoff(t *testing.T) {
	p := petStyleRetryPolicy()
	if p.MaxAttempts != 8 || !p.RetryDefiniteAbort {
		t.Fatalf("unexpected retry policy: %+v", p)
	}
	if p.DefiniteAbortBackoffBase != 25*time.Millisecond || p.DefiniteAbortBackoffMax != 400*time.Millisecond {
		t.Fatalf("unexpected contention backoff: %+v", p)
	}
}

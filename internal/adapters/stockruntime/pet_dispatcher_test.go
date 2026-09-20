package stockruntime

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type petServiceFake struct {
	root character.PetRoot
	pets []character.Pet
	err  error

	cleanPetID          int64
	expItems            []appi5.PetExpItemDebit
	upgrades            []apppet.SkillUpgrade
	equipPetID          int64
	equipIndex          int64
	equipResult         apppet.EquipItemResult
	oneKeyPetID         int64
	oneKeyResult        apppet.OneKeyEquipResult
	advancePetID        int64
	advanceResult       apppet.AdvanceResult
	oneKeyAdvancePetID  int64
	oneKeyAdvanceResult apppet.OneKeyAdvanceResult
	styleAcquireItemID  int64
	styleAcquireResult  apppet.PetStyleAcquireResult
	styleSelectPetID    int64
	styleSelectStyleID  int64
	styleSelectResult   apppet.PetStyleSelectResult
	styleCancelPetID    int64
	styleCancelResult   apppet.PetStyleCancelResult
}

func (s *petServiceFake) RosterView(_ context.Context, _ identity.ActorContext, observedAt time.Time) (character.PetRoot, []apppet.PetRosterView, error) {
	out := make([]apppet.PetRosterView, 0, len(s.pets))
	for _, pet := range s.pets {
		out = append(out, apppet.PetRosterView{Pet: pet, Appearance: characterasset.EffectivePetAppearance{OwnerStateVersion: pet.StateVersion, ObservedAt: observedAt, ActiveStyle: 0}})
	}
	return s.root, out, s.err
}
func (s *petServiceFake) Summon(context.Context, identity.ActorContext, int64, operation.Context) (character.Pet, error) {
	if len(s.pets) > 0 {
		return s.pets[0], s.err
	}
	return character.Pet{}, s.err
}
func (s *petServiceFake) CleanCD(_ context.Context, _ identity.ActorContext, petID int64, _ operation.Context) (apppet.HatchResult, error) {
	s.cleanPetID = petID
	return apppet.HatchResult{}, s.err
}
func (s *petServiceFake) SetShow(context.Context, identity.ActorContext, int64, operation.Context) error {
	return s.err
}
func (s *petServiceFake) Evolve(context.Context, identity.ActorContext, int64, operation.Context) (apppet.EvolveResult, error) {
	return apppet.EvolveResult{}, s.err
}
func (s *petServiceFake) Feed(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (apppet.ExpResult, error) {
	return apppet.ExpResult{}, s.err
}
func (s *petServiceFake) UseExpItems(_ context.Context, _ identity.ActorContext, _ int64, items []appi5.PetExpItemDebit, _ operation.Context) (apppet.ExpResult, error) {
	s.expItems = append([]appi5.PetExpItemDebit(nil), items...)
	return apppet.ExpResult{}, s.err
}
func (s *petServiceFake) UpgradeSkills(_ context.Context, _ identity.ActorContext, _ int64, upgrades []apppet.SkillUpgrade, _ operation.Context) (apppet.SkillResult, error) {
	s.upgrades = append([]apppet.SkillUpgrade(nil), upgrades...)
	return apppet.SkillResult{}, s.err
}
func (s *petServiceFake) EquipItem(_ context.Context, _ identity.ActorContext, petID, equipIndex int64, _ operation.Context) (apppet.EquipItemResult, error) {
	s.equipPetID = petID
	s.equipIndex = equipIndex
	return s.equipResult, s.err
}
func (s *petServiceFake) OneKeyEquip(_ context.Context, _ identity.ActorContext, petID int64, _ operation.Context) (apppet.OneKeyEquipResult, error) {
	s.oneKeyPetID = petID
	return s.oneKeyResult, s.err
}
func (s *petServiceFake) Advance(_ context.Context, _ identity.ActorContext, petID int64, _ operation.Context) (apppet.AdvanceResult, error) {
	s.advancePetID = petID
	return s.advanceResult, s.err
}
func (s *petServiceFake) OneKeyAdvance(_ context.Context, _ identity.ActorContext, petID int64, _ operation.Context) (apppet.OneKeyAdvanceResult, error) {
	s.oneKeyAdvancePetID = petID
	return s.oneKeyAdvanceResult, s.err
}
func (s *petServiceFake) AcquirePetStyle(_ context.Context, _ identity.ActorContext, itemID int64, _ operation.Context) (apppet.PetStyleAcquireResult, error) {
	s.styleAcquireItemID = itemID
	return s.styleAcquireResult, s.err
}
func (s *petServiceFake) SelectPetStyle(_ context.Context, _ identity.ActorContext, petID, styleID int64, _ operation.Context) (apppet.PetStyleSelectResult, error) {
	s.styleSelectPetID, s.styleSelectStyleID = petID, styleID
	return s.styleSelectResult, s.err
}
func (s *petServiceFake) CancelPetStyle(_ context.Context, _ identity.ActorContext, petID int64, _ operation.Context) (apppet.PetStyleCancelResult, error) {
	s.styleCancelPetID = petID
	return s.styleCancelResult, s.err
}

type petEconomyFake struct {
	amount int64
	err    error
	key    string
}

func (s *petEconomyFake) CurrentScalar(_ context.Context, _ identity.PlayerID, key string, _ operation.Context) (int64, error) {
	s.key = key
	return s.amount, s.err
}

func TestPetDispatcherMID780UsesCanonicalRoster(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(100, 0).UTC()
	pet := character.Pet{PlayerID: actor.PlayerID, PetID: 9, TableID: 10030001, OriginTableID: 10030001, Star: 1, Level: 1, Exp: 0, Color: 1, Fumo: character.PetFumoSlots{5, 60, 700}, Birthday: 1700000000, IsShow: true, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	svc := &petServiceFake{pets: []character.Pet{pet}}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc}
	req := env(780, nil, now)
	req.Envelope.Params = map[string]any{}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 {
		t.Fatalf("status=%d body=%#v", resp.HTTPStatus, resp.Body)
	}
	rows := resp.Body["pets"].([]any)
	if len(rows) != 1 || rows[0].(map[string]any)["pet_id"] != int64(9) {
		t.Fatalf("body=%#v", resp.Body)
	}
	fumos := rows[0].(map[string]any)["fumos"].([]any)
	if !reflect.DeepEqual(fumos, []any{int64(5), int64(60), int64(700)}) {
		t.Fatalf("MID780 raw Pet Fumo projection=%#v", fumos)
	}
}

func TestPetDispatcherAcceptsStockEnvelopeMetadataButRejectsUnknownGameplayField(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(101, 0).UTC()
	pet := character.Pet{PlayerID: actor.PlayerID, PetID: 9, TableID: 10030001, OriginTableID: 10030001, Star: 1, Level: 1, Exp: 0, Color: 1, Birthday: 1700000000, IsShow: true, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: &petServiceFake{pets: []character.Pet{pet}}}
	req := env(780, nil, now)
	req.Envelope.Params = map[string]any{
		"mid": int64(780), "token": "bearer", "region": int64(1),
		"v_": "1", "app_v": "1.164.0", "platform": int64(3),
	}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 {
		t.Fatalf("stock envelope metadata rejected: status=%d body=%#v", resp.HTTPStatus, resp.Body)
	}
	req.Envelope.Params["invented"] = true
	resp = d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 400 {
		t.Fatalf("invented gameplay field accepted: status=%d body=%#v", resp.HTTPStatus, resp.Body)
	}
}

func TestPetDispatcherMID785StrictShapeAndMinimalResponse(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(102, 0).UTC()
	svc := &petServiceFake{advanceResult: apppet.AdvanceResult{
		PetID: 77, RestoreItems: []appi5.Award{{TableID: 50001007, ItemNum: 2}, {TableID: 50001003, ItemNum: 1}},
	}}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc}
	req := env(785, nil, now)
	req.Envelope.Params = map[string]any{"pet_id": int64(77)}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 || svc.advancePetID != 77 {
		t.Fatalf("status=%d pet=%d body=%#v", resp.HTTPStatus, svc.advancePetID, resp.Body)
	}
	want := map[string]any{"restore_items": []any{
		map[string]any{"table_id": int64(50001007), "item_num": int64(2)},
		map[string]any{"table_id": int64(50001003), "item_num": int64(1)},
	}}
	if !reflect.DeepEqual(resp.Body, want) {
		t.Fatalf("MID785 leaked or omitted wire fields: got=%#v want=%#v", resp.Body, want)
	}

	svc.advanceResult = apppet.AdvanceResult{PetID: 77}
	resp = d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 || len(resp.Body) != 0 {
		t.Fatalf("zero-restoration MID785 response=%#v status=%d", resp.Body, resp.HTTPStatus)
	}
}

func TestPetDispatcherMID785RejectsNonExactPetIDRequest(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(103, 0).UTC()
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: &petServiceFake{}}
	cases := []map[string]any{
		{},
		{"pet_id": int64(0)},
		{"pet_id": int64(-1)},
		{"pet_id": "77"},
		{"pet_id": int64(77), "extra": int64(1)},
	}
	for i, params := range cases {
		req := env(785, nil, now)
		req.Envelope.Params = params
		resp := d.Dispatch(context.Background(), req)
		if resp.HTTPStatus != 400 {
			t.Fatalf("case %d accepted: params=%#v status=%d body=%#v", i, params, resp.HTTPStatus, resp.Body)
		}
	}
}

func TestPetDispatcherMID790StrictShapeAndMinimalResponse(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(104, 0).UTC()
	svc := &petServiceFake{oneKeyAdvanceResult: apppet.OneKeyAdvanceResult{
		PetID: 77, RestoreItems: []appi5.Award{{TableID: 50001006, ItemNum: 2}},
	}}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc}
	req := env(790, nil, now)
	req.Envelope.Params = map[string]any{"pet_id": int64(77)}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 || svc.oneKeyAdvancePetID != 77 {
		t.Fatalf("status=%d pet=%d body=%#v", resp.HTTPStatus, svc.oneKeyAdvancePetID, resp.Body)
	}
	want := map[string]any{"restore_items": []any{map[string]any{"table_id": int64(50001006), "item_num": int64(2)}}}
	if !reflect.DeepEqual(resp.Body, want) {
		t.Fatalf("MID790 leaked or omitted wire fields: got=%#v want=%#v", resp.Body, want)
	}

	svc.oneKeyAdvanceResult = apppet.OneKeyAdvanceResult{PetID: 77}
	resp = d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 || len(resp.Body) != 0 {
		t.Fatalf("zero-restoration MID790 response=%#v status=%d", resp.Body, resp.HTTPStatus)
	}

	for i, params := range []map[string]any{
		{}, {"pet_id": int64(0)}, {"pet_id": int64(-1)}, {"pet_id": "77"}, {"pet_id": int64(77), "extra": int64(1)},
	} {
		req := env(790, nil, now)
		req.Envelope.Params = params
		resp := d.Dispatch(context.Background(), req)
		if resp.HTTPStatus != 400 {
			t.Fatalf("case %d accepted: params=%#v status=%d body=%#v", i, params, resp.HTTPStatus, resp.Body)
		}
	}
}

func TestPetDispatcherMID782ProjectsAbsoluteCurrentCrystal(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(100, 0).UTC()
	svc := &petServiceFake{}
	economy := &petEconomyFake{amount: 321}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc, Economy: economy}
	req := env(782, nil, now)
	req.Envelope.Params = map[string]any{"pet_id": int64(77)}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 {
		t.Fatalf("status=%d body=%#v", resp.HTTPStatus, resp.Body)
	}
	if svc.cleanPetID != 77 {
		t.Fatalf("CleanCD pet=%d", svc.cleanPetID)
	}
	if economy.key != "crystal" {
		t.Fatalf("projection key=%q", economy.key)
	}
	got, ok := resp.Body["economy_"].(map[string]any)
	if !ok || got["crystal"] != int64(321) {
		t.Fatalf("body=%#v", resp.Body)
	}
}

func TestPetDispatcherMID782ProjectionFailureDoesNotResettleInDispatcher(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(100, 0).UTC()
	svc := &petServiceFake{}
	economy := &petEconomyFake{err: errors.New("read failed")}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc, Economy: economy}
	req := env(782, nil, now)
	req.Envelope.Params = map[string]any{"pet_id": int64(77)}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 503 || svc.cleanPetID != 77 {
		t.Fatalf("status=%d clean=%d body=%#v", resp.HTTPStatus, svc.cleanPetID, resp.Body)
	}
}

func TestDecodePetExpItemsStrictAndOrderPreserving(t *testing.T) {
	got, err := decodePetExpItems([]any{
		map[string]any{"item_id": int64(50001089), "item_num": int64(2)},
		map[string]any{"item_id": int64(50001087), "item_num": int64(1)},
	})
	if err != nil {
		t.Fatal(err)
	}
	want := []appi5.PetExpItemDebit{{ItemID: 50001089, Count: 2}, {ItemID: 50001087, Count: 1}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got=%#v want=%#v", got, want)
	}
	bad := []any{
		[]any{},
		[]any{map[string]any{"item_id": int64(1), "item_num": int64(1)}},
		[]any{map[string]any{"item_id": int64(50001087), "item_num": int64(1)}, map[string]any{"item_id": int64(50001087), "item_num": int64(2)}},
		[]any{map[string]any{"item_id": int64(50001087), "item_num": int64(0)}},
		[]any{map[string]any{"item_id": int64(50001087), "item_num": int64(1), "extra": int64(2)}},
	}
	for i, raw := range bad {
		if _, err := decodePetExpItems(raw); err == nil {
			t.Fatalf("bad[%d] accepted: %#v", i, raw)
		}
	}
}

func TestDecodePetSkillUpgradesAllowsUnsortedButRejectsMalformed(t *testing.T) {
	got, err := decodePetSkillUpgrades("4|1|3", "2|1|5")
	if err != nil {
		t.Fatal(err)
	}
	want := []apppet.SkillUpgrade{{Slot: 4, Count: 2}, {Slot: 1, Count: 1}, {Slot: 3, Count: 5}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got=%#v want=%#v", got, want)
	}
	bad := [][2]any{
		{"1|2", "1"},
		{"1|1", "1|2"},
		{"0", "1"},
		{"6", "1"},
		{"01", "1"},
		{"1|", "1|1"},
		{" 1", "1"},
		{"1", "0"},
		{"1", int64(1)},
	}
	for i, tc := range bad {
		if _, err := decodePetSkillUpgrades(tc[0], tc[1]); err == nil {
			t.Fatalf("bad[%d] accepted: %#v", i, tc)
		}
	}
}

func TestPetDispatcherRejectsInventedParamsAndUnownedMIDs(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(100, 0).UTC()
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: &petServiceFake{}}
	badReq := env(780, nil, now)
	badReq.Envelope.Params = map[string]any{"x": 1}
	bad := d.Dispatch(context.Background(), badReq)
	if bad.HTTPStatus != 400 {
		t.Fatalf("bad params status=%d", bad.HTTPStatus)
	}
	unownedReq := env(784, nil, now)
	unownedReq.Envelope.Params = map[string]any{}
	unowned := d.Dispatch(context.Background(), unownedReq)
	if unowned.HTTPStatus != 501 {
		t.Fatalf("unowned mid status=%d", unowned.HTTPStatus)
	}
}

func TestPetProgressionRejectsStringTypedIntegers(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(100, 0).UTC()
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: &petServiceFake{}}
	cases := []struct {
		mid    uint16
		params map[string]any
	}{
		{786, map[string]any{"pet_id": "1"}},
		{787, map[string]any{"pet_id": int64(1), "item_id": "50001087", "item_num": int64(1)}},
		{134, map[string]any{"pet_id": "1", "items": []any{map[string]any{"item_id": int64(50001087), "item_num": int64(1)}}}},
		{134, map[string]any{"pet_id": int64(1), "items": []any{map[string]any{"item_id": "50001087", "item_num": int64(1)}}}},
		{791, map[string]any{"pet_id": "1", "skill_colors": "1", "skill_counts": "1"}},
	}
	for _, tc := range cases {
		req := env(tc.mid, nil, now)
		req.Envelope.Params = tc.params
		resp := d.Dispatch(context.Background(), req)
		if resp.HTTPStatus != 400 {
			t.Fatalf("MID%d accepted string integer: status=%d body=%#v", tc.mid, resp.HTTPStatus, resp.Body)
		}
	}
}

func TestCA75PetStyleMIDsStrictWireAndStockProjection(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(105, 0).UTC()
	svc := &petServiceFake{
		styleAcquireResult: apppet.PetStyleAcquireResult{PetID: 77, StyleItemID: 50001376, ActiveStyle: 50009999, PetStyles: []int64{50001376, 50009999}, StateVersion: 3, Mutated: true, Consumed: true},
		styleSelectResult:  apppet.PetStyleSelectResult{PetID: 77, StyleItemID: 50001376, ActiveStyle: 50001376, StateVersion: 4, Mutated: true},
		styleCancelResult:  apppet.PetStyleCancelResult{PetID: 77, ActiveStyle: 0, StateVersion: 5, Mutated: true},
	}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc}

	r1893 := env(1893, nil, now)
	r1893.Envelope.Params = map[string]any{"item_id": int64(50001376)}
	got := d.Dispatch(context.Background(), r1893)
	if got.HTTPStatus != 200 || svc.styleAcquireItemID != 50001376 || len(got.Body) != 2 || got.Body["active_style"] != int64(50009999) || !reflect.DeepEqual(got.Body["pet_styles"], []int64{50001376, 50009999}) {
		t.Fatalf("MID1893 status=%d item=%d body=%#v", got.HTTPStatus, svc.styleAcquireItemID, got.Body)
	}
	for _, forbidden := range []string{"pet_id", "style_item_id", "state_version", "mutated", "consumed", "remove_item", "economy_", "server_time"} {
		if _, ok := got.Body[forbidden]; ok {
			t.Fatalf("MID1893 leaked %q in %#v", forbidden, got.Body)
		}
	}

	r1894 := env(1894, nil, now)
	r1894.Envelope.Params = map[string]any{"pet_id": int64(77), "style_id": int64(50001376)}
	got = d.Dispatch(context.Background(), r1894)
	if got.HTTPStatus != 200 || svc.styleSelectPetID != 77 || svc.styleSelectStyleID != 50001376 || len(got.Body) != 1 || got.Body["active_style"] != int64(50001376) {
		t.Fatalf("MID1894 status=%d pet=%d style=%d body=%#v", got.HTTPStatus, svc.styleSelectPetID, svc.styleSelectStyleID, got.Body)
	}

	r1895 := env(1895, nil, now)
	r1895.Envelope.Params = map[string]any{"pet_id": int64(77)}
	got = d.Dispatch(context.Background(), r1895)
	if got.HTTPStatus != 200 || svc.styleCancelPetID != 77 || len(got.Body) != 0 {
		t.Fatalf("MID1895 status=%d pet=%d body=%#v", got.HTTPStatus, svc.styleCancelPetID, got.Body)
	}
}

func TestCA75PetStyleMIDsRejectMalformedAndInventedParams(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(106, 0).UTC()
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: &petServiceFake{}}
	cases := []struct {
		mid    uint16
		params map[string]any
	}{
		{1893, map[string]any{}},
		{1893, map[string]any{"item_id": "50001376"}},
		{1893, map[string]any{"item_id": 50001376.5}},
		{1893, map[string]any{"item_id": int64(50001376), "pet_id": int64(77)}},
		{1894, map[string]any{"pet_id": int64(77)}},
		{1894, map[string]any{"pet_id": "77", "style_id": int64(50001376)}},
		{1894, map[string]any{"pet_id": int64(77), "style_id": false}},
		{1894, map[string]any{"pet_id": int64(77), "style_id": int64(50001376), "item_id": int64(1)}},
		{1895, map[string]any{}},
		{1895, map[string]any{"pet_id": "77"}},
		{1895, map[string]any{"pet_id": int64(77), "style_id": int64(50001376)}},
	}
	for i, tc := range cases {
		r := env(tc.mid, nil, now)
		r.Envelope.Params = tc.params
		got := d.Dispatch(context.Background(), r)
		if got.HTTPStatus != 400 {
			t.Fatalf("bad[%d] MID%d accepted params=%#v status=%d body=%#v", i, tc.mid, tc.params, got.HTTPStatus, got.Body)
		}
	}
}

func TestCA75PetStyleErrorTransportMapping(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(107, 0).UTC()
	tests := []struct {
		err  error
		want int
	}{
		{apppet.ErrPetAppearanceContentInactive, 503},
		{apppet.ErrPetNotFound, 404},
		{apppet.ErrPetAppearanceUnavailable, 400},
		{apppet.ErrPetStyleSwitchConflict, 409},
		{economy.ErrInsufficientBalance, 409},
		{errors.New("infrastructure"), 503},
	}
	for _, tc := range tests {
		d := PetDispatcher{Authority: httpAuthority{actor}, Service: &petServiceFake{err: tc.err}}
		r := env(1894, nil, now)
		r.Envelope.Params = map[string]any{"pet_id": int64(77), "style_id": int64(50001376)}
		got := d.Dispatch(context.Background(), r)
		if got.HTTPStatus != tc.want {
			t.Fatalf("err=%v status=%d want=%d body=%#v", tc.err, got.HTTPStatus, tc.want, got.Body)
		}
	}
}

func TestPetDispatcherMID783StrictWireAndAlreadyEquippedConvergence(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(102, 0).UTC()
	svc := &petServiceFake{equipResult: apppet.EquipItemResult{PetID: 77, AlreadyEquipped: true}}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc}
	req := env(783, nil, now)
	req.Envelope.Params = map[string]any{"pet_id": int64(77), "equip_index": int64(2)}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 || svc.equipPetID != 77 || svc.equipIndex != 2 || len(resp.Body) != 1 || resp.Body["error_code"] != int64(30001) {
		t.Fatalf("status=%d pet=%d slot=%d body=%#v", resp.HTTPStatus, svc.equipPetID, svc.equipIndex, resp.Body)
	}

	for i, params := range []map[string]any{
		{"pet_id": int64(77)},
		{"pet_id": int64(77), "equip_index": int64(0)},
		{"pet_id": int64(77), "equip_index": int64(4)},
		{"pet_id": int64(77), "equip_index": "2"},
		{"pet_id": int64(77), "equip_index": int64(2), "invented": true},
	} {
		r := env(783, nil, now)
		r.Envelope.Params = params
		got := d.Dispatch(context.Background(), r)
		if got.HTTPStatus != 400 {
			t.Fatalf("bad[%d] accepted: params=%#v status=%d body=%#v", i, params, got.HTTPStatus, got.Body)
		}
	}
}

func TestPetDispatcherMID783SuccessResponseIsEmpty(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(103, 0).UTC()
	svc := &petServiceFake{equipResult: apppet.EquipItemResult{PetID: 77}}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc}
	req := env(783, nil, now)
	req.Envelope.Params = map[string]any{"pet_id": int64(77), "equip_index": int64(1)}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 || len(resp.Body) != 0 {
		t.Fatalf("status=%d body=%#v", resp.HTTPStatus, resp.Body)
	}
}

func TestPetDispatcherMID792StrictWireAndNeverProjectsManaOrPlan(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(104, 0).UTC()
	svc := &petServiceFake{oneKeyResult: apppet.OneKeyEquipResult{PetID: 88, Level: 97, Exp: 1689095, Equipment: character.PetEquipmentSlots{0, 0, 1}}}
	d := PetDispatcher{Authority: httpAuthority{actor}, Service: svc}
	req := env(792, nil, now)
	req.Envelope.Params = map[string]any{"pet_id": int64(88)}
	resp := d.Dispatch(context.Background(), req)
	if resp.HTTPStatus != 200 || svc.oneKeyPetID != 88 || len(resp.Body) != 0 {
		t.Fatalf("status=%d pet=%d body=%#v", resp.HTTPStatus, svc.oneKeyPetID, resp.Body)
	}
	if _, ok := resp.Body["economy_"]; ok {
		t.Fatalf("MID792 leaked economy projection: %#v", resp.Body)
	}

	for i, params := range []map[string]any{
		{},
		{"pet_id": int64(0)},
		{"pet_id": "88"},
		{"pet_id": int64(88), "equip_index": int64(1)},
		{"pet_id": int64(88), "invented": true},
	} {
		r := env(792, nil, now)
		r.Envelope.Params = params
		got := d.Dispatch(context.Background(), r)
		if got.HTTPStatus != 400 {
			t.Fatalf("bad[%d] accepted: params=%#v status=%d body=%#v", i, params, got.HTTPStatus, got.Body)
		}
	}
}

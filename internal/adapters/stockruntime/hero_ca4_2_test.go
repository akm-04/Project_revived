package stockruntime

import (
	"context"
	"errors"
	"reflect"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type ca42HeroService struct {
	ca23HeroService
	equipPartner    int64
	equipIndex      int64
	equipResult     apphero.EquipItemResult
	equipErr        error
	onePartner      int64
	oneResult       apphero.OneKeyEquipResult
	oneErr          error
	enhancePartner  int64
	enhanceIndex    int64
	enhanceTimes    int64
	enhanceResult   apphero.EnhanceSuperEquipmentResult
	enhanceErr      error
	fumoPartner     int64
	fumoIndex       int64
	fumoMaterials   []int64
	fumoResult      apphero.FumoResult
	fumoErr         error
	promotePartner  int64
	promoteResult   apphero.HeroPromotionResult
	promoteErr      error
	oneClickPartner int64
	oneClickResult  apphero.HeroPromotionResult
	oneClickErr     error
	rosterViews     []apphero.HeroRosterView
	rosterRoot      character.HeroRoot
}

func (s *ca42HeroService) EquipItem(_ context.Context, _ identity.ActorContext, partnerID, equipIndex int64, _ operation.Context) (apphero.EquipItemResult, error) {
	s.equipPartner, s.equipIndex = partnerID, equipIndex
	return s.equipResult, s.equipErr
}

func (s *ca42HeroService) OneKeyEquip(_ context.Context, _ identity.ActorContext, partnerID int64, _ operation.Context) (apphero.OneKeyEquipResult, error) {
	s.onePartner = partnerID
	return s.oneResult, s.oneErr
}

func (s *ca42HeroService) EnhanceSuperEquipment(_ context.Context, _ identity.ActorContext, partnerID, equipIndex, enhanceTimes int64, _ operation.Context) (apphero.EnhanceSuperEquipmentResult, error) {
	s.enhancePartner, s.enhanceIndex, s.enhanceTimes = partnerID, equipIndex, enhanceTimes
	return s.enhanceResult, s.enhanceErr
}

func (s *ca42HeroService) FeedFumo(_ context.Context, _ identity.ActorContext, partnerID, equipIndex int64, materials []int64, _ operation.Context) (apphero.FumoResult, error) {
	s.fumoPartner, s.fumoIndex = partnerID, equipIndex
	s.fumoMaterials = append([]int64(nil), materials...)
	return s.fumoResult, s.fumoErr
}

func (s *ca42HeroService) RosterView(context.Context, identity.ActorContext) (character.HeroRoot, []apphero.HeroRosterView, error) {
	return s.rosterRoot, append([]apphero.HeroRosterView(nil), s.rosterViews...), nil
}
func (s *ca42HeroService) PowerUpHero(_ context.Context, _ identity.ActorContext, partnerID int64, _ operation.Context) (apphero.HeroPromotionResult, error) {
	s.promotePartner = partnerID
	return s.promoteResult, s.promoteErr
}
func (s *ca42HeroService) OneClickJinjie(_ context.Context, _ identity.ActorContext, partnerID int64, _ operation.Context) (apphero.HeroPromotionResult, error) {
	s.oneClickPartner = partnerID
	return s.oneClickResult, s.oneClickErr
}

type ca42HeroEconomy struct {
	calls  int
	pid    identity.PlayerID
	key    string
	amount int64
	err    error
}

func (e *ca42HeroEconomy) CurrentScalar(_ context.Context, pid identity.PlayerID, key string, _ operation.Context) (int64, error) {
	e.calls++
	e.pid, e.key = pid, key
	return e.amount, e.err
}

func TestCA42MID54MinimalSuccessAndAlreadyEquippedRecovery(t *testing.T) {
	svc := &ca42HeroService{equipResult: apphero.EquipItemResult{PartnerID: 41, Equipment: character.HeroEquipmentSlots{1, 0, 0, 0, 0, 0}}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}

	r := d.Dispatch(context.Background(), heroReq(t, 54, map[string]any{"partner_id": int64(41), "equip_index": int64(1)}))
	if r.HTTPStatus != 200 || len(r.Body) != 0 || svc.equipPartner != 41 || svc.equipIndex != 1 {
		t.Fatalf("success=%+v args=%d/%d", r, svc.equipPartner, svc.equipIndex)
	}

	svc.equipResult.AlreadyEquipped = true
	r = d.Dispatch(context.Background(), heroReq(t, 54, map[string]any{"partner_id": int64(41), "equip_index": int64(1)}))
	if r.HTTPStatus != 200 || len(r.Body) != 1 || r.Body["error_code"] != int64(30001) {
		t.Fatalf("already response=%+v", r)
	}
}

func TestCA42MID54StrictShapeAndSemanticRejection(t *testing.T) {
	svc := &ca42HeroService{}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	for _, params := range []map[string]any{
		{"partner_id": int64(1)},
		{"partner_id": int64(1), "equip_index": int64(0)},
		{"partner_id": int64(1), "equip_index": int64(7)},
		{"partner_id": int64(1), "equip_index": int64(1), "item_id": int64(99)},
	} {
		if r := d.Dispatch(context.Background(), heroReq(t, 54, params)); r.HTTPStatus != 400 {
			t.Fatalf("invalid MID54 accepted params=%v response=%+v", params, r)
		}
	}
	svc.equipErr = apphero.ErrHeroEquipmentUnavailable
	if r := d.Dispatch(context.Background(), heroReq(t, 54, map[string]any{"partner_id": int64(1), "equip_index": int64(1)})); r.HTTPStatus != 400 || r.Body["error"] != "hero_operation_rejected" {
		t.Fatalf("semantic rejection=%+v", r)
	}
}

func TestCA42MID62ProjectsCanonicalEquipsAndCurrentManaForNoWork(t *testing.T) {
	slots := character.HeroEquipmentSlots{1, 0, 1, 1, 0, 1}
	svc := &ca42HeroService{oneResult: apphero.OneKeyEquipResult{PartnerID: 77, Level: 10, Exp: 123, Equipment: slots, NoWork: true}}
	economy := &ca42HeroEconomy{amount: 987654}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Economy: economy}

	r := d.Dispatch(context.Background(), heroReq(t, 62, map[string]any{"partner_id": int64(77)}))
	if r.HTTPStatus != 200 || svc.onePartner != 77 || economy.calls != 1 || economy.key != "mana" {
		t.Fatalf("response=%+v partner=%d economy=%+v", r, svc.onePartner, economy)
	}
	got, ok := r.Body["equips"].([]any)
	if !ok || len(got) != character.HeroEquipmentSlotCount {
		t.Fatalf("equips=%#v", r.Body["equips"])
	}
	want := []any{int64(1), int64(0), int64(1), int64(1), int64(0), int64(1)}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("equips=%v want=%v", got, want)
	}
	e, ok := r.Body["economy_"].(map[string]any)
	if !ok || e["mana"] != int64(987654) || len(r.Body) != 2 {
		t.Fatalf("projection=%+v", r.Body)
	}
}

func TestCA42MID62StrictShapeAndProjectionFailure(t *testing.T) {
	svc := &ca42HeroService{oneResult: apphero.OneKeyEquipResult{PartnerID: 1, Level: 1, Equipment: character.HeroEquipmentSlots{}}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Economy: &ca42HeroEconomy{amount: 1}}
	for _, params := range []map[string]any{
		{},
		{"partner_id": int64(0)},
		{"partner_id": int64(1), "items": []any{}},
	} {
		if r := d.Dispatch(context.Background(), heroReq(t, 62, params)); r.HTTPStatus != 400 {
			t.Fatalf("invalid MID62 accepted params=%v response=%+v", params, r)
		}
	}

	d.Economy = nil
	if r := d.Dispatch(context.Background(), heroReq(t, 62, map[string]any{"partner_id": int64(1)})); r.HTTPStatus != 503 || r.Body["error"] != "hero_projection_unavailable" {
		t.Fatalf("missing projection=%+v", r)
	}
	d.Economy = &ca42HeroEconomy{err: errors.New("projection failed")}
	if r := d.Dispatch(context.Background(), heroReq(t, 62, map[string]any{"partner_id": int64(1)})); r.HTTPStatus != 503 || r.Body["error"] != "hero_projection_failed" {
		t.Fatalf("failed projection=%+v", r)
	}
}

func TestCA45MID304StrictShapeAndEmptySuccess(t *testing.T) {
	svc := &ca42HeroService{enhanceResult: apphero.EnhanceSuperEquipmentResult{PartnerID: 77, Equipment: character.HeroEquipmentSlots{12, 1, 1, 1, 1, 1}}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	r := d.Dispatch(context.Background(), heroReq(t, 304, map[string]any{"partner_id": int64(77), "equip_index": int64(1), "enhance_times": int64(2)}))
	if r.HTTPStatus != 200 || len(r.Body) != 0 || svc.enhancePartner != 77 || svc.enhanceIndex != 1 || svc.enhanceTimes != 2 {
		t.Fatalf("success=%+v args=%d/%d/%d", r, svc.enhancePartner, svc.enhanceIndex, svc.enhanceTimes)
	}
	for _, params := range []map[string]any{
		{"partner_id": int64(77), "equip_index": int64(1)},
		{"partner_id": int64(77), "equip_index": int64(0), "enhance_times": int64(1)},
		{"partner_id": int64(77), "equip_index": int64(7), "enhance_times": int64(1)},
		{"partner_id": int64(77), "equip_index": int64(1), "enhance_times": int64(0)},
		{"partner_id": int64(77), "equip_index": int64(1), "enhance_times": int64(1), "mana": int64(1)},
	} {
		if got := d.Dispatch(context.Background(), heroReq(t, 304, params)); got.HTTPStatus != 400 {
			t.Fatalf("invalid MID304 accepted params=%v response=%+v", params, got)
		}
	}
}

func TestCA45MID49ReconnectPreservesRawSuperEquipmentValues(t *testing.T) {
	h := ca23Hero(character.SuperHero, 11001, 77, 8)
	h.Equipment = character.HeroEquipmentSlots{1, 2, 11, 21, 31, 40}
	svc := &ca42HeroService{rosterViews: []apphero.HeroRosterView{{Hero: h}}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	r := d.Dispatch(context.Background(), heroReq(t, 49, map[string]any{}))
	if r.HTTPStatus != 200 {
		t.Fatalf("response=%+v", r)
	}
	heroes := r.Body["heros"].(map[string]any)
	row := heroes["77"].(map[string]any)
	got, ok := row["equips"].([]any)
	if !ok {
		t.Fatalf("equips=%#v", row["equips"])
	}
	want := []any{int64(1), int64(2), int64(11), int64(21), int64(31), int64(40)}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("equips=%v want=%v", got, want)
	}
}

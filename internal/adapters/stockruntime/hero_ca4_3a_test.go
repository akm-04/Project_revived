package stockruntime

import (
	"context"
	"errors"
	"reflect"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/character"
)

func TestCA43AMID58StrictShapeAndProjection(t *testing.T) {
	svc := &ca42HeroService{fumoResult: apphero.FumoResult{PartnerID: 41, Slot: 5, Fumo: 20, Levels: character.HeroFumoSlots{0, 0, 0, 0, 1, 0}}}
	economy := &ca42HeroEconomy{amount: 9400}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Economy: economy}
	params := map[string]any{"partner_id": int64(41), "equip_index": int64(5), "materials": []any{int64(20001038), int64(20001047)}}
	r := d.Dispatch(context.Background(), heroReq(t, 58, params))
	if r.HTTPStatus != 200 || svc.fumoPartner != 41 || svc.fumoIndex != 5 || !reflect.DeepEqual(svc.fumoMaterials, []int64{20001038, 20001047}) {
		t.Fatalf("response=%+v svc=%+v", r, svc)
	}
	if r.Body["fumo"] != int64(20) {
		t.Fatalf("fumo=%v", r.Body["fumo"])
	}
	wantLevels := []any{int64(0), int64(0), int64(0), int64(0), int64(1), int64(0)}
	if got, ok := r.Body["fumo_lev"].([]any); !ok || !reflect.DeepEqual(got, wantLevels) {
		t.Fatalf("levels=%#v", r.Body["fumo_lev"])
	}
	e, ok := r.Body["economy_"].(map[string]any)
	if !ok || e["mana"] != int64(9400) || economy.calls != 1 {
		t.Fatalf("economy=%#v calls=%d", r.Body["economy_"], economy.calls)
	}
}

func TestCA43AMID58RejectsMalformedAndSemanticFailureWithoutProjection(t *testing.T) {
	svc := &ca42HeroService{}
	economy := &ca42HeroEconomy{amount: 1}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Economy: economy}
	bad := []map[string]any{
		{"partner_id": int64(1), "equip_index": int64(5)},
		{"partner_id": int64(1), "equip_index": int64(0), "materials": []any{int64(1)}},
		{"partner_id": int64(1), "equip_index": int64(7), "materials": []any{int64(1)}},
		{"partner_id": int64(1), "equip_index": int64(5), "materials": []any{}},
		{"partner_id": int64(1), "equip_index": int64(5), "materials": []any{int64(1)}, "invented": true},
	}
	for _, p := range bad {
		if r := d.Dispatch(context.Background(), heroReq(t, 58, p)); r.HTTPStatus != 400 {
			t.Fatalf("bad params accepted %v => %+v", p, r)
		}
	}
	svc.fumoErr = apphero.ErrHeroFumoUnavailable
	r := d.Dispatch(context.Background(), heroReq(t, 58, map[string]any{"partner_id": int64(1), "equip_index": int64(5), "materials": []any{int64(1)}}))
	if r.HTTPStatus != 400 || r.Body["error"] != "hero_operation_rejected" || economy.calls != 0 {
		t.Fatalf("semantic=%+v economyCalls=%d", r, economy.calls)
	}
}

func TestCA43AMID58ProjectionFailureIsNonOK(t *testing.T) {
	svc := &ca42HeroService{fumoResult: apphero.FumoResult{PartnerID: 1, Slot: 1, Fumo: 1}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Economy: &ca42HeroEconomy{err: errors.New("projection")}}
	r := d.Dispatch(context.Background(), heroReq(t, 58, map[string]any{"partner_id": int64(1), "equip_index": int64(1), "materials": []any{int64(2)}}))
	if r.HTTPStatus != 503 || r.Body["error"] != "hero_projection_failed" {
		t.Fatalf("projection failure=%+v", r)
	}
}

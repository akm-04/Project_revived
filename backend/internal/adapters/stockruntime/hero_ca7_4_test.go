package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type ca74LIVEHTTPService struct {
	unlockPartner int64
	unlockModel   int64
	unlockResult  apphero.LIVEUnlockResult
	unlockErr     error
	showPartner   int64
	showModel     int64
	showValue     bool
	showErr       error
}

func (s *ca74LIVEHTTPService) UnlockLIVE(_ context.Context, _ identity.ActorContext, partnerID, modelID int64, _ operation.Context) (apphero.LIVEUnlockResult, error) {
	s.unlockPartner, s.unlockModel = partnerID, modelID
	return s.unlockResult, s.unlockErr
}
func (s *ca74LIVEHTTPService) SetLIVEShow(_ context.Context, _ identity.ActorContext, partnerID, modelID int64, show bool, _ operation.Context) (apphero.LIVEShowResult, error) {
	s.showPartner, s.showModel, s.showValue = partnerID, modelID, show
	return apphero.LIVEShowResult{PartnerID: partnerID, ModelID: modelID, IsShow: show, StateVersion: 2}, s.showErr
}

type ca74HeroEconomy struct {
	amount int64
	key    string
	err    error
}

func (e *ca74HeroEconomy) CurrentScalar(_ context.Context, _ identity.PlayerID, key string, _ operation.Context) (int64, error) {
	e.key = key
	return e.amount, e.err
}

func TestCA74MID68StockWireAlwaysProjectsAlignedLIVEAndCurrentCrystal(t *testing.T) {
	live := &ca74LIVEHTTPService{unlockResult: apphero.LIVEUnlockResult{
		PartnerID: 7, ModelID: 40001074, StateVersion: 3,
		LIVE: []apphero.LIVEResultState{{ModelID: 40001074, IsShow: true}, {ModelID: 40001109, IsShow: false}},
	}}
	economy := &ca74HeroEconomy{amount: 12345}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, LIVE: live, Economy: economy}
	r := d.Dispatch(context.Background(), heroReq(t, 68, map[string]any{"partner_id": json.Number("7"), "model_id": json.Number("40001074")}))
	if r.HTTPStatus != 200 || live.unlockPartner != 7 || live.unlockModel != 40001074 || economy.key != "crystal" {
		t.Fatalf("response=%+v service=%d/%d economy=%q", r, live.unlockPartner, live.unlockModel, economy.key)
	}
	if r.Body["unlocked_dynamic_card"] != "40001074|40001109" || r.Body["dynamic_card_state"] != "1|0" {
		t.Fatalf("LIVE wire=%#v", r.Body)
	}
	e, ok := r.Body["economy_"].(map[string]any)
	if !ok || e["crystal"] != int64(12345) {
		t.Fatalf("economy=%#v", r.Body["economy_"])
	}
	for _, invented := range []string{"remove_item", "activation_item", "server_time", "crystal"} {
		if _, ok := r.Body[invented]; ok {
			t.Fatalf("MID68 invented top-level field %q: %#v", invented, r.Body)
		}
	}
}

func TestCA74MID68ProjectionFailureAfterSemanticSuccessReturns503ForFreshConvergenceRetry(t *testing.T) {
	live := &ca74LIVEHTTPService{unlockResult: apphero.LIVEUnlockResult{PartnerID: 7, ModelID: 40001074, StateVersion: 2, LIVE: []apphero.LIVEResultState{{ModelID: 40001074, IsShow: true}}}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, LIVE: live, Economy: &ca74HeroEconomy{err: errors.New("projection")}}
	r := d.Dispatch(context.Background(), heroReq(t, 68, map[string]any{"partner_id": json.Number("7"), "model_id": json.Number("40001074")}))
	if r.HTTPStatus != 503 || r.Body["error"] != "hero_projection_failed" {
		t.Fatalf("response=%+v", r)
	}
}

func TestCA74MID69UsesStrictJSONNumericBitAndEmptySuccessBody(t *testing.T) {
	live := &ca74LIVEHTTPService{}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, LIVE: live}
	for raw, want := range map[json.Number]bool{"0": false, "1": true} {
		r := d.Dispatch(context.Background(), heroReq(t, 69, map[string]any{"partner_id": json.Number("7"), "model_id": json.Number("40001074"), "is_show": raw}))
		if r.HTTPStatus != 200 || len(r.Body) != 0 || live.showPartner != 7 || live.showModel != 40001074 || live.showValue != want {
			t.Fatalf("is_show=%s response=%+v captured=%d/%d/%v", raw, r, live.showPartner, live.showModel, live.showValue)
		}
	}
	bad := []any{int64(1), "1", true, json.Number("2"), json.Number("-1"), json.Number("0.5")}
	for _, raw := range bad {
		r := d.Dispatch(context.Background(), heroReq(t, 69, map[string]any{"partner_id": json.Number("7"), "model_id": json.Number("40001074"), "is_show": raw}))
		if r.HTTPStatus != 400 {
			t.Fatalf("MID69 accepted unsupported is_show %#v: %+v", raw, r)
		}
	}
	missing := d.Dispatch(context.Background(), heroReq(t, 69, map[string]any{"partner_id": json.Number("7"), "model_id": json.Number("40001074")}))
	if missing.HTTPStatus != 400 {
		t.Fatalf("MID69 accepted missing is_show: %+v", missing)
	}
}

func TestCA74MIDsRejectInventedGameplayFieldsAndMapSemanticFailure(t *testing.T) {
	live := &ca74LIVEHTTPService{unlockErr: apphero.ErrHeroAppearanceUnavailable}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, LIVE: live, Economy: &ca74HeroEconomy{amount: 1}}
	r := d.Dispatch(context.Background(), heroReq(t, 68, map[string]any{"partner_id": json.Number("7"), "model_id": json.Number("40001074")}))
	if r.HTTPStatus != 400 || r.Body["error"] != "hero_operation_rejected" {
		t.Fatalf("semantic rejection=%+v", r)
	}
	extra := d.Dispatch(context.Background(), heroReq(t, 68, map[string]any{"partner_id": json.Number("7"), "model_id": json.Number("40001074"), "item_id": json.Number("50005171")}))
	if extra.HTTPStatus != 400 {
		t.Fatalf("MID68 accepted invented item field: %+v", extra)
	}
	extra = d.Dispatch(context.Background(), heroReq(t, 69, map[string]any{"partner_id": json.Number("7"), "model_id": json.Number("40001074"), "is_show": json.Number("1"), "toggle": json.Number("1")}))
	if extra.HTTPStatus != 400 {
		t.Fatalf("MID69 accepted invented toggle field: %+v", extra)
	}
}

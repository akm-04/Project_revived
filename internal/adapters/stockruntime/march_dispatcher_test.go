package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/march"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"math"
	"net/http"
	"testing"
)

func TestMarchReportStockVariantsAndNumericBoundary(t *testing.T) {
	makeReport := func() map[string]any {
		return map[string]any{"win": true, "is_reborn": 0, "hero_status": []any{map[string]any{"player_id": 1, "hero_id": 7, "hp": json.Number("120.5"), "mp": 345, "is_reborn": 0}}, "enemy_status": []any{map[string]any{"hero_id": 2, "hp": 0, "mp": 0, "is_reborn": 0}}}
	}
	p := makeReport()
	if _, ok := marchResult(p); !ok {
		t.Fatal("BattleCreateReport variant refused")
	}
	p["formation"] = "7|0|0|0|0"
	p["cost_drink"] = 1
	if _, ok := marchResult(p); !ok {
		t.Fatal("BattleCreate variant refused")
	}
	for name, mutate := range map[string]func(map[string]any){
		"win":             func(p map[string]any) { p["win"] = 1 },
		"unknown":         func(p map[string]any) { p["reward"] = 999 },
		"empty":           func(p map[string]any) { p["enemy_status"] = []any{} },
		"formation":       func(p map[string]any) { p["formation"] = "7|7" },
		"negative_drink":  func(p map[string]any) { p["cost_drink"] = -1 },
		"nan":             func(p map[string]any) { p["hero_status"].([]any)[0].(map[string]any)["hp"] = math.NaN() },
		"string":          func(p map[string]any) { p["hero_status"].([]any)[0].(map[string]any)["hp"] = "120" },
		"nested_envelope": func(p map[string]any) { p["hero_status"].([]any)[0].(map[string]any)["mid"] = 338 },
	} {
		t.Run(name, func(t *testing.T) {
			p := makeReport()
			mutate(p)
			if _, ok := marchResult(p); ok {
				t.Fatal("malformed report accepted")
			}
		})
	}
	if marchFailure(336, d.ErrRefused).HTTPStatus != http.StatusOK || marchFailure(336, d.ErrInvalid).HTTPStatus != http.StatusBadRequest || marchFailure(336, &receipt.ConflictError{}).HTTPStatus != http.StatusBadRequest {
		t.Fatal("F4 status shape")
	}
	for _, mid := range []uint16{340, 342} {
		if ref := marchFailure(mid, d.ErrRefused); ref.HTTPStatus != http.StatusConflict || ref.Body["error_code"] != int64(1) {
			t.Fatalf("MID %d refusal reached the OK callback", mid)
		}
	}
	if ref := marchFailure(336, d.ErrRefused); ref.HTTPStatus != http.StatusOK || ref.Body["error_code"] != 1 {
		t.Fatal("other MIDs keep the stock refusal body")
	}
}

type marchStartProbe struct {
	MarchPort
	calls int
}

func (p *marchStartProbe) Start(context.Context, identity.ActorContext, app.Fight, operation.Context) (map[string]any, error) {
	p.calls++
	return map[string]any{}, nil
}
func TestMarchStartUsesCampaignEnumNotInstanceEnum(t *testing.T) {
	p := &marchStartProbe{}
	dispatch := MarchDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: p}
	for _, kind := range []int{5, 4} {
		r := dispatch.Dispatch(context.Background(), heroReq(t, 340, map[string]any{"campaign_type": kind, "formation": "1|0|0|0|0"}))
		want := http.StatusOK
		if kind == 4 {
			want = http.StatusBadRequest
		}
		if r.HTTPStatus != want {
			t.Fatal("src_64 CampaignType.MARCH is 5, InstanceType.MARCH is 4", kind, r)
		}
	}
	if p.calls != 1 {
		t.Fatal("invalid enum reached owner", p.calls)
	}
}

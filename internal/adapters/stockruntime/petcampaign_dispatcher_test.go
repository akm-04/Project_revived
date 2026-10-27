package stockruntime

import (
	"context"
	app "gxb.local/backend/v2/internal/application/petcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

type petCampaignProbe struct {
	PetCampaignPort
	starts, results int
	last            app.Result
}

func (p *petCampaignProbe) Start(_ context.Context, _ identity.ActorContext, q app.Fight, _ operation.Context) (map[string]any, error) {
	p.starts++
	return map[string]any{}, nil
}
func (p *petCampaignProbe) Result(_ context.Context, _ identity.ActorContext, q app.Result, _ operation.Context) (map[string]any, error) {
	p.results++
	p.last = q
	return map[string]any{}, nil
}
func TestPetCampaignBooleanWireAndNoInventedStars(t *testing.T) {
	p := &petCampaignProbe{}
	d := PetCampaignDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: p}
	for _, tc := range []struct {
		params map[string]any
		status int
	}{{map[string]any{"is_win": true, "floor": 1, "floor_type": 1}, 200}, {map[string]any{"is_win": false, "floor": 1, "floor_type": 2, "pet_id": 9}, 200}, {map[string]any{"is_win": 1, "floor": 1, "floor_type": 1}, 400}, {map[string]any{"is_win": true, "floor": 1, "floor_type": 1, "star": 3}, 400}, {map[string]any{"is_win": true, "floor": 1, "floor_type": 1, "formation": "1"}, 400}} {
		got := d.Dispatch(context.Background(), heroReq(t, 820, tc.params))
		if got.HTTPStatus != tc.status {
			t.Fatal(tc, got)
		}
	}
	if p.results != 2 || !p.last.HasPet || p.last.Pet != 9 || p.last.Win {
		t.Fatal(p)
	}
}
func TestPetCampaignRejectsRentalAndForgedStartShape(t *testing.T) {
	p := &petCampaignProbe{}
	d := PetCampaignDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: p}
	for _, tc := range []struct {
		params map[string]any
		status int
	}{{map[string]any{"campaign_id": 30001, "formation": "1|0|0|0|0"}, 200}, {map[string]any{"campaign_id": 30001, "formation": "1", "rent_pet_id": 9}, 400}, {map[string]any{"campaign_id": 30001, "formation": "1", "force": 999999}, 400}} {
		got := d.Dispatch(context.Background(), heroReq(t, 819, tc.params))
		if got.HTTPStatus != tc.status {
			t.Fatal(tc, got)
		}
	}
	if p.starts != 1 {
		t.Fatal(p.starts)
	}
}

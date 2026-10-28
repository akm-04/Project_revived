package stockruntime

import (
	"context"
	app "gxb.local/backend/v2/internal/application/godstrial"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

type trialProbe struct {
	GodsTrialPort
	results int
	last    app.Result
}

func (p *trialProbe) Result(_ context.Context, _ identity.ActorContext, q app.Result, _ operation.Context) (map[string]any, error) {
	p.results++
	p.last = q
	return map[string]any{}, nil
}
func TestGodsTrialCurrentResultArrayAndCampaignIdentity(t *testing.T) {
	p := &trialProbe{}
	d := GodsTrialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: p}
	for _, tc := range []struct {
		params map[string]any
		status int
	}{
		{map[string]any{"campaign_id": 1001, "campaign_type": 79, "star": 1, "partner_ids": []any{int64(9007199254740991)}}, 200},
		{map[string]any{"campaign_id": 1001, "campaign_type": 57, "star": 1, "partner_ids": []any{int64(1)}}, 400},
		{map[string]any{"campaign_id": 1001, "campaign_type": 99, "star": 1, "partner_ids": []any{int64(1)}}, 400},
		{map[string]any{"campaign_id": 1001, "campaign_type": 79, "star": 4, "partner_ids": []any{int64(1)}}, 400},
		{map[string]any{"campaign_id": 1001, "campaign_type": 79, "star": 1, "partner_ids": "1"}, 400},
		{map[string]any{"campaign_id": 1001, "campaign_type": 79, "star": 1, "partner_ids": []any{int64(1)}, "items": []any{}}, 400},
	} {
		r := d.Dispatch(context.Background(), heroReq(t, 3093, tc.params))
		if r.HTTPStatus != tc.status {
			t.Fatal(tc, r)
		}
	}
	if p.results != 1 || p.last.Formation[0] != 9007199254740991 {
		t.Fatal(p)
	}
}

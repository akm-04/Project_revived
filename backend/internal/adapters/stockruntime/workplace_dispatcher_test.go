package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/workplace"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"net/http"
	"testing"
)

type workplaceProbe struct {
	WorkplacePort
	calls int
}

func (p *workplaceProbe) Dispatch(_ context.Context, _ identity.ActorContext, q app.Dispatch, _ operation.Context) (map[string]any, error) {
	p.calls++
	return map[string]any{"partners": q.Partners}, nil
}
func TestWorkplaceOwnedIdentityBoundary(t *testing.T) {
	p := &workplaceProbe{}
	d := WorkplaceDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: p}
	for _, tc := range []struct {
		name   string
		ids    any
		status int
	}{
		{"owned_ids", []any{json.Number("12000"), int64(9007199254740991)}, 200},
		{"duplicate", []any{12000, 12000}, 400},
		{"zero", []any{0}, 400},
		{"fraction", []any{1.5}, 400},
		{"too_large", []any{json.Number("9007199254740992")}, 400},
		{"string", []any{"12000"}, 400},
		{"empty", []any{}, 400},
		{"map", map[string]any{}, 400},
	} {
		t.Run(tc.name, func(t *testing.T) {
			r := d.Dispatch(context.Background(), heroReq(t, 531, map[string]any{"partners": tc.ids, "team_id": 2, "treasure_type": 2001, "sp_num": 10}))
			if r.HTTPStatus != tc.status {
				t.Fatal(r)
			}
		})
	}
	if p.calls != 1 {
		t.Fatal("bad identities reached owner", p.calls)
	}
	if workplaceFailure(&receipt.ConflictError{}).HTTPStatus != http.StatusBadRequest {
		t.Fatal("receipt conflict must be F4 malformed request")
	}
}

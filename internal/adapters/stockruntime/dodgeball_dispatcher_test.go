package stockruntime

import (
	"context"
	domain "gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

type dodgeballProbe struct {
	DodgeballPort
	results int
}

func (probe *dodgeballProbe) Result(_ context.Context, _ identity.ActorContext, records []domain.HitRecord, _ operation.Context) (map[string]any, error) {
	probe.results++
	return map[string]any{}, nil
}
func (probe *dodgeballProbe) FriendInfo(_ context.Context, _ identity.ActorContext, _ operation.Context) (map[string]any, error) {
	return map[string]any{"friend_infos": []map[string]any{}}, nil
}
func TestDodgeballRecordBoundaryAndDirectFriendArray(t *testing.T) {
	probe := &dodgeballProbe{}
	dispatcher := DodgeballDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}
	record := map[string]any{"rate_id": 1, "id": 1, "ball_num": 1, "is_buff1": false, "is_buff2": false}
	for _, test := range []struct {
		raw    any
		status int
	}{
		{[]any{}, 200}, {map[string]any{}, 200}, {[]any{record}, 200}, {nil, 400}, {"[]", 400},
		{[]any{map[string]any{"rate_id": 1, "id": 1, "ball_num": 1, "is_buff1": 0, "is_buff2": false}}, 400},
		{[]any{map[string]any{"rate_id": 1, "id": 1, "ball_num": 1, "is_buff1": false, "is_buff2": false, "reward": 50}}, 400},
		{[]any{map[string]any{"rate_id": 651, "id": 1, "ball_num": 1, "is_buff1": false, "is_buff2": false}}, 400},
	} {
		response := dispatcher.Dispatch(context.Background(), heroReq(t, 2963, map[string]any{"records": test.raw}))
		if response.HTTPStatus != test.status {
			t.Fatal(test, response)
		}
	}
	if probe.results != 3 {
		t.Fatal(probe.results)
	}
	response := dispatcher.Dispatch(context.Background(), heroReq(t, 2964, map[string]any{}))
	if _, valid := response.JSON.([]map[string]any); response.HTTPStatus != 200 || !valid {
		t.Fatal(response)
	}
}

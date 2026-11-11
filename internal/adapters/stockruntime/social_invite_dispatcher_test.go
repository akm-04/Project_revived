package stockruntime

import (
	"context"
	"errors"
	"testing"

	invite "gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

type inviteReadProbe struct {
	calls int
	body  map[string]any
	err   error
}

func (probe *inviteReadProbe) Read(_ context.Context, _ identity.ActorContext, _ operation.Context) (map[string]any, error) {
	probe.calls++
	return probe.body, probe.err
}

type inviteBindProbe struct {
	calls int
	code  string
	err   error
}

func (probe *inviteBindProbe) Bind(_ context.Context, _ identity.ActorContext, code string, _ operation.Context) (map[string]any, error) {
	probe.calls++
	probe.code = code
	return map[string]any{"invitor_id": int64(100001), "invitor_name": "Inviter"}, probe.err
}

type inviteClaimProbe struct {
	calls   int
	mission int64
	err     error
}

func (probe *inviteClaimProbe) Claim(_ context.Context, _ identity.ActorContext, mission int64, _ operation.Context) (map[string]any, error) {
	probe.calls++
	probe.mission = mission
	return map[string]any{"awards": []any{map[string]any{"table_id": int64(-1), "item_num": int64(90), "crystal": int64(90)}}, "new_missions": []any{}, "new_infos": map[string]any{"missions": []any{}, "invite_players": []any{}}}, probe.err
}

func TestSocialInviteDispatcherStockShapesAndRefusals(t *testing.T) {
	read := &inviteReadProbe{body: map[string]any{"missions": []any{}, "invite_players": []any{}, "invite_code": "1F", "invitor_id": int64(0), "invitor_name": ""}}
	bind := &inviteBindProbe{}
	claim := &inviteClaimProbe{}
	dispatcher := SocialInviteDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Read: read, Bind: bind, Claim: claim}

	for _, test := range []struct {
		mid        uint16
		parameters map[string]any
		status     int
	}{
		{384, map[string]any{}, 200},
		{384, map[string]any{"extra": "x"}, 400},
		{386, map[string]any{"invite_code": "1F"}, 200},
		{386, map[string]any{"invite_code": " "}, 400},
		{386, map[string]any{}, 400},
		{386, map[string]any{"invite_code": int64(1)}, 400},
		{385, map[string]any{"mission_id": int64(100016)}, 200},
		{385, map[string]any{}, 400},
		{385, map[string]any{"mission_id": int64(0)}, 400},
		{385, map[string]any{"mission_id": 1.5}, 400},
	} {
		result := dispatcher.Dispatch(context.Background(), heroReq(t, test.mid, test.parameters))
		if result.HTTPStatus != test.status {
			t.Fatalf("mid %d %+v: %+v", test.mid, test.parameters, result)
		}
		if test.status != 200 && result.Body["missions"] != nil && result.Body["awards"] != nil {
			t.Fatal("refusal ran a success callback", result)
		}
	}
	if read.calls != 1 || bind.calls != 1 || claim.calls != 1 || bind.code != "1F" || claim.mission != 100016 {
		t.Fatal(read.calls, bind.calls, claim.calls, bind.code, claim.mission)
	}

	for _, refusal := range []error{invite.ErrBindRefused, invite.ErrClaimRefused, invite.ErrFacts} {
		bind.err = refusal
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 386, map[string]any{"invite_code": "1F"}))
		if result.HTTPStatus != 409 || result.Body["error_code"] != unprovenRefusalCode {
			t.Fatal(refusal, result)
		}
		claim.err = refusal
		result = dispatcher.Dispatch(context.Background(), heroReq(t, 385, map[string]any{"mission_id": int64(100016)}))
		if result.HTTPStatus != 409 || result.Body["error_code"] != unprovenRefusalCode {
			t.Fatal(refusal, result)
		}
	}
	bind.err = &receipt.ConflictError{}
	result := dispatcher.Dispatch(context.Background(), heroReq(t, 386, map[string]any{"invite_code": "1F"}))
	if result.HTTPStatus != 409 || result.Body["error_code"] != staleConflictCode {
		t.Fatal("receipt conflict", result)
	}
	bind.err = domain.ErrSameAccount
	result = dispatcher.Dispatch(context.Background(), heroReq(t, 386, map[string]any{"invite_code": "1F"}))
	if result.HTTPStatus != 409 || result.Body["error_code"] != int64(20033) {
		t.Fatal("same-account refusal lost stock code", result)
	}
	bind.err = invite.ErrUnavailable
	result = dispatcher.Dispatch(context.Background(), heroReq(t, 386, map[string]any{"invite_code": "1F"}))
	if result.HTTPStatus != 503 {
		t.Fatal(result)
	}
	read.err = errors.New("database unavailable")
	result = dispatcher.Dispatch(context.Background(), heroReq(t, 384, map[string]any{}))
	if result.HTTPStatus != 503 {
		t.Fatal(result)
	}
}

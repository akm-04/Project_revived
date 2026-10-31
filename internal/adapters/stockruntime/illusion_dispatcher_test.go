package stockruntime

import (
	"context"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/illusion"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type illusionStub struct {
	settled app.Response
	err     error
}

func (s illusionStub) Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{"challenge_times": int64(5)}, s.err
}
func (s illusionStub) Buy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{"challenge_times": int64(10)}, s.err
}
func (illusionStub) Start(context.Context, identity.ActorContext, app.StartRequest, operation.Context) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s illusionStub) Settle(context.Context, identity.ActorContext, app.ResultRequest, operation.Context) (app.Response, error) {
	return s.settled, s.err
}
func (illusionStub) MemberTeam(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error) {
	return map[string]any{"heros": []map[string]any{}}, nil
}

func illusionRequest(mid uint16, params map[string]any, now time.Time) httpedge.DispatchRequest {
	params["token"], params["region"] = "bearer", int64(1)
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: operation.Context{StartedAt: now}, MID: mid, ReceivedAt: now, Params: params,
		Claims: wire.CredentialClaims{Token: "bearer", Region: 1}}}
}

func TestIllusionEveryMIDRoutes(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := IllusionDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: illusionStub{}}
	for _, request := range []struct {
		mid    uint16
		params map[string]any
	}{
		{1344, map[string]any{}},
		{1345, map[string]any{}},
		{1346, map[string]any{"formation": "1"}},
		{1347, map[string]any{"star": int64(1), "total_damage": float64(500), "formation": "1", "cost_time": int64(10)}},
		{1364, map[string]any{"player_id": int64(100001)}},
	} {
		got := dispatcher.Dispatch(context.Background(), illusionRequest(request.mid, request.params, now))
		if got.HTTPStatus != 200 {
			t.Fatalf("MID %d: %d %#v", request.mid, got.HTTPStatus, got.Body)
		}
	}
}

func TestIllusionDuplicateTerminalIsFightExist(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := IllusionDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)},
		Service: illusionStub{settled: app.Response{Body: map[string]any{"rank": int64(1), "now_hurt": int64(5), "highest_hurt": int64(5)}, Duplicate: true}}}
	got := dispatcher.Dispatch(context.Background(), illusionRequest(1347, map[string]any{"star": int64(1), "total_damage": float64(5), "formation": "1", "cost_time": int64(10)}, now))
	if got.HTTPStatus != 200 || got.Body["error_code"] != int64(illusionFightExist) || got.Body["rank"] != int64(1) {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
}

func TestIllusionRefusalIsBareErrorCode(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := IllusionDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: illusionStub{err: d.ErrRefused}}
	got := dispatcher.Dispatch(context.Background(), illusionRequest(1344, map[string]any{}, now))
	if got.HTTPStatus != 200 || len(got.Body) != 1 || got.Body["error_code"] != int64(1) {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
}

func TestIllusionForgedAndRentedInputIsBadRequest(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := IllusionDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: illusionStub{}}
	if got := dispatcher.Dispatch(context.Background(), illusionRequest(1344, map[string]any{"extra": int64(1)}, now)); got.HTTPStatus != 400 {
		t.Fatalf("forged 1344: %d %#v", got.HTTPStatus, got.Body)
	}
	if got := dispatcher.Dispatch(context.Background(), illusionRequest(1346, map[string]any{"formation": "1", "rent_player_id": int64(7)}, now)); got.HTTPStatus != 400 {
		t.Fatalf("rented 1346: %d %#v", got.HTTPStatus, got.Body)
	}
	if got := dispatcher.Dispatch(context.Background(), illusionRequest(1347, map[string]any{"star": int64(1), "total_damage": "not-a-number", "formation": "1", "cost_time": int64(10)}, now)); got.HTTPStatus != 400 {
		t.Fatalf("bad damage: %d %#v", got.HTTPStatus, got.Body)
	}
	if got := dispatcher.Dispatch(context.Background(), illusionRequest(1365, map[string]any{}, now)); got.HTTPStatus != 400 {
		t.Fatalf("unsupported MID: %d %#v", got.HTTPStatus, got.Body)
	}
	if got := dispatcher.Dispatch(context.Background(), illusionRequest(1347, map[string]any{"star": int64(2), "total_damage": float64(5), "formation": "1", "cost_time": int64(10)}, now)); got.HTTPStatus != 400 {
		t.Fatalf("bad star: %d %#v", got.HTTPStatus, got.Body)
	}
}

func TestIllusionConflictMapsToBadRequest(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := IllusionDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: illusionStub{err: d.ErrInvalid}}
	if got := dispatcher.Dispatch(context.Background(), illusionRequest(1345, map[string]any{}, now)); got.HTTPStatus != 400 {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
}

func TestIllusionOneShotNoticesDeliverOnce(t *testing.T) {
	ledger := NewIllusionNoticeLedger()
	const room, mid = int64(9), uint16(518)
	players := []identity.PlayerID{1, 2}
	if got := ledger.undelivered(room, mid, players); len(got) != 2 {
		t.Fatal(got)
	}
	ledger.markDelivered(room, mid, 1)
	if got := ledger.undelivered(room, mid, players); len(got) != 1 || got[0] != 2 {
		t.Fatal("a delivered notice repeated", got)
	}
	ledger.reseat(room, mid, []identity.PlayerID{1})
	if got := ledger.undelivered(room, mid, players); len(got) != 2 {
		t.Fatal("a rejoined player keeps a stale delivery", got)
	}
	ledger.markDelivered(room, mid, 1)
	ledger.forget(room)
	if got := ledger.undelivered(room, mid, players); len(got) != 2 {
		t.Fatal("a closed room kept its ledger", got)
	}
}

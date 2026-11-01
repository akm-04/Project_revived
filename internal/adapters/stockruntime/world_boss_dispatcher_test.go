package stockruntime

import (
	"context"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type worldBossStub struct {
	settled app.Response
	err     error
}

func (worldBossStub) Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{"total_hurt": int64(0)}, nil
}
func (worldBossStub) Buy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{}, nil
}
func (worldBossStub) Start(context.Context, identity.ActorContext, app.StartRequest, operation.Context) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s worldBossStub) Settle(context.Context, identity.ActorContext, app.ResultRequest, operation.Context) (app.Response, error) {
	return s.settled, s.err
}
func (s worldBossStub) Sweep(context.Context, identity.ActorContext, int64, operation.Context) (app.Response, error) {
	return s.settled, s.err
}

func worldBossRequest(mid uint16, params map[string]any, now time.Time) httpedge.DispatchRequest {
	params["token"], params["region"] = "bearer", int64(1)
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: operation.Context{StartedAt: now}, MID: mid, ReceivedAt: now, Params: params,
		Claims: wire.CredentialClaims{Token: "bearer", Region: 1}}}
}

func TestWorldBossDuplicateReturnsFightExist(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := WorldBossDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: worldBossStub{settled: app.Response{Body: map[string]any{"damage": int64(5), "total_hurt": int64(5), "total_rank": int64(1)}, Duplicate: true}}}
	got := dispatcher.Dispatch(context.Background(), worldBossRequest(627, map[string]any{"campaign_id": int64(10011), "campaign_type": int64(8), "total_damage": float64(5), "formation": "1"}, now))
	if got.HTTPStatus != 200 || got.Body["error_code"] != int64(worldBossFightExist) || got.Body["damage"] != int64(5) || got.Body["total_rank"] != int64(1) {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
}

func TestWorldBossRefusalIsBareErrorCode(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := WorldBossDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: worldBossStub{err: d.ErrRefused}}
	got := dispatcher.Dispatch(context.Background(), worldBossRequest(628, map[string]any{"campaign_id": int64(10011)}, now))
	if got.HTTPStatus != 409 || len(got.Body) != 1 || got.Body["error_code"] != int64(1) {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
	if _, exists := got.Body["error_msg"]; exists {
		t.Fatal("refusal carried error_msg")
	}
}

type worldBossRouteStub struct {
	calls     []string
	duplicate bool
}

func (s *worldBossRouteStub) record(name string) { s.calls = append(s.calls, name) }
func (s *worldBossRouteStub) Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	s.record("info")
	return map[string]any{"total_hurt": int64(1)}, nil
}
func (s *worldBossRouteStub) Buy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	s.record("buy")
	return map[string]any{"buy_times": int64(1)}, nil
}
func (s *worldBossRouteStub) Start(_ context.Context, _ identity.ActorContext, request app.StartRequest, _ operation.Context) (map[string]any, error) {
	s.record("start")
	return map[string]any{"campaign_id": request.CampaignID, "formation": request.Formation}, nil
}
func (s *worldBossRouteStub) Settle(context.Context, identity.ActorContext, app.ResultRequest, operation.Context) (app.Response, error) {
	s.record("settle")
	return app.Response{Body: map[string]any{"damage": int64(7)}, Duplicate: s.duplicate}, nil
}
func (s *worldBossRouteStub) Sweep(_ context.Context, _ identity.ActorContext, campaign int64, _ operation.Context) (app.Response, error) {
	s.record("sweep")
	return app.Response{Body: map[string]any{"damage": campaign}, Duplicate: s.duplicate}, nil
}

func TestWorldBossEveryMIDRoutes(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	stub := &worldBossRouteStub{}
	dispatcher := WorldBossDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: stub}
	for _, request := range []struct {
		mid    uint16
		params map[string]any
	}{
		{624, map[string]any{}},
		{625, map[string]any{}},
		{626, map[string]any{"campaign_id": int64(10011), "formation": "1|2"}},
		{627, map[string]any{"campaign_id": int64(10011), "campaign_type": int64(8), "total_damage": float64(7), "formation": "1"}},
		{628, map[string]any{"campaign_id": int64(10011)}},
	} {
		got := dispatcher.Dispatch(context.Background(), worldBossRequest(request.mid, request.params, now))
		if got.HTTPStatus != 200 {
			t.Fatalf("MID %d: %d %#v", request.mid, got.HTTPStatus, got.Body)
		}
	}
	expected := []string{"info", "buy", "start", "settle", "sweep"}
	if len(stub.calls) != len(expected) {
		t.Fatalf("calls %v", stub.calls)
	}
	for index, name := range expected {
		if stub.calls[index] != name {
			t.Fatalf("calls %v", stub.calls)
		}
	}
}

func TestWorldBossTerminalDuplicatesAreFightExist(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := WorldBossDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &worldBossRouteStub{duplicate: true}}
	for _, request := range []struct {
		mid    uint16
		params map[string]any
	}{
		{627, map[string]any{"campaign_id": int64(10011), "campaign_type": int64(8), "total_damage": float64(7), "formation": "1"}},
		{628, map[string]any{"campaign_id": int64(10011)}},
	} {
		got := dispatcher.Dispatch(context.Background(), worldBossRequest(request.mid, request.params, now))
		if got.HTTPStatus != 200 || got.Body["error_code"] != int64(worldBossFightExist) {
			t.Fatalf("MID %d duplicate: %d %#v", request.mid, got.HTTPStatus, got.Body)
		}
	}
}

func TestWorldBossUnsupportedMIDAndRentAreBadRequest(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := WorldBossDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &worldBossRouteStub{}}
	if got := dispatcher.Dispatch(context.Background(), worldBossRequest(629, map[string]any{}, now)); got.HTTPStatus != 400 {
		t.Fatalf("unsupported MID: %d %#v", got.HTTPStatus, got.Body)
	}
	if got := dispatcher.Dispatch(context.Background(), worldBossRequest(628, map[string]any{"campaign_id": int64(10011), "rent_player_id": int64(7)}, now)); got.HTTPStatus != 400 {
		t.Fatalf("rented sweep: %d %#v", got.HTTPStatus, got.Body)
	}
}

func TestWorldBossForgedInputIsBadRequest(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := WorldBossDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: worldBossStub{}}
	if got := dispatcher.Dispatch(context.Background(), worldBossRequest(624, map[string]any{"extra": int64(1)}, now)); got.HTTPStatus != 400 {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
	if got := dispatcher.Dispatch(context.Background(), worldBossRequest(626, map[string]any{"campaign_id": int64(10011), "formation": "not-a-hero"}, now)); got.HTTPStatus != 400 {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
}

package stockruntime

import (
	"context"
	"path/filepath"
	"testing"
	"time"

	bootstrap "gxb.local/backend/v2/internal/application/bootstrap"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type httpAuthority struct{ actor identity.ActorContext }

func (a httpAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

type httpEndpoints struct{}

func (httpEndpoints) EndpointFor(_ context.Context, role domainrt.PhysicalRole) (apprealtime.Endpoint, error) {
	return apprealtime.Endpoint{Host: "127.0.0.1", Port: 21000 + map[domainrt.PhysicalRole]int{domainrt.World: 1, domainrt.Service: 2, domainrt.Guild: 3}[role]}, nil
}
func actorForHTTP(t *testing.T) identity.ActorContext {
	t.Helper()
	mk := func(b byte) ids.UUID { var u ids.UUID; u[15] = b; return u }
	a, _ := identity.AccountIDFrom(mk(1))
	s, _ := identity.SessionIDFrom(mk(2))
	c, _ := identity.ContextIDFrom(mk(3))
	return identity.ActorContext{AccountID: a, AccountUID: identity.AccountUID("20000007"), SessionID: s, ContextID: c, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func env(mid uint16, room any, now time.Time) httpedge.DispatchRequest {
	params := map[string]any{"token": "bearer", "region": int64(1)}
	if room != nil {
		params["room_id"] = room
	}
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: operation.Context{StartedAt: now}, MID: mid, ReceivedAt: now, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: 1}}}
}
func capturedHTTPTracker(t *testing.T) *lobby.BootTracker {
	t.Helper()
	tr, err := lobby.NewCapturedBootTracker(lobby.EvidenceConfig{RunID: "http-test", ProcessRole: lobby.ProcessAPI, ProcessID: "api-test", SinkPath: filepath.Join(t.TempDir(), "http-test-api.jsonl"), MaxEvents: 1000, RingEvents: 1000})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = tr.Close() })
	return tr
}

func protocolEvidence(tr *lobby.BootTracker) []lobby.BootEvent {
	var out []lobby.BootEvent
	for _, e := range tr.Events() {
		if e.MID != 0 {
			out = append(out, e)
		}
	}
	return out
}

func TestDiscoveryBindsRoomToCanonicalActor(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	tracker := capturedHTTPTracker(t)
	svc := apprealtime.Service{Authority: httpAuthority{actorForHTTP(t)}, Endpoints: httpEndpoints{}}
	d := DiscoveryDispatcher{Realtime: svc, Tracker: tracker}
	r := d.Dispatch(context.Background(), env(192, int64(1), now))
	if r.HTTPStatus != 200 || r.Body["room_id"] != int64(1) || r.Body["port"] != int64(21001) {
		t.Fatalf("%+v", r)
	}
	r = d.Dispatch(context.Background(), env(192, int64(2), now))
	if r.HTTPStatus != 403 {
		t.Fatalf("forged room status=%d body=%v", r.HTTPStatus, r.Body)
	}
	e := protocolEvidence(tracker)
	if len(e) != 1 || e[0].Key != "WORLD" {
		t.Fatalf("%v", e)
	}
}
func TestLobbyFacadeRequiresCanonicalRegionAndRecordsExplicit(t *testing.T) {
	now := time.Unix(200, 0).UTC()
	tracker := capturedHTTPTracker(t)
	actor := actorForHTTP(t)
	d := LobbyDispatcher{Authority: httpAuthority{actor}, Tracker: tracker}
	r := d.Dispatch(context.Background(), env(2784, nil, now))
	if r.HTTPStatus != 200 || r.Body["is_award"] != int64(0) {
		t.Fatalf("%+v", r)
	}
	bad := env(2784, nil, now)
	bad.Envelope.Claims.Region = 2
	if got := d.Dispatch(context.Background(), bad); got.HTTPStatus != 403 {
		t.Fatalf("%+v", got)
	}
	e := protocolEvidence(tracker)
	if len(e) != 1 || e[0].Kind != lobby.BootExplicitHTTP {
		t.Fatalf("%v", e)
	}
}
func TestTimerFacadeClassifiedPassive(t *testing.T) {
	now := time.Unix(300, 0).UTC()
	tracker := capturedHTTPTracker(t)
	d := LobbyDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Tracker: tracker}
	if got := d.Dispatch(context.Background(), env(1056, nil, now)); got.HTTPStatus != 200 {
		t.Fatal(got.HTTPStatus)
	}
	if ev := protocolEvidence(tracker); len(ev) != 1 || ev[0].Kind != lobby.BootLegitTimer {
		t.Fatalf("%v", ev)
	}
}

type fakeBootstrap struct {
	mid18 bootstrap.MID18Result
	mid1  bootstrap.MID1Result
	err   error
}

func (f fakeBootstrap) MID18(context.Context, bootstrap.AccountCredentials, operation.Context) (bootstrap.MID18Result, error) {
	return f.mid18, f.err
}
func (f fakeBootstrap) MID1(context.Context, bootstrap.RuntimeMID1Request) (bootstrap.MID1Result, error) {
	return f.mid1, f.err
}

func TestBootstrapDispatcherMID18AndMID1Shapes(t *testing.T) {
	now := time.Unix(500, 0).UTC()
	fb := fakeBootstrap{
		mid18: bootstrap.MID18Result{Regions: []logicalserver.RegionView{{RegionID: 1, Name: "Server 1", CurID: 100000, MaxPlayerID: 199999}}, Players: []logicalserver.PlayerSummary{}, RecallRegions: []int32{}},
		mid1:  bootstrap.MID1Result{Token: "bearer", Region: 1, UID: identity.AccountUID("20000007"), Detail: map[string]any{"17": map[string]any{}}, IsNew: 1},
	}
	tracker := capturedHTTPTracker(t)
	d := BootstrapDispatcher{Bootstrap: fb, Tracker: tracker, ClientLogURL: "https://logs.invalid/client-log"}
	r18 := env(18, nil, now)
	r18.Envelope.Operation = operation.Context{StartedAt: now}
	r18.Envelope.Params = map[string]any{"sid": "s", "login_token": "l"}
	got := d.Dispatch(context.Background(), r18)
	if got.HTTPStatus != 200 || len(got.Body["regions"].([]any)) != 1 {
		t.Fatalf("%+v", got)
	}
	r1 := env(1, nil, now)
	r1.Envelope.Operation = operation.Context{StartedAt: now}
	r1.Envelope.Params = map[string]any{"sid": "s", "login_token": "l", "region": int64(1)}
	got = d.Dispatch(context.Background(), r1)
	if got.HTTPStatus != 200 || got.Body["token"] != "bearer" || got.Body["uid"] != identity.AccountUID("20000007") || got.Body["log_url"] != "https://logs.invalid/client-log" || got.Body["server_time"] != now.Unix() || got.Body["story_type"] != int64(0) || got.Body["is_debug"] != int64(0) || got.Body["is_old_top"] != int64(0) || len(protocolEvidence(tracker)) != len(lobby.EmbeddedMID1Records) {
		t.Fatalf("got=%+v events=%d", got, len(protocolEvidence(tracker)))
	}
}
func TestBootstrapDispatcherMID1EmptyLogURLIsHonestDisabledDefault(t *testing.T) {
	now := time.Unix(502, 0).UTC()
	r := env(1, nil, now)
	r.Envelope.Operation = operation.Context{StartedAt: now}
	r.Envelope.Params = map[string]any{"sid": "s", "login_token": "l", "region": int64(1)}
	fb := fakeBootstrap{mid1: bootstrap.MID1Result{Token: "bearer", Region: 1, UID: identity.AccountUID("20000007"), Detail: map[string]any{}, IsNew: 0}}
	got := (BootstrapDispatcher{Bootstrap: fb}).Dispatch(context.Background(), r)
	if got.HTTPStatus != 200 {
		t.Fatalf("%+v", got)
	}
	if v, ok := got.Body["log_url"]; !ok || v != "" {
		t.Fatalf("log_url must be explicitly present and empty by default: %#v", got.Body)
	}
}

func TestBootstrapDispatcherPreserves20018OnlyForCapacity(t *testing.T) {
	now := time.Unix(501, 0).UTC()
	r := env(1, nil, now)
	r.Envelope.Operation = operation.Context{StartedAt: now}
	r.Envelope.Params = map[string]any{"sid": "s", "login_token": "l", "region": int64(1)}
	got := (BootstrapDispatcher{Bootstrap: fakeBootstrap{err: logicalserver.ErrServerFull}}).Dispatch(context.Background(), r)
	if got.HTTPStatus != 200 || got.Body["error_code"] != int64(20018) {
		t.Fatalf("%+v", got)
	}
}

func TestPreloginDispatcherStockShapes(t *testing.T) {
	d := PreloginDispatcher{PublicEngineURL: "https://gxbengine.shares.zrok.io"}
	mk := func(mid uint16, params map[string]any) httpedge.DispatchRequest {
		return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, Params: params}}
	}

	center := d.Dispatch(context.Background(), mk(20480, map[string]any{"area": "tw"}))
	if center.HTTPStatus != 200 || center.Body["url"] != "https://gxbengine.shares.zrok.io" || center.Body["server_id"] != int64(1) || center.Body["back_domain"] != "" || center.Body["res_download_url"] != "" {
		t.Fatalf("center=%+v", center)
	}
	version := d.Dispatch(context.Background(), mk(2, map[string]any{"v": "1.631.0"}))
	if version.HTTPStatus != 200 || version.Body["is_inapp"] != int64(0) || version.Body["need_restart"] != int64(0) {
		t.Fatalf("version=%+v", version)
	}
	announce := d.Dispatch(context.Background(), mk(7, nil))
	if announce.HTTPStatus != 200 || announce.Body["contents"] != "{}" {
		t.Fatalf("announce=%+v", announce)
	}
	ab := d.Dispatch(context.Background(), mk(2864, map[string]any{"unique_key": "mtspy"}))
	if ab.HTTPStatus != 200 || ab.JSON != "B" {
		t.Fatalf("mtspy=%+v", ab)
	}
	other := d.Dispatch(context.Background(), mk(2864, map[string]any{"unique_key": "other"}))
	if other.JSON != "A" {
		t.Fatalf("other=%+v", other)
	}
}

func TestPreloginCenterRequiresPublicEngineURL(t *testing.T) {
	got := (PreloginDispatcher{}).Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 20480}})
	if got.HTTPStatus != 503 {
		t.Fatalf("got=%+v", got)
	}
}

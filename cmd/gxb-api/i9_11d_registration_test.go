package main

import (
	"context"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type registrationAuthority struct{ actor identity.ActorContext }

func (a registrationAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func registrationActor() identity.ActorContext {
	return identity.ActorContext{LogicalServerID: 1, PlayerID: 100001}
}

func registrationRequest(mid uint16, now time.Time) httpedge.DispatchRequest {
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation:  operation.Context{StartedAt: now},
		MID:        mid,
		ReceivedAt: now,
		Params:     map[string]any{"token": "bearer", "region": int64(1)},
		Claims:     wire.CredentialClaims{Token: "bearer", Region: 1},
	}}
}

func TestCompatRoutesRegister(t *testing.T) {
	router := httpedge.NewRouter()
	dispatcher := stockruntime.NewCompatDispatcher(registrationAuthority{actor: registrationActor()}, nil)
	if len(stockruntime.CompatMIDs) != 3 {
		t.Fatalf("CompatMIDs = %v", stockruntime.CompatMIDs)
	}
	for _, mid := range stockruntime.CompatMIDs {
		if err := router.Register(mid, dispatcher); err != nil {
			t.Fatalf("MID %d did not register: %v", mid, err)
		}
		if err := router.Register(mid, dispatcher); err == nil {
			t.Fatalf("MID %d registered twice", mid)
		}
	}
	for _, mid := range []uint16{1025, 1026, 1864} {
		if _, ok := router.Lookup(mid); !ok {
			t.Fatalf("MID %d missing after registration", mid)
		}
	}
}

func TestArenaResultRouteRegisters(t *testing.T) {
	router := httpedge.NewRouter()
	dispatcher := stockruntime.NewArenaResultDispatcher(registrationAuthority{actor: registrationActor()})
	for _, mid := range stockruntime.ArenaFightResultMIDs {
		if err := router.Register(mid, dispatcher); err != nil {
			t.Fatalf("MID %d did not register: %v", mid, err)
		}
	}
	if len(stockruntime.ArenaFightResultMIDs) != 1 || stockruntime.ArenaFightResultMIDs[0] != 279 {
		t.Fatalf("ArenaFightResultMIDs = %v", stockruntime.ArenaFightResultMIDs)
	}
	if _, ok := router.Lookup(279); !ok {
		t.Fatal("MID 279 missing after registration")
	}
}

func TestLobbyServesServerTimeThroughTheRouter(t *testing.T) {
	router := httpedge.NewRouter()
	dispatcher := stockruntime.LobbyDispatcher{Authority: registrationAuthority{actor: registrationActor()}}
	if err := router.Register(3, dispatcher); err != nil {
		t.Fatal(err)
	}
	routed, ok := router.Lookup(3)
	if !ok {
		t.Fatal("MID 3 missing after registration")
	}
	now := time.Unix(1_700_000_123, 0).UTC()
	response := routed.Dispatch(context.Background(), registrationRequest(3, now))
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("MID 3 status = %d", response.HTTPStatus)
	}
	if response.Body["server_time"] != now.Unix() || len(response.Body) != 1 {
		t.Fatalf("MID 3 body = %#v", response.Body)
	}
	replyconformance.Check(t, 3, response.Body)
}

func TestInactiveSurfaceMIDsAnswerTheSharedRefusal(t *testing.T) {
	router := httpedge.NewRouter()
	inactive := stockruntime.InactiveModeDispatcher{Authority: registrationAuthority{actor: registrationActor()}}
	for _, mid := range []uint16{17, 80, 84, 85, 208, 209, 210, 211, 212, 213, 246, 1412} {
		if err := router.Register(mid, inactive); err != nil {
			t.Fatalf("MID %d is not on the generated inactive list: %v", mid, err)
		}
	}
	for _, mid := range []uint16{17, 80, 84, 85, 208, 209, 210, 211, 212, 213, 246, 1412} {
		routed, _ := router.Lookup(mid)
		response := routed.Dispatch(context.Background(), registrationRequest(mid, time.Unix(100, 0).UTC()))
		if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35028) || !response.Inactive {
			t.Fatalf("MID %d inactive answer = %+v", mid, response)
		}
	}
}

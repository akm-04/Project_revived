package stockruntime

import (
	"context"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/adventure"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type adventureStub struct {
	err       error
	tableID   int64
	fight     app.FightRequest
	result    app.ResultRequest
	duplicate bool
}

func (s *adventureStub) List(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{"adventure_list": map[string]any{}}, s.err
}
func (s *adventureStub) Info(_ context.Context, _ identity.ActorContext, tableID int64, _ operation.Context) (map[string]any, error) {
	s.tableID = tableID
	return map[string]any{"detail": map[string]any{}}, s.err
}
func (s *adventureStub) BuyShop(_ context.Context, _ identity.ActorContext, tableID int64, _ operation.Context) (app.Response, error) {
	s.tableID = tableID
	return app.Response{Body: map[string]any{}, Duplicate: s.duplicate}, s.err
}
func (s *adventureStub) BuyCard(_ context.Context, _ identity.ActorContext, tableID int64, _ operation.Context) (app.Response, error) {
	s.tableID = tableID
	return app.Response{Body: map[string]any{"awards": []any{}}, Duplicate: s.duplicate}, s.err
}
func (s *adventureStub) Fight(_ context.Context, _ identity.ActorContext, request app.FightRequest, _ operation.Context) (app.Response, error) {
	s.fight = request
	return app.Response{Body: map[string]any{"is_win": int64(1)}, Duplicate: s.duplicate}, s.err
}
func (s *adventureStub) StartSingle(_ context.Context, _ identity.ActorContext, request app.FightRequest, _ operation.Context) (map[string]any, error) {
	s.fight = request
	return map[string]any{}, s.err
}
func (s *adventureStub) SettleSingle(_ context.Context, _ identity.ActorContext, request app.ResultRequest, _ operation.Context) (app.Response, error) {
	s.result = request
	return app.Response{Body: map[string]any{"awards": []any{}}, Duplicate: s.duplicate}, s.err
}

func adventureRequest(mid uint16, params map[string]any) httpedge.DispatchRequest {
	now := time.Unix(1700000000, 0).UTC()
	params["token"] = "bearer"
	params["region"] = int64(1)
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: operation.Context{StartedAt: now}, MID: mid, ReceivedAt: now, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: 1}}}
}

func TestAdventureDispatcherRoutesAndDuplicates(t *testing.T) {
	stub := &adventureStub{}
	dispatcher := AdventureDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: stub}
	if response := dispatcher.Dispatch(context.Background(), adventureRequest(2416, map[string]any{})); response.Body == nil || response.HTTPStatus != 200 {
		t.Fatalf("2416 %+v", response)
	}
	if response := dispatcher.Dispatch(context.Background(), adventureRequest(2417, map[string]any{"table_id": int64(10004)})); response.Body == nil || stub.tableID != 10004 {
		t.Fatalf("2417 %+v", response)
	}
	stub.duplicate = true
	response := dispatcher.Dispatch(context.Background(), adventureRequest(2418, map[string]any{"table_id": int64(1001)}))
	if response.Body["error_code"] != int64(30005) || stub.tableID != 1001 {
		t.Fatalf("2418 %+v", response)
	}
	stub.duplicate = false
	if response = dispatcher.Dispatch(context.Background(), adventureRequest(2419, map[string]any{"formation": "11|12", "pet_id": int64(21)})); response.HTTPStatus != 200 || len(stub.fight.Formation) != 2 || stub.fight.PetID != 21 {
		t.Fatalf("2419 %+v %+v", response, stub.fight)
	}
	if response = dispatcher.Dispatch(context.Background(), adventureRequest(2421, map[string]any{"formation": "11"})); response.HTTPStatus != 200 || len(stub.fight.Formation) != 1 {
		t.Fatalf("2421 %+v %+v", response, stub.fight)
	}
	if response = dispatcher.Dispatch(context.Background(), adventureRequest(2422, map[string]any{"star": int64(1), "total_damage": int64(50), "formation": "11"})); response.HTTPStatus != 200 || stub.result.Star != 1 || stub.result.Damage != 50 {
		t.Fatalf("2422 %+v %+v", response, stub.result)
	}
	if response = dispatcher.Dispatch(context.Background(), adventureRequest(2420, map[string]any{"table_id": int64(100001)})); response.HTTPStatus != 200 {
		t.Fatalf("2420 %+v", response)
	}
}

func TestAdventureDispatcherMapsExpiredAndInvalid(t *testing.T) {
	stub := &adventureStub{err: d.ErrExpired}
	dispatcher := AdventureDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: stub}
	response := dispatcher.Dispatch(context.Background(), adventureRequest(2417, map[string]any{"table_id": int64(10004)}))
	if response.Body["error_code"] != int64(35029) {
		t.Fatalf("expired %+v", response)
	}
	stub.err = d.ErrInvalid
	response = dispatcher.Dispatch(context.Background(), adventureRequest(2417, map[string]any{"table_id": int64(10004)}))
	if response.HTTPStatus != 400 {
		t.Fatalf("invalid %+v", response)
	}
	response = dispatcher.Dispatch(context.Background(), adventureRequest(2416, map[string]any{"unexpected": int64(1)}))
	if response.HTTPStatus != 400 {
		t.Fatalf("params %+v", response)
	}
}

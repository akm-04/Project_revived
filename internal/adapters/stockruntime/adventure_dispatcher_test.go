package stockruntime

import (
	"context"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/adventure"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/economy"
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
	pick      app.PickRequest
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
func (s *adventureStub) PrepareDefense(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) StartDefense(_ context.Context, _ identity.ActorContext, request app.FightRequest, _ int64, _ operation.Context) (map[string]any, error) {
	s.fight = request
	return map[string]any{}, s.err
}
func (s *adventureStub) DefenseResult(_ context.Context, _ identity.ActorContext, request app.ResultRequest, _ int64, _ operation.Context) (app.Response, error) {
	s.result = request
	return app.Response{Body: map[string]any{}, Duplicate: s.duplicate}, s.err
}
func (s *adventureStub) QuitDefense(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) EnterDefense(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) InviteDefense(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) KickDefense(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) ExitDefense(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) CreateCoop(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) EnterCoop(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) InviteCoop(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) RemoveCoop(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) ExitCoop(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) EnterTeamFight(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) SelectCoop(_ context.Context, _ identity.ActorContext, request app.PickRequest, _ operation.Context) (map[string]any, error) {
	s.pick = request
	return map[string]any{}, s.err
}
func (s *adventureStub) PrepareCoop(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
}
func (s *adventureStub) StartCoop(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return map[string]any{}, s.err
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

func TestAdventureDispatcherRoutesRoomMIDs(t *testing.T) {
	stub := &adventureStub{}
	dispatcher := AdventureDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: stub}
	cases := []struct {
		mid    uint16
		params map[string]any
	}{
		{2410, map[string]any{"star": int64(1), "total_damage": int64(10), "monster_pos": int64(1), "formation": "11", "table_id": int64(10001)}},
		{2411, map[string]any{}},
		{2412, map[string]any{"monster_pos": int64(1), "table_id": int64(10001)}},
		{2413, map[string]any{"monster_pos": int64(1), "table_id": int64(10001)}},
		{2423, map[string]any{"table_id": int64(10006)}},
		{2424, map[string]any{"player_id": int64(7002), "table_id": int64(10001)}},
		{2425, map[string]any{"room_id": int64(9), "table_id": int64(10006)}},
		{2426, map[string]any{"table_id": int64(10006)}},
		{2427, map[string]any{"player_id": int64(7002), "table_id": int64(10006)}},
		{2428, map[string]any{"table_id": int64(10006)}},
		{2429, map[string]any{"partner_id": int64(11), "pos": int64(1), "table_id": int64(10006)}},
		{2430, map[string]any{"table_id": int64(10006)}},
		{2431, map[string]any{"formation": "11", "pet_id": int64(0), "monster_pos": int64(1), "table_id": int64(10001)}},
	}
	for _, item := range cases {
		response := dispatcher.Dispatch(context.Background(), adventureRequest(item.mid, item.params))
		if response.HTTPStatus != 200 {
			t.Fatalf("mid %d: %+v", item.mid, response)
		}
	}
	if stub.result.Star != 1 || stub.pick.PartnerID != 11 {
		t.Fatalf("parsed result %+v pick %+v", stub.result, stub.pick)
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
	stub.err = sr.ErrAlreadyInRoom
	response = dispatcher.Dispatch(context.Background(), adventureRequest(2417, map[string]any{"table_id": int64(10004)}))
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("already in room %+v", response)
	}
	for _, serverError := range []error{economy.ErrUnknownResource, d.ErrUnavailable} {
		stub.err = serverError
		response = dispatcher.Dispatch(context.Background(), adventureRequest(2417, map[string]any{"table_id": int64(10004)}))
		if response.HTTPStatus != 503 {
			t.Fatalf("server failure %v -> %+v", serverError, response)
		}
	}
	stub.err = nil
	stub.duplicate = true
	response = dispatcher.Dispatch(context.Background(), adventureRequest(2422, map[string]any{"star": int64(1), "total_damage": int64(50), "formation": "11"}))
	if response.HTTPStatus != 200 || response.Body["error_code"] != int64(30005) {
		t.Fatalf("2422 duplicate %+v", response)
	}
}

package stockruntime

import (
	"context"
	"net/http"
	"testing"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type composeBookFake struct {
	owned        bool
	ownErr       error
	commandErr   error
	body         map[string]any
	commandCalls int
}

func (f *composeBookFake) Command(context.Context, identity.ActorContext, appbook.Command, operation.Context) (appbook.Result, error) {
	f.commandCalls++
	return appbook.Result{Body: f.body}, f.commandErr
}

func (f *composeBookFake) Read(context.Context, identity.ActorContext, uint16, operation.Context) (map[string]any, error) {
	return nil, book.ErrInvalid
}

func (f *composeBookFake) OwnsComposeItem(context.Context, int64, operation.Context) (bool, error) {
	return f.owned, f.ownErr
}

type composeFurnitureFake struct {
	owns     bool
	ownErr   error
	body     map[string]any
	err      error
	ownCalls int
	calls    int
	item     int64
	units    int64
}

func (f *composeFurnitureFake) OwnsFurnitureComposeItem(context.Context, int64, operation.Context) (bool, error) {
	f.ownCalls++
	return f.owns, f.ownErr
}

func (f *composeFurnitureFake) ComposeFurnitureItem(_ context.Context, _ identity.ActorContext, itemID, amount int64, _ operation.Context) (map[string]any, error) {
	f.calls++
	f.item = itemID
	f.units = amount
	return f.body, f.err
}

type composeEquipmentFake struct {
	body  map[string]any
	err   error
	calls int
	item  int64
	units int64
}

func (f *composeEquipmentFake) ComposeEquipmentItem(_ context.Context, _ identity.ActorContext, itemID, amount int64, _ operation.Context) (map[string]any, error) {
	f.calls++
	f.item = itemID
	f.units = amount
	return f.body, f.err
}

func TestA128ComposeRoutesEquipmentToCharacterOwner(t *testing.T) {
	equipment := &composeEquipmentFake{body: map[string]any{}}
	dispatcher := ComposeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Book: &composeBookFake{owned: false}, Furniture: &composeFurnitureFake{}, Equipment: equipment}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(20001361)}))
	if got.HTTPStatus != http.StatusOK {
		t.Fatalf("status=%d body=%#v", got.HTTPStatus, got.Body)
	}
	if equipment.calls != 1 || equipment.item != 20001361 || equipment.units != 1 {
		t.Fatalf("equipment port calls=%d item=%d units=%d", equipment.calls, equipment.item, equipment.units)
	}
}

func TestA128ComposeRoutesBookToBookOwner(t *testing.T) {
	bookOwner := &composeBookFake{owned: true, body: map[string]any{}}
	equipment := &composeEquipmentFake{}
	dispatcher := ComposeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Book: bookOwner, Furniture: &composeFurnitureFake{}, Equipment: equipment}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(130001001)}))
	if got.HTTPStatus != http.StatusOK || bookOwner.commandCalls != 1 || equipment.calls != 0 {
		t.Fatalf("status=%d book calls=%d equipment calls=%d body=%#v", got.HTTPStatus, bookOwner.commandCalls, equipment.calls, got.Body)
	}
}

func TestA128ComposeRoutesFurnitureToDormOwner(t *testing.T) {
	furniture := &composeFurnitureFake{owns: true, body: map[string]any{}}
	equipment := &composeEquipmentFake{}
	dispatcher := ComposeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Book: &composeBookFake{}, Furniture: furniture, Equipment: equipment}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(50031013), "item_num": int64(2)}))
	if got.HTTPStatus != http.StatusOK {
		t.Fatalf("status=%d body=%#v", got.HTTPStatus, got.Body)
	}
	if furniture.calls != 1 || furniture.item != 50031013 || furniture.units != 2 || equipment.calls != 0 {
		t.Fatalf("furniture calls=%d item=%d units=%d equipment calls=%d", furniture.calls, furniture.item, furniture.units, equipment.calls)
	}
}

func TestA128ComposeRoutesBlueprintToDormOwner(t *testing.T) {
	furniture := &composeFurnitureFake{owns: true, body: map[string]any{}}
	equipment := &composeEquipmentFake{}
	dispatcher := ComposeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Book: &composeBookFake{}, Furniture: furniture, Equipment: equipment}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(50020013)}))
	if got.HTTPStatus != http.StatusOK || furniture.calls != 1 || equipment.calls != 0 {
		t.Fatalf("status=%d furniture calls=%d equipment calls=%d body=%#v", got.HTTPStatus, furniture.calls, equipment.calls, got.Body)
	}
}

func TestA128ComposeFurnitureRefusalIs409(t *testing.T) {
	furniture := &composeFurnitureFake{owns: true, err: appdorm.ErrFurnitureLevelTooLow}
	dispatcher := ComposeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Book: &composeBookFake{}, Furniture: furniture, Equipment: &composeEquipmentFake{}}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(50031013)}))
	if got.HTTPStatus != http.StatusConflict || got.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("status=%d body=%#v", got.HTTPStatus, got.Body)
	}
}

func TestA128ComposeRefusesUnqualifiedCategory(t *testing.T) {
	equipment := &composeEquipmentFake{err: apphero.ErrEquipmentComposeUnqualified}
	dispatcher := ComposeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Book: &composeBookFake{}, Furniture: &composeFurnitureFake{}, Equipment: equipment}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(999999)}))
	if got.HTTPStatus != http.StatusConflict || got.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("status=%d body=%#v", got.HTTPStatus, got.Body)
	}
}

func TestA128ComposeRejectsMalformedAmount(t *testing.T) {
	equipment := &composeEquipmentFake{}
	dispatcher := ComposeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Book: &composeBookFake{}, Furniture: &composeFurnitureFake{}, Equipment: equipment}
	for _, amount := range []any{int64(0), int64(-1), "not-a-number"} {
		got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(20001361), "item_num": amount}))
		if got.HTTPStatus != http.StatusBadRequest || equipment.calls != 0 {
			t.Fatalf("amount=%#v status=%d calls=%d body=%#v", amount, got.HTTPStatus, equipment.calls, got.Body)
		}
	}
}

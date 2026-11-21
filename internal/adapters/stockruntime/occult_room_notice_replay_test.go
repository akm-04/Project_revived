package stockruntime

import (
	"context"
	"testing"

	app "gxb.local/backend/v2/internal/application/occult"
	"gxb.local/backend/v2/internal/domain/identity"
)

type occultClosedRoomSource struct{ view app.RoomNotice }

func (s occultClosedRoomSource) ReadRoomNotice(context.Context, string) (app.RoomNotice, bool, error) {
	return s.view, true, nil
}

// A redelivered wakeup for the same closed room must not re-send the final
// report: the ledger keeps the terminal-push cursor after the last member is
// removed.
func TestOccultClosedRoomDoesNotForgetItsTerminalPushes(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	view := app.RoomNotice{RoomID: 7, Closed: true,
		Removed: []app.PlayerBody{{Player: identity.PlayerID(2)}},
		Pushes:  []app.RoomPush{{Sequence: 5, Function: 7, Bodies: []app.PlayerBody{{Player: 2}, {Player: 3}}}}}
	handler := OccultRoomNoticeHandler{Service: occultClosedRoomSource{view: view},
		Delivery: RoomDelivery{Registry: registry, MaxHandles: 10}, Delivered: NewRoomNoticeLedger(),
		Online: func(identity.PlayerID) bool { return true }}
	if err := handler.ReloadAndDeliver(context.Background(), "7"); err != nil {
		t.Fatal(err)
	}
	if fresh := handler.Delivered.terminalPushes(view.RoomID, view.Pushes); len(fresh) != 0 {
		t.Fatalf("a repeated closed-room wakeup re-sends %+v", fresh)
	}
	if err := handler.ReloadAndDeliver(context.Background(), "7"); err != nil {
		t.Fatal(err)
	}
}

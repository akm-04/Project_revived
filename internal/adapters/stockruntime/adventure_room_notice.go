package stockruntime

import (
	"context"
	"errors"
	"sync"
	"time"

	app "gxb.local/backend/v2/internal/application/adventure"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

// AdventureRoomNoticeType is the stock ROOM_NOTICE; room_type 2 routes the
// defense room and 3 the illusion co-op room.
const AdventureRoomNoticeType int64 = 32

const (
	adventureFunctionRoomChange int64 = 1
	adventureFunctionTeamEnter  int64 = 2
	adventureFunctionTeamPick   int64 = 3
	adventureFunctionTeamReady  int64 = 4
	adventureFunctionTeamFight  int64 = 5
	adventureFunctionRoomBusy   int64 = 6
	adventureFunctionRoomFight  int64 = 7
	adventureFunctionRoomQuit   int64 = 8
)

type AdventureRoomNoticeSource interface {
	ReadRoomNotice(context.Context, string) (app.RoomNotice, bool, error)
}

func NewAdventureRoomNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: AdventureRoomNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateAdventureRoomNotice},
	})
}

func ValidateAdventureRoomNotice(value any) error {
	body, ok := noticeParams(value)
	if !ok {
		return rt.ErrInvalidS2CPayload
	}
	function, functionOK := body["function_type"].(int64)
	roomType, roomTypeOK := body["room_type"].(int64)
	if !functionOK || function < adventureFunctionRoomChange || function > adventureFunctionRoomQuit || !roomTypeOK || (roomType != d.RoomTypeDefense && roomType != d.RoomTypeIllusion) {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func adventureRoomFrame(function, roomType int64, body map[string]any) (*amf3.Object, error) {
	params := make(map[string]any, len(body)+2)
	for key, value := range body {
		params[key] = value
	}
	params["function_type"], params["room_type"] = function, roomType
	converted, err := amfFromValue(params)
	if err != nil {
		return nil, err
	}
	return &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: AdventureRoomNoticeType}, {Name: "params", Value: converted}}}, nil
}

// adventurePushLedger sends each recorded room status push once.
// shortcut: in memory, so a realtime restart repeats one wakeup's pushes.
type adventurePushLedger struct {
	mu    sync.Mutex
	seen  map[int64]int64
	known map[int64]bool
}

func NewAdventurePushLedger() *adventurePushLedger {
	return &adventurePushLedger{seen: map[int64]int64{}, known: map[int64]bool{}}
}

func (l *adventurePushLedger) newPushes(room int64, pushes []app.RoomPush) []app.RoomPush {
	l.mu.Lock()
	defer l.mu.Unlock()
	known := l.known[room]
	l.known[room] = true
	var fresh []app.RoomPush
	for _, push := range pushes {
		if known && push.Sequence > l.seen[room] {
			fresh = append(fresh, push)
		}
		if push.Sequence > l.seen[room] {
			l.seen[room] = push.Sequence
		}
	}
	return fresh
}

// AdventureRoomNoticeHandler pushes one room's state when its wakeup arrives.
type AdventureRoomNoticeHandler struct {
	Service         AdventureRoomNoticeSource
	Delivery        RoomDelivery
	Delivered       *RoomNoticeLedger
	Pushes          *adventurePushLedger
	OnDeliveryError func(error)
}

func (h AdventureRoomNoticeHandler) ReloadAndDeliver(c context.Context, reference string) error {
	if h.Service == nil || h.Delivered == nil || h.Pushes == nil {
		return errors.New("adventure room notice unavailable")
	}
	c, cancel := context.WithTimeout(c, 2*time.Second)
	defer cancel()
	view, found, err := h.Service.ReadRoomNotice(c, reference)
	if err != nil || !found {
		return err
	}
	seated := make([]identity.PlayerID, 0, len(view.Seated))
	for _, member := range view.Seated {
		seated = append(seated, member.Player)
	}
	h.Delivered.reseat(view.RoomID, uint16(AdventureRoomNoticeType), seated)
	for _, removal := range view.Removed {
		if len(h.Delivered.undelivered(view.RoomID, uint16(AdventureRoomNoticeType), []identity.PlayerID{removal.Player})) == 0 {
			continue
		}
		frame, err := adventureRoomFrame(adventureFunctionRoomChange, view.RoomType, removal.Body)
		if err != nil {
			return err
		}
		if err = h.Delivery.Deliver(c, removal.Player, mids.MIDPlayerNotice, frame); err != nil {
			return err
		}
		h.Delivered.markDelivered(view.RoomID, uint16(AdventureRoomNoticeType), removal.Player)
	}
	for _, member := range view.Seated {
		frame, err := adventureRoomFrame(adventureFunctionRoomChange, view.RoomType, member.Body)
		if err != nil {
			return err
		}
		if err = h.Delivery.Deliver(c, member.Player, mids.MIDPlayerNotice, frame); err != nil {
			return err
		}
	}
	for _, push := range h.Pushes.newPushes(view.RoomID, view.Pushes) {
		for _, body := range push.Bodies {
			frame, err := adventureRoomFrame(push.Function, view.RoomType, body.Body)
			if err != nil {
				return err
			}
			if err = h.Delivery.Deliver(c, body.Player, mids.MIDPlayerNotice, frame); err != nil {
				return err
			}
		}
	}
	if len(seated) == 0 {
		h.Delivered.forget(view.RoomID)
	}
	return nil
}

package stockruntime

import (
	"context"
	"errors"
	"time"

	app "gxb.local/backend/v2/internal/application/occult"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

const (
	// OccultRoomNoticeType is the stock NoticeType.ROOM_NOTICE; room_type 1 routes
	// the params to Occult:handleRoomNotice.
	OccultRoomNoticeType int64 = 32
	// OccultInviteNoticeType is the stock FriendNoticeType.OCCULT a 2369 invite creates.
	OccultInviteNoticeType int64 = 7
	occultRoomTypeMulti    int64 = 1

	occultFunctionRoomChange int64 = 1
	occultFunctionChangePos  int64 = 8
	occultFunctionEvent      int64 = 9
	occultFunctionOnline     int64 = 12
	occultFunctionLast       int64 = 12
)

type OccultRoomNoticeSource interface {
	ReadRoomNotice(context.Context, string) (app.RoomNotice, bool, error)
}

// OccultRoomNoticeHandler pushes a room's state when its wakeup arrives.
// 2362 stays authoritative: a lost push is repaired by the next read.
type OccultRoomNoticeHandler struct {
	Service         OccultRoomNoticeSource
	Delivery        RoomDelivery
	Delivered       *RoomNoticeLedger
	Online          func(identity.PlayerID) bool
	OnDeliveryError func(error)
}

func NewOccultRoomNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: OccultRoomNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateOccultRoomNotice},
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: OccultInviteNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateOccultInviteNotice},
	})
}

func noticeParams(value any) (map[string]any, bool) {
	object, ok := value.(*amf3.Object)
	if !ok || object == nil {
		return nil, false
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 2 {
		return nil, false
	}
	params, ok := fields["params"].(*amf3.Object)
	if !ok || params == nil {
		return nil, false
	}
	body, err := params.StrictMap()
	return body, err == nil
}

func ValidateOccultRoomNotice(value any) error {
	body, ok := noticeParams(value)
	if !ok {
		return rt.ErrInvalidS2CPayload
	}
	function, functionOK := body["function_type"].(int64)
	roomType, roomTypeOK := body["room_type"].(int64)
	if !functionOK || function < occultFunctionRoomChange || function > occultFunctionLast || !roomTypeOK || roomType != occultRoomTypeMulti {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func ValidateOccultInviteNotice(value any) error {
	body, ok := noticeParams(value)
	if !ok {
		return rt.ErrInvalidS2CPayload
	}
	room, roomOK := body["room_id"].(int64)
	chapter, chapterOK := body["chapter_id"].(int64)
	player, playerOK := body["player_info"].(*amf3.Object)
	if !roomOK || room <= 0 || !chapterOK || chapter <= 0 || !playerOK || player == nil {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func occultNotice(noticeType int64, params map[string]any) (*amf3.Object, error) {
	converted, err := amfFromValue(params)
	if err != nil {
		return nil, err
	}
	return &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: noticeType}, {Name: "params", Value: converted}}}, nil
}

func occultRoomFrame(function int64, body map[string]any) (*amf3.Object, error) {
	params := make(map[string]any, len(body)+2)
	for key, value := range body {
		params[key] = value
	}
	params["function_type"], params["room_type"] = function, occultRoomTypeMulti
	return occultNotice(OccultRoomNoticeType, params)
}

func (h OccultRoomNoticeHandler) ReloadAndDeliver(c context.Context, reference string) error {
	if h.Service == nil || h.Delivered == nil || h.Online == nil {
		return errors.New("occult room notice unavailable")
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
	h.Delivered.reseat(view.RoomID, occultRoomNoticeKey, seated)
	steps := []func(context.Context, app.RoomNotice, []identity.PlayerID) error{h.deliverRemovals, h.deliverRoomChanges, h.deliverEvents, h.deliverPushes, h.deliverPositions, h.deliverOnline, h.deliverInvites}
	for _, step := range steps {
		if err = step(c, view, seated); err != nil {
			return err
		}
	}
	if len(seated) == 0 {
		h.Delivered.forget(view.RoomID)
	}
	return nil
}

const (
	occultRoomNoticeKey   = uint16(OccultRoomNoticeType)
	occultInviteNoticeKey = uint16(OccultInviteNoticeType)
)

func (h OccultRoomNoticeHandler) send(c context.Context, player identity.PlayerID, frame *amf3.Object, err error) error {
	if err != nil {
		return err
	}
	return h.Delivery.Deliver(c, player, mids.MIDPlayerNotice, frame)
}

func (h OccultRoomNoticeHandler) deliverRemovals(c context.Context, view app.RoomNotice, _ []identity.PlayerID) error {
	for _, removal := range view.Removed {
		if len(h.Delivered.undelivered(view.RoomID, occultRoomNoticeKey, []identity.PlayerID{removal.Player})) == 0 {
			continue
		}
		frame, err := occultRoomFrame(occultFunctionRoomChange, removal.Body)
		if err = h.send(c, removal.Player, frame, err); err != nil {
			return err
		}
		h.Delivered.markDelivered(view.RoomID, occultRoomNoticeKey, removal.Player)
	}
	return nil
}

func (h OccultRoomNoticeHandler) deliverRoomChanges(c context.Context, view app.RoomNotice, _ []identity.PlayerID) error {
	for _, member := range view.Seated {
		frame, err := occultRoomFrame(occultFunctionRoomChange, member.Body)
		if err = h.send(c, member.Player, frame, err); err != nil {
			return err
		}
	}
	return nil
}

// deliverEvents sends each applied event once. The first sight of a room only
// records its newest sequence: the ROOM_CHANGE just sent already carries it.
func (h OccultRoomNoticeHandler) deliverEvents(c context.Context, view app.RoomNotice, seated []identity.PlayerID) error {
	fresh := h.Delivered.newEvents(view.RoomID, view.Events)
	for _, event := range fresh {
		body := map[string]any{"event_id": event.Type}
		if event.Type == int64(d.EventIncreaseDispatch) {
			body["dispatch_limit"] = event.DispatchLimit
		}
		frame, err := occultRoomFrame(occultFunctionEvent, body)
		if err != nil {
			return err
		}
		for _, player := range seated {
			if err = h.send(c, player, frame, nil); err != nil {
				return err
			}
		}
	}
	return nil
}

// deliverPushes sends each recorded team or fight-status push once, in server order.
func (h OccultRoomNoticeHandler) deliverPushes(c context.Context, view app.RoomNotice, _ []identity.PlayerID) error {
	for _, push := range h.Delivered.newPushes(view.RoomID, view.Pushes) {
		for _, body := range push.Bodies {
			frame, err := occultRoomFrame(push.Function, body.Body)
			if err = h.send(c, body.Player, frame, err); err != nil {
				return err
			}
		}
	}
	return nil
}

// deliverPositions tells the others where a member moved since the last wakeup.
func (h OccultRoomNoticeHandler) deliverPositions(c context.Context, view app.RoomNotice, seated []identity.PlayerID) error {
	for _, moved := range h.Delivered.movedPositions(view.RoomID, view.Positions) {
		frame, err := occultRoomFrame(occultFunctionChangePos, map[string]any{"player_id": int64(moved.Player), "stay_pos": moved.Position})
		if err != nil {
			return err
		}
		for _, player := range seated {
			if player == moved.Player {
				continue
			}
			if err = h.send(c, player, frame, nil); err != nil {
				return err
			}
		}
	}
	return nil
}

// deliverOnline tells the others when a member's connection state changed.
// shortcut: presence is sampled on room wakeups only, so a drop between two
// wakeups shows at the next one; 2362 stays authoritative.
func (h OccultRoomNoticeHandler) deliverOnline(c context.Context, view app.RoomNotice, seated []identity.PlayerID) error {
	states := make(map[identity.PlayerID]bool, len(seated))
	for _, player := range seated {
		states[player] = h.Online(player)
	}
	for _, changed := range h.Delivered.changedOnline(view.RoomID, states) {
		online := int64(0)
		if changed.Online {
			online = 1
		}
		frame, err := occultRoomFrame(occultFunctionOnline, map[string]any{"player_id": int64(changed.Player), "is_online": online})
		if err != nil {
			return err
		}
		for _, player := range seated {
			if player == changed.Player {
				continue
			}
			if err = h.send(c, player, frame, nil); err != nil {
				return err
			}
		}
	}
	return nil
}

func (h OccultRoomNoticeHandler) deliverInvites(c context.Context, view app.RoomNotice, _ []identity.PlayerID) error {
	for _, invite := range view.Invites {
		if len(h.Delivered.undelivered(view.RoomID, occultInviteNoticeKey, []identity.PlayerID{invite.Player})) == 0 {
			continue
		}
		frame, err := occultNotice(OccultInviteNoticeType, invite.Body)
		if err = h.send(c, invite.Player, frame, err); err != nil {
			return err
		}
		h.Delivered.markDelivered(view.RoomID, occultInviteNoticeKey, invite.Player)
	}
	return nil
}

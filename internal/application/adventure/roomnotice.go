package adventure

import (
	"context"
	"strconv"

	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/sharedroom"
)

// PlayerBody is one addressee's share of a room push.
type PlayerBody struct {
	Player identity.PlayerID
	Body   map[string]any
}

// RoomPush is one not-yet-delivered or repeatable room status push.
type RoomPush struct {
	Sequence int64
	Function int64
	Bodies   []PlayerBody
}

// RoomNotice is the realtime projection of one Adventure room.
type RoomNotice struct {
	RoomID   int64
	RoomType int64
	Seated   []PlayerBody
	Removed  []PlayerBody
	Pushes   []RoomPush
	Invites  []PlayerBody
}

// ReadRoomNotice reads a room for the realtime route; it never writes.
func (s Mode) ReadRoomNotice(c context.Context, reference string) (RoomNotice, bool, error) {
	roomID, err := strconv.ParseInt(reference, 10, 64)
	if err != nil || roomID <= 0 {
		return RoomNotice{}, false, d.ErrInvalid
	}
	room, found, err := s.RoomStore.ReadRoomTx(c, s.Fresh, roomID)
	if err != nil || !found || room.Family != RoomFamily {
		return RoomNotice{}, false, err
	}
	state, err := s.roomState(room)
	if err != nil {
		return RoomNotice{}, false, err
	}
	out := RoomNotice{RoomID: room.ID, RoomType: state.RoomType}
	if room.Status == sharedroom.StatusOpen {
		seated, err := s.seatedBodies(c, room, state)
		if err != nil {
			return RoomNotice{}, false, err
		}
		out.Seated = seated
	}
	out.Removed, err = s.removedBodies(c, room, state)
	if err != nil {
		return RoomNotice{}, false, err
	}
	out.Pushes = roomPushes(state, out.Seated)
	return out, true, nil
}

func (s Mode) seatedBodies(c context.Context, room sharedroom.Room, state d.RoomState) ([]PlayerBody, error) {
	var bodies []PlayerBody
	for _, member := range room.Members() {
		body, err := s.roomChangeBody(c, room, state)
		if err != nil {
			return nil, err
		}
		bodies = append(bodies, PlayerBody{Player: member, Body: body})
	}
	return bodies, nil
}

func (s Mode) roomChangeBody(c context.Context, room sharedroom.Room, state d.RoomState) (map[string]any, error) {
	var info map[string]any
	var err error
	if state.RoomType == d.RoomTypeDefense {
		info, err = s.defenseRoomInfo(c, s.Fresh, room, state)
	} else {
		info, err = s.coopRoomInfo(c, s.Fresh, room, state)
	}
	if err != nil {
		return nil, err
	}
	return map[string]any{"room_id": room.ID, "room_type": state.RoomType, "room_info": info,
		"self_info": map[string]any{"room_id": room.ID}}, nil
}

// removedBodies are the room_id 0 changes of seats that no longer sit here. A
// player now holding another Adventure room is skipped.
func (s Mode) removedBodies(c context.Context, room sharedroom.Room, state d.RoomState) ([]PlayerBody, error) {
	family := DefenseFamily()
	if state.RoomType == d.RoomTypeIllusion {
		family = IllusionFamily()
	}
	var bodies []PlayerBody
	for _, seat := range room.Seats {
		if seat.Stage == sharedroom.SeatSeated && room.Status == sharedroom.StatusOpen {
			continue
		}
		current, found, err := s.RoomStore.ReadPlayerRoomTx(c, s.Fresh, seat.Player, family.Name, family.Slot)
		if err != nil {
			return nil, err
		}
		if found && current.ID != room.ID {
			continue
		}
		bodies = append(bodies, PlayerBody{Player: seat.Player, Body: map[string]any{
			"room_id": int64(0), "room_type": state.RoomType, "self_info": map[string]any{"room_id": int64(0)}}})
	}
	return bodies, nil
}

func roomPushes(state d.RoomState, seated []PlayerBody) []RoomPush {
	var out []RoomPush
	for _, record := range state.Pushes {
		push := RoomPush{Sequence: record.Sequence, Function: record.Function}
		for _, member := range seated {
			if !record.All && int64(member.Player) == record.Actor {
				continue
			}
			push.Bodies = append(push.Bodies, PlayerBody{Player: member.Player, Body: record.Body})
		}
		out = append(out, push)
	}
	return out
}

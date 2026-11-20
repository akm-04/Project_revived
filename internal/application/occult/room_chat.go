package occult

import (
	"context"
	"fmt"

	gen "gxb.local/backend/v2/internal/application/generation"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// SendRoomChat answers a 515 whose selectType is OCCULT: the line is stored on
// the actor's room and the room wakeup pushes 516 to the addressed member.
func (s Mode) SendRoomChat(c context.Context, a identity.ActorContext, recipient identity.PlayerID, message friendmessage.Message, op operation.Context) error {
	if recipient == a.PlayerID || !recipient.Valid() {
		return d.ErrInvalid
	}
	payload, err := message.Canonical()
	if err != nil {
		return d.ErrInvalid
	}
	if op, err = s.pin(c, op); err != nil {
		return err
	}
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(), Apply: func(_ context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		if message.HasRoomID && message.RoomID > 0 && message.RoomID != room.ID {
			return fmt.Errorf("%w: room mismatch", d.ErrRefused)
		}
		if !roomSeat(*room, recipient) {
			return fmt.Errorf("%w: not a room mate", d.ErrRefused)
		}
		state, err := d.LoadRunState(room.Payload)
		if err != nil {
			return err
		}
		state.AddChat(sharedroom.ChatMessage{Sender: int64(a.PlayerID), Recipients: []int64{int64(recipient)},
			Message: payload, At: sc.Operation.DecisionAt().Unix()})
		raw, err := state.Encode()
		if err != nil {
			return err
		}
		return room.SetPayload(raw, sc.Operation.DecisionAt())
	}}, op)
	return err
}

func roomSeat(room sharedroom.Room, player identity.PlayerID) bool {
	for _, member := range room.Members() {
		if member == player {
			return true
		}
	}
	return false
}

package adventure

import (
	"context"
	"fmt"

	gen "gxb.local/backend/v2/internal/application/generation"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// SendRoomChat answers a 515 whose selectType is ADVENTURE_ILLUSION or
// ADVENTURE_DEFENSE: the line is stored on that mode's room and the room wakeup
// pushes 516 to the addressed member.
func (s Mode) SendRoomChat(c context.Context, a identity.ActorContext, recipient identity.PlayerID, message friendmessage.Message, op operation.Context) error {
	if recipient == a.PlayerID || !recipient.Valid() {
		return d.ErrInvalid
	}
	var family sr.Family
	switch message.SelectType {
	case friendmessage.SelectAdventureIllusion:
		family = IllusionFamily()
	case friendmessage.SelectAdventureDefense:
		family = DefenseFamily()
	default:
		return d.ErrInvalid
	}
	payload, err := message.Canonical()
	if err != nil {
		return d.ErrInvalid
	}
	if op, err = s.pin(c, op); err != nil {
		return err
	}
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: family, Apply: func(_ context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		if message.HasRoomID && message.RoomID > 0 && message.RoomID != room.ID {
			return fmt.Errorf("%w: room mismatch", d.ErrRefused)
		}
		if !roomSeat(*room, recipient) {
			return fmt.Errorf("%w: not a room mate", d.ErrRefused)
		}
		return s.mutateRoom(sc, room, func(state *d.RoomState) error {
			state.AddChat(sharedroom.ChatMessage{Sender: int64(a.PlayerID), Recipients: []int64{int64(recipient)},
				Message: payload, At: sc.Operation.DecisionAt().Unix()})
			return nil
		})
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

package channelchatread

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	app "gxb.local/backend/v2/internal/application/adventure"
	"gxb.local/backend/v2/internal/application/channelchat"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// DefenseRoomReader reads the canonical Adventure defense room behind a
// structured defense invitation chat.
type DefenseRoomReader struct {
	Store sharedroomstore.Store
}

func (r DefenseRoomReader) ReadDefenseTx(c context.Context, t tx.Tx, a ar.Admission, _ time.Time, selection channelchat.RoomSelection) (channelchat.Owned[channelchat.Defense], error) {
	if t == nil || selection.RoomID <= 0 {
		return channelchat.Owned[channelchat.Defense]{}, channelchat.ErrInvalidStructured
	}
	room, found, err := r.Store.ReadRoomTx(c, t, selection.RoomID)
	if err != nil {
		return channelchat.Owned[channelchat.Defense]{}, err
	}
	if !found || room.Family != app.RoomFamily || room.Slot != app.DefenseSlot || !shareableRoom(room, a) {
		return channelchat.Owned[channelchat.Defense]{}, channelchat.ErrInvalidStructured
	}
	state, err := d.LoadRoomState(room.Payload)
	if err != nil || state.RoomType != d.RoomTypeDefense {
		return channelchat.Owned[channelchat.Defense]{}, channelchat.ErrInvalidStructured
	}
	return channelchat.Owned[channelchat.Defense]{
		Value:  channelchat.Defense{RoomID: room.ID, Level: state.MasterLevel},
		Source: channelchat.SourceObservation{Identity: fmt.Sprintf("adventure-defense-room:%d", room.ID), ContentRevisionID: room.NoticeVersion},
	}, nil
}

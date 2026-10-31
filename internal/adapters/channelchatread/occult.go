package channelchatread

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/application/channelchat"
	app "gxb.local/backend/v2/internal/application/occult"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// OccultRoomReader reads the canonical shared room behind a structured
// occult-invitation chat: only an open team room can be shared.
type OccultRoomReader struct {
	Store sharedroomstore.Store
}

func (r OccultRoomReader) ReadOccultTx(c context.Context, t tx.Tx, _ ar.Admission, _ time.Time, selection channelchat.RoomSelection) (channelchat.Owned[channelchat.Occult], error) {
	if t == nil || selection.RoomID <= 0 {
		return channelchat.Owned[channelchat.Occult]{}, channelchat.ErrInvalidStructured
	}
	room, found, err := r.Store.ReadRoomTx(c, t, selection.RoomID)
	if err != nil {
		return channelchat.Owned[channelchat.Occult]{}, err
	}
	if !found || room.Family != app.RoomFamily || room.Slot != app.RoomSlot || room.Status != sharedroom.StatusOpen {
		return channelchat.Owned[channelchat.Occult]{}, channelchat.ErrInvalidStructured
	}
	state, err := d.LoadRunState(room.Payload)
	if err != nil || state.CampaignType != d.MultiCampaignType {
		return channelchat.Owned[channelchat.Occult]{}, channelchat.ErrInvalidStructured
	}
	// shortcut: force is 0 because the player directory carries no battle power.
	return channelchat.Owned[channelchat.Occult]{
		Value:  channelchat.Occult{RoomID: room.ID, ChapterID: state.ChapterID},
		Source: channelchat.SourceObservation{Identity: fmt.Sprintf("occult-room:%d", room.ID), ContentRevisionID: room.NoticeVersion},
	}, nil
}

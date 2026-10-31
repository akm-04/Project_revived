package channelchatread

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/application/channelchat"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// IllusionRoomReader reads the canonical shared room behind a structured
// illusion-invitation chat.
type IllusionRoomReader struct {
	Store   sharedroomstore.Store
	Content contentstore.Store
}

func (r IllusionRoomReader) ReadIllusionTx(c context.Context, t tx.Tx, _ ar.Admission, _ time.Time, selection channelchat.RoomSelection) (channelchat.Owned[channelchat.Invitation], error) {
	if t == nil || selection.RoomID <= 0 {
		return channelchat.Owned[channelchat.Invitation]{}, channelchat.ErrInvalidStructured
	}
	room, found, err := r.Store.ReadRoomTx(c, t, selection.RoomID)
	if err != nil {
		return channelchat.Owned[channelchat.Invitation]{}, err
	}
	if !found || room.Family != "illusion" || room.Slot != 1 || room.Status != sharedroom.StatusOpen {
		return channelchat.Owned[channelchat.Invitation]{}, channelchat.ErrInvalidStructured
	}
	state, err := d.LoadRoomState(room.Payload)
	if err != nil {
		return channelchat.Owned[channelchat.Invitation]{}, channelchat.ErrInvalidStructured
	}
	revision, err := r.Content.ActiveRevision(c, t)
	if err != nil {
		return channelchat.Owned[channelchat.Invitation]{}, err
	}
	catalog, err := r.Content.IllusionCatalogTx(c, t, revision)
	if err != nil {
		return channelchat.Owned[channelchat.Invitation]{}, err
	}
	campaign, found := catalog.Campaign(state.ParadiseID)
	if !found {
		return channelchat.Owned[channelchat.Invitation]{}, channelchat.ErrInvalidStructured
	}
	return channelchat.Owned[channelchat.Invitation]{
		Value:  channelchat.Invitation{RoomID: room.ID, BossName: campaign.Name, Level: state.MasterLevel},
		Source: channelchat.SourceObservation{Identity: fmt.Sprintf("illusion-room:%d", room.ID), ContentRevisionID: room.NoticeVersion},
	}, nil
}

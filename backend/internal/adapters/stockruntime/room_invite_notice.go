package stockruntime

import (
	"context"
	"errors"
	"strconv"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
)

// RoomInviteNoticeListHandler reloads the friend notice list the way a gift
// reload does: MIDForceReload with player_id 0 and friend_notice 1.
type RoomInviteNoticeListHandler struct{ Delivery RoomDelivery }

func (h RoomInviteNoticeListHandler) NoticeListChanged(c context.Context, recipient identity.PlayerID) error {
	if h.Delivery.Registry == nil || h.Delivery.Authority == nil || h.Delivery.Time == nil || !recipient.Valid() {
		return errors.New("room invite notice list unavailable")
	}
	frame := &amf3.Object{Properties: []amf3.Property{{Name: "player_id", Value: int64(0)}, {Name: "friend_notice", Value: int64(1)}}}
	return h.Delivery.Deliver(c, recipient, mids.MIDForceReload, frame)
}

func (h RoomInviteNoticeListHandler) ReloadAndDeliver(c context.Context, reference string) error {
	recipient, err := strconv.ParseInt(reference, 10, 64)
	if err != nil || recipient <= 0 {
		return errors.New("invalid room invite notice list reference")
	}
	return h.NoticeListChanged(c, identity.PlayerID(recipient))
}

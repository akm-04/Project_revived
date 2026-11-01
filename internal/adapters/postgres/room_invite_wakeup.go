//go:build postgres

package postgres

import (
	"context"
	"strconv"
	"time"

	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/application/roominvite"
	"gxb.local/backend/v2/internal/domain/identity"
)

// RoomInviteNoticeListEmitter wakes the realtime friend-notice reload after the
// materialize transaction committed. Delivery failure never repeats state.
type RoomInviteNoticeListEmitter struct {
	Pool    *Pool
	OnError func(error)
}

func (e RoomInviteNoticeListEmitter) NoticeListChanged(c context.Context, recipient identity.PlayerID) {
	if e.Pool == nil || !recipient.Valid() {
		return
	}
	ctx, cancel := context.WithTimeout(c, 2*time.Second)
	defer cancel()
	err := EmitRealtimeWakeup(ctx, socialWakeupExecer{e.Pool}, wake.Envelope{Version: wake.EnvelopeVersion, Route: roominvite.NoticeListRoute, Ref: strconv.FormatInt(int64(recipient), 10)})
	if err != nil && e.OnError != nil {
		e.OnError(err)
	}
}

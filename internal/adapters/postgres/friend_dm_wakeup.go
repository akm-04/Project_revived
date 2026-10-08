//go:build postgres

package postgres

import (
	"context"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	"time"
)

type FriendDMWakeupEmitter struct {
	Pool    *Pool
	OnError func(error)
}

func (s FriendDMWakeupEmitter) EmitFriendDM(c context.Context, o dm.Occurrence) {
	if s.Pool == nil || o.Validate() != nil {
		return
	}
	raw, e := (dm.Reference{Recipient: o.Recipient, OccurrenceID: o.ID, Version: 1}).Encode()
	if e == nil {
		bounded, cancel := context.WithTimeout(c, 2*time.Second)
		defer cancel()
		e = EmitRealtimeWakeup(bounded, socialWakeupExecer{s.Pool}, wake.Envelope{Version: 1, Route: dm.WakeupRoute, Ref: raw})
	}
	if e != nil && s.OnError != nil {
		s.OnError(e)
	}
}

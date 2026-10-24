//go:build postgres

package postgres

import (
	"context"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	"time"
)

type GeneralDMWakeupEmitter struct {
	Pool    *Pool
	OnError func(error)
}

func (s GeneralDMWakeupEmitter) EmitGeneralDM(c context.Context, i dm.Intent) {
	if s.Pool == nil || i.Validate() != nil || i.Status.Terminal() {
		return
	}
	raw, e := (dm.Reference{ID: i.ID, Version: i.StateVersion}).Encode()
	if e == nil {
		bounded, cancel := context.WithTimeout(c, time.Second)
		defer cancel()
		e = EmitRealtimeWakeup(bounded, socialWakeupExecer{s.Pool}, wake.Envelope{Version: 1, Route: dm.WakeupRoute, Ref: raw})
	}
	if e != nil && s.OnError != nil {
		s.OnError(e)
	}
}

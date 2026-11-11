package postgres

import (
	"context"
	"log"
	"strconv"

	"gxb.local/backend/v2/internal/adapters/postgres/broadcaststore"
	app "gxb.local/backend/v2/internal/application/broadcast"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BroadcastEmitter queues one lobby announcement through the caller's
// transaction, so the push exists only after the gameplay change commits.
// Announcements are display-only (D1): a message that fails its own validation
// is dropped, journalled and counted, while a database or wakeup error stays
// fatal so the gameplay rolls back.
type BroadcastEmitter struct {
	Store   broadcaststore.Store
	Metrics observability.Metrics
}

func (e BroadcastEmitter) EmitTx(ctx context.Context, t tx.Tx, m app.Message) error {
	if err := m.Validate(); err != nil {
		log.Printf("broadcast: dropped invalid announcement msg_type=%d: %v", m.MsgType, err)
		observability.CountDropped(e.Metrics, "broadcast_announcement_dropped", "broadcast")
		return nil
	}
	id, err := e.Store.InsertTx(ctx, t, m)
	if err != nil {
		return err
	}
	return EmitRealtimeWakeup(ctx, t, wake.Envelope{Version: wake.EnvelopeVersion, Route: app.Route, Ref: strconv.FormatInt(id, 10)})
}

var _ app.Emitter = BroadcastEmitter{}

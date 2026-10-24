package stockruntime

import (
	"context"
	"encoding/json"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Reusable typed adapter boundary. These MIDs are deliberately not registered
// before the I7B-6 full rich-provider/consumer qualification gate.
func DecodeShowcaseAssignment(params map[string]any) (app.Selection, error) {
	if len(params) != 1 {
		return app.Selection{}, app.ErrSelection
	}
	return app.ParseSelection(params["ids"])
}
func DecodeShowcaseDetail(params map[string]any) (identity.PlayerID, int, error) {
	if len(params) != 2 {
		return 0, 0, app.ErrSelection
	}
	n, ok := params["to_player_id"].(json.Number)
	if !ok {
		return 0, 0, app.ErrSelection
	}
	// Player ID belongs to the read target; assignment never accepts a target PID.
	id, e := finitejson.ExactInteger(n)
	if e != nil || id <= 0 {
		return 0, 0, app.ErrSelection
	}
	i, e := app.ParseShowcaseIndex(params["index"])
	return identity.PlayerID(id), i, e
}

// The assignment callback executes in its exact caller transaction, before any
// root/selection/receipt write. A missing rich composer fails closed, including
// empty requests; it cannot be treated as a stock success response.
func RequireShowcaseRecords(builder app.ShowcaseRecordBuilder, pid identity.PlayerID) func(context.Context, gen.TimedScope, app.Selection, string, time.Time) error {
	return func(c context.Context, sc gen.TimedScope, s app.Selection, rev string, at time.Time) error {
		_, e := app.SlotRecordsTx(c, tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, app.ShowcaseSnapshot{PlayerID: pid, Selection: s, ContentRevision: rev, ObservedAt: at}, builder)
		return e
	}
}

package commerceprivilege

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// BootstrapProjection consumes only canonical privilege state; missing legacy
// state preserves the prior inactive bootstrap, never a qualified4Aabsence.
type BootstrapProjection struct{ Provider Provider }

func (BootstrapProjection) Name() string     { return "commerce.i7c4a.privilege" }
func (BootstrapProjection) Claims() []string { return []string{"17.vip", "17.charge"} }
func (p BootstrapProjection) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	snap, ok, e := p.Provider.snapshot(c, q, a.PlayerID, "", at)
	if e != nil {
		return e
	}
	if !ok {
		return nil
	}
	out, ok := detail["17"].(map[string]any)
	if !ok {
		return errors.New("privilege MID17 projection unavailable")
	}
	out["vip"] = snap.State.VIPLevel
	out["charge"] = snap.State.Charge
	return nil
}

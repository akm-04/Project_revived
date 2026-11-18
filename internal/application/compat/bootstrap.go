package compat

import (
	"context"
	"time"

	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BootstrapProjection overlays the two MID 1 compat fields (I9-11D C4). It
// claims exactly the fields it writes; the frozen lobby baseline serves 0 and
// an empty array until the same read function replaces them.
type BootstrapProjection struct {
	Store Store
}

func (BootstrapProjection) Name() string { return "compat.preferences" }

func (BootstrapProjection) Claims() []string {
	return []string{"17.first_main_touch", "17.message_pushes"}
}

func (p BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	if p.Store == nil {
		return d.ErrUnavailable
	}
	preferences, _, err := p.Store.ReadTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	record, ok := detail["17"].(map[string]any)
	if !ok {
		return d.ErrUnavailable
	}
	record["first_main_touch"] = preferences.FirstMainTouch
	record["message_pushes"] = preferences.Enabled()
	return nil
}

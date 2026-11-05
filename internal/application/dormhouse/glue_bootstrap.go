package dormhouse

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/bootstrap"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type GlueBootstrap struct{ Owner GluePurchaseOwner }

var _ bootstrap.MID1DetailContributor = GlueBootstrap{}

func (GlueBootstrap) Name() string     { return "i9-10c.glue-purchases" }
func (GlueBootstrap) Claims() []string { return []string{"17.buy_glue_times"} }
func (projection GlueBootstrap) OverlayMID1(ctx context.Context, query tx.Queryer, actor identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	if projection.Owner == nil {
		return ErrUnavailable
	}
	core, valid := detail["17"].(map[string]any)
	if !valid {
		return ErrProof
	}
	stored, exists, err := projection.Owner.ReadGluePurchasesTx(ctx, query, actor.PlayerID)
	if err != nil {
		return err
	}
	var previous *dorm.GluePurchases
	if exists {
		previous = &stored
	}
	count, err := dorm.EffectiveGluePurchaseCount(previous, actor.PlayerID, modes.Day(at), at)
	if err != nil {
		return err
	}
	core["buy_glue_times"] = count
	return nil
}

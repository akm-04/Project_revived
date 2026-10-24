package conquerstore

import (
	"context"
	"errors"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type CatalogReader interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ConquerCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

// BootstrapProjection overlays MID17 conquer_lev/conquer_loop_id/conquer_region
// from the owner's known facts; a missing or UNKNOWN_LEGACY row keeps the stock defaults.
type BootstrapProjection struct{ Content CatalogReader }

func (BootstrapProjection) Name() string { return "i7c5e.conquer-progress" }
func (BootstrapProjection) Claims() []string {
	return []string{"17.conquer_lev", "17.conquer_loop_id", "17.conquer_region"}
}

func (p BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	mid17, ok := detail["17"].(map[string]any)
	if q == nil || p.Content == nil || !ok {
		return errors.New("conquer bootstrap: invalid projection input")
	}
	facts, err := (Store{}).ReadFactsTx(ctx, q, actor.PlayerID)
	if errors.Is(err, d.ErrUnavailable) {
		return nil
	}
	if err != nil {
		return err
	}
	if !facts.Known() {
		return nil
	}
	revision, err := p.Content.ActiveRevision(ctx, q)
	if err != nil {
		return err
	}
	catalog, err := p.Content.ConquerCatalogTx(ctx, q, revision)
	if err != nil {
		return err
	}
	if err = facts.Validate(catalog); err != nil {
		return err
	}
	progress := *facts.Payload.Progress
	region, err := catalog.Region(progress)
	if err != nil {
		return err
	}
	mid17["conquer_lev"], mid17["conquer_loop_id"], mid17["conquer_region"] = progress.Level, progress.Loop, region
	return nil
}

var _ appboot.MID1DetailContributor = BootstrapProjection{}

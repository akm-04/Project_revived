package bookstore

import (
	"context"
	"gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type ActiveReader interface {
	BookInputsActiveTx(context.Context, tx.Queryer) (string, bool, error)
}
type BootstrapProjection struct {
	Service bookskill.Service
	Content ActiveReader
}

func (BootstrapProjection) Name() string     { return "i7c2d.bookshelf-cabinet" }
func (BootstrapProjection) Claims() []string { return []string{"1056"} }
func (b BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	rev, on, e := b.Content.BookInputsActiveTx(ctx, q)
	if e != nil || !on {
		return e
	}
	v, e := b.Service.BuildingsWireTx(ctx, q, bookskill.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: at})
	if e != nil {
		return e
	}
	detail["1056"] = v
	return nil
}

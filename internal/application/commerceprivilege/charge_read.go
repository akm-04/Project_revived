package commerceprivilege

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
)

// Query answers stock MID 354 (C10): every catalog product with its purchase
// history, no locks. VipRechargeWindow builds its whole list from this array,
// so an unbought product is a zero-count row, not an omitted one.
func (s Charge) Query(c context.Context, a identity.ActorContext, at time.Time) (map[string]any, error) {
	if s.Fresh == nil || s.Store == nil || s.Content == nil || !a.PlayerID.Valid() || at.IsZero() {
		return nil, d.ErrUnavailable
	}
	revision, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return nil, e
	}
	catalog, e := s.Content.ChargeCatalogTx(c, s.Fresh, revision)
	if e != nil {
		return nil, e
	}
	purchases, e := s.Store.ReadPurchasesTx(c, s.Fresh, a.PlayerID)
	if e != nil {
		return nil, e
	}
	tuning, tuned, e := s.Store.ChargeTuningTx(c, s.Fresh)
	if e != nil {
		return nil, e
	}
	history := make(map[int64]d.Purchase, len(purchases))
	for _, purchase := range purchases {
		history[purchase.ChargeID] = purchase
	}
	charges := make([]d.Purchase, 0, len(catalog.Products))
	for _, product := range catalog.Products {
		if tuned && tuning.Validate() == nil && tuning.ProductOff(product.ID) {
			continue
		}
		row := history[product.ID]
		row.ChargeID = product.ID
		charges = append(charges, row)
	}
	return map[string]any{"charges": charges, "giftbags": []any{}, "server_time": at.UTC().Unix()}, nil
}

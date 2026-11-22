package commerceprivilege

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Query answers stock MID 354 (C10): every catalog product with its purchase
// history, no locks. VipRechargeWindow builds its whole list from this array,
// so an unbought product is a zero-count row, not an omitted one.
func (s Charge) Query(c context.Context, a identity.ActorContext, at time.Time, op operation.Context) (map[string]any, error) {
	if s.Fresh == nil || s.Store == nil || s.Content == nil || !a.PlayerID.Valid() || at.IsZero() {
		return nil, d.ErrUnavailable
	}
	var body map[string]any
	_, err := s.Timed.Runner.Run(c, op, readProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		revision, e := s.Content.ActiveRevision(c, sc.Tx)
		if e != nil {
			return e
		}
		catalog, e := s.Content.ChargeCatalogTx(c, sc.Tx, revision)
		if e != nil {
			return e
		}
		purchases, e := s.Store.ReadPurchasesTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		tuning, tuned, e := s.Store.ChargeTuningTx(c, sc.Tx)
		if e != nil {
			return e
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
		body = map[string]any{"charges": charges, "giftbags": []any{}, "server_time": at.UTC().Unix()}
		return nil
	})
	return body, err
}

func readProfile() tx.Profile {
	return tx.Profile{Name: "charge-read", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}

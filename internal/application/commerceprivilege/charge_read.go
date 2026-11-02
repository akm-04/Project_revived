package commerceprivilege

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
)

// Query answers stock MID 354 (C10): the player's purchase history, no locks.
func (s Charge) Query(c context.Context, a identity.ActorContext, at time.Time) (map[string]any, error) {
	if s.Fresh == nil || s.Store == nil || !a.PlayerID.Valid() || at.IsZero() {
		return nil, d.ErrUnavailable
	}
	purchases, e := s.Store.ReadPurchasesTx(c, s.Fresh, a.PlayerID)
	if e != nil {
		return nil, e
	}
	if purchases == nil {
		purchases = []d.Purchase{}
	}
	return map[string]any{"charges": purchases, "giftbags": []any{}, "server_time": at.UTC().Unix()}, nil
}

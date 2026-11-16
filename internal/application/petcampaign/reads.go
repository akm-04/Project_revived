package petcampaign

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MaxFloorTx is 100005's owner fact: the highest Sky Tower floor reached.
func (s Mode) MaxFloorTx(c context.Context, q tx.Queryer, p identity.PlayerID) (int64, error) {
	if s.Store == nil {
		return 0, d.ErrUnavailable
	}
	state, found, e := s.Store.ReadTx(c, q, p)
	if e != nil {
		return 0, e
	}
	if !found {
		return 0, nil
	}
	return state.Max, nil
}

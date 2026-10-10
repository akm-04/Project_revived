package socialrelationstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) InsertPreparedRootTx(c context.Context, t tx.Tx, r socialrelation.Root) error {
	if t == nil || r.Validate() != nil || r.StateVersion != 1 || !r.CreatedAt.Equal(r.UpdatedAt) {
		return socialrelation.ErrInvalidState
	}
	return effect(t, c, `INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)`, int64(r.PlayerID), r.CreatedAt)
}

var _ socialrelation.PreparedRootStore = Store{}

func (Store) ReadPreparedRootTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (socialrelation.Root, bool, error) {
	if q == nil || !pid.Valid() {
		return socialrelation.Root{}, false, socialrelation.ErrInvalidState
	}
	r := socialrelation.Root{PlayerID: pid}
	e := q.QueryRow(c, `SELECT state_version,created_at,updated_at FROM player_social_roots WHERE player_id=$1`, int64(pid)).Scan(&r.StateVersion, &r.CreatedAt, &r.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return socialrelation.Root{}, false, nil
	}
	if e != nil {
		return r, false, e
	}
	r.CreatedAt = r.CreatedAt.UTC()
	r.UpdatedAt = r.UpdatedAt.UTC()
	return r, true, r.Validate()
}

package socialrelationstore

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadRootsTx(c context.Context, q tx.Queryer, pids []identity.PlayerID) (map[identity.PlayerID]socialrelation.Root, error) {
	out := map[identity.PlayerID]socialrelation.Root{}
	for _, pid := range pids {
		var r socialrelation.Root
		var id int64
		e := q.QueryRow(c, `SELECT player_id,state_version,created_at,updated_at FROM player_social_roots WHERE player_id=$1`, int64(pid)).Scan(&id, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt)
		if e != nil {
			return nil, e
		}
		r.PlayerID = identity.PlayerID(id)
		if r.Validate() != nil || r.PlayerID != pid {
			return nil, socialrelation.ErrInvalidState
		}
		out[pid] = r
	}
	return out, nil
}

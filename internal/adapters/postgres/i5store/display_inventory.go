package i5store

import (
	"context"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Empty stacks are qualified only with a canonical I5 owner. AcquiredAt is never
// a cosmetic startTime. The population retains all per-stack CAS versions.
func (s Store) ReadDisplayInventoryTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (app.InventoryPopulation, error) {
	out := app.InventoryPopulation{PlayerID: pid}
	if q == nil || !pid.Valid() {
		return out, app.ErrUnavailable
	}
	if e := q.QueryRow(c, `SELECT state_version,created_at FROM player_economy_owners WHERE player_id=$1`, int64(pid)).Scan(&out.RootVersion, &out.CreatedAt); e != nil {
		return out, e
	}
	var e error
	out.Stacks, e = s.ListStacksTx(c, q, pid)
	return out, e
}

var _ app.InventoryReader = Store{}

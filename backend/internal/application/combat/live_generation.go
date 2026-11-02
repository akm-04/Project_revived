package combat

import (
	"context"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// LiveGenerationTx lets the owning mode admit a mid-battle story entitlement
// without attesting or terminating the battle. Caller holds its mode row.
func (s Service) LiveGenerationTx(c context.Context, t tx.Tx, loc d.Locator, pid identity.PlayerID, generation string, at time.Time) (bool, error) {
	if err := s.Store.LockLocatorTx(c, t, loc); err != nil {
		return false, err
	}
	a, found, err := s.Store.FindUnresolvedTx(c, t, loc)
	return found && a.ActorPlayer == int64(pid) && a.GenerationRef == generation && a.State == d.Staged && at.Before(a.ResultDeadline), err
}

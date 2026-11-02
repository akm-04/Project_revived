package combat

import (
	"context"
	"encoding/json"

	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BorrowedTx reports whether the locator's open attempt froze a BORROWED
// attacker, read from the snapshot rather than any client field (C13).
func (s Service) BorrowedTx(ctx context.Context, t tx.Tx, locator d.Locator) (bool, error) {
	attempt, found, err := s.Store.FindUnresolvedTx(ctx, t, locator)
	if err != nil {
		return false, err
	}
	if !found {
		return false, nil
	}
	raw, err := s.Store.ReadSnapshotTx(ctx, t, attempt.SnapshotHash)
	if err != nil {
		return false, err
	}
	var snapshot d.Snapshot
	if err := json.Unmarshal(raw, &snapshot); err != nil {
		return false, err
	}
	for _, side := range [][]d.Actor{snapshot.Battle.TeamA, snapshot.Battle.PetsA} {
		for _, actor := range side {
			if actor.Origin == d.Borrowed {
				return true, nil
			}
		}
	}
	return false, nil
}

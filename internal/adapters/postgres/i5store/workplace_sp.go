package i5store

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// The economy owner root serializes first access, including absent temporal rows.
func (Store) InsertWorkplaceSPTx(ctx context.Context, t tx.Tx, state economy.TemporalState) error {
	if t == nil || state.ResourceKey != i5.WorkplaceSPKey || state.StateVersion != 1 || state.ContentRevision == "" || state.PolicyVersion != state.ContentRevision {
		return errors.New("invalid workplace SP initialization")
	}
	if err := state.Validate(); err != nil {
		return err
	}
	_, err := t.Exec(ctx, insertBootstrapTemporal, int64(state.PlayerID), state.ResourceKey, state.StoredAmount, state.RegenAnchorAt, state.PolicyVersion, state.ContentRevision, state.UpdatedAt.UTC())
	return err
}

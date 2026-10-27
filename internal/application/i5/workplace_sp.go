package i5

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const WorkplaceSPKey = "workplace_sp"

type workplaceSPInitializer interface {
	InsertWorkplaceSPTx(context.Context, tx.Tx, economy.TemporalState) error
}

// WorkplaceSPTx lazily initializes fresh and existing players through the same
// owner. Initial full stamina is private policy; it never resets an existing row.
func (s Service) WorkplaceSPTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, op operation.Context) (economy.MaterializedTemporal, error) {
	if s.Store == nil || s.Content == nil || t == nil || !pid.Valid() || op.StartedAt.IsZero() {
		return economy.MaterializedTemporal{}, errors.New("invalid workplace SP access")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return economy.MaterializedTemporal{}, err
	}
	if err = s.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return economy.MaterializedTemporal{}, err
	}
	progression, err := s.Store.LockProgressionTx(ctx, t, pid)
	if err != nil {
		return economy.MaterializedTemporal{}, err
	}
	now := op.StartedAt.UTC()
	policy, err := s.temporalPolicyAtTx(ctx, t, pid, WorkplaceSPKey, revision, progression.Level, now)
	if err != nil {
		return economy.MaterializedTemporal{}, err
	}
	state, exists, err := s.Store.LockTemporalTx(ctx, t, pid, WorkplaceSPKey)
	if err != nil {
		return economy.MaterializedTemporal{}, err
	}
	if !exists {
		initializer, ok := s.Store.(workplaceSPInitializer)
		if !ok {
			return economy.MaterializedTemporal{}, errors.New("workplace SP initialization unavailable")
		}
		state = economy.TemporalState{PlayerID: pid, ResourceKey: WorkplaceSPKey, StoredAmount: policy.NaturalCap, PolicyVersion: revision, ContentRevision: revision, StateVersion: 1, UpdatedAt: now}
		if err = initializer.InsertWorkplaceSPTx(ctx, t, state); err != nil {
			return economy.MaterializedTemporal{}, err
		}
	} else if state.ContentRevision != revision {
		return economy.MaterializedTemporal{}, ErrContentRevisionConflict
	}
	materialized, err := state.Materialize(now, policy)
	if err != nil {
		return economy.MaterializedTemporal{}, err
	}
	if materialized.State.StateVersion != state.StateVersion {
		if err = s.Store.SaveTemporalTx(ctx, t, materialized.State); err != nil {
			return economy.MaterializedTemporal{}, err
		}
	}
	return materialized, nil
}

package i5

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TxTemporalDebiter spends a regenerating resource (campaign energy) inside the caller's transaction (I9_MODE_FRAMEWORK_V1 F9).
// The caller owns the transaction and the semantic receipt. TemporalBalanceTx is the admission preview (F6): it locks and
// materializes the balance at the operation instant without changing it.
type TxTemporalDebiter interface {
	DebitTemporalTx(context.Context, tx.Tx, identity.PlayerID, string, int64, operation.Context) (economy.TemporalState, error)
	TemporalBalanceTx(context.Context, tx.Tx, identity.PlayerID, string, operation.Context) (int64, error)
}

func (s Service) DebitTemporalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, amount int64, op operation.Context) (economy.TemporalState, error) {
	if amount <= 0 {
		return economy.TemporalState{}, errors.New("invalid temporal debit")
	}
	if key != EnergyKey {
		return s.debitTemporalTx(ctx, t, pid, key, amount, op)
	}
	// Occult tickets accrue from every energy debit and only from here; the
	// scalar rows (720) lock before the energy row (721).
	ledger, err := s.lockOccultLedgerTx(ctx, t, pid, op)
	if err != nil {
		return economy.TemporalState{}, err
	}
	next, err := s.debitTemporalTx(ctx, t, pid, key, amount, op)
	if err != nil {
		return economy.TemporalState{}, err
	}
	if err := s.saveOccultLedgerTx(ctx, t, ledger, amount, op.StartedAt.UTC()); err != nil {
		return economy.TemporalState{}, err
	}
	// Rank 723: only this seam credits guild activity (I9_GUILD_ACTIVITY_V1 C1, C2).
	return next, s.Store.AppendGuildActivityDayTx(ctx, t, pid, op.StartedAt.UTC(), amount)
}

func (s Service) debitTemporalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, amount int64, op operation.Context) (economy.TemporalState, error) {
	state, policy, now, err := s.lockTemporalTx(ctx, t, pid, key, op)
	if err != nil {
		return economy.TemporalState{}, err
	}
	next, err := state.Debit(amount, now, policy)
	if err != nil {
		return economy.TemporalState{}, err
	}
	return next, s.Store.SaveTemporalTx(ctx, t, next)
}

func (s Service) TemporalBalanceTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, op operation.Context) (int64, error) {
	state, policy, now, err := s.lockTemporalTx(ctx, t, pid, key, op)
	if err != nil {
		return 0, err
	}
	materialized, err := state.Materialize(now, policy)
	return materialized.Amount, err
}

func (s Service) lockTemporalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, op operation.Context) (economy.TemporalState, economy.TemporalPolicy, time.Time, error) {
	if s.Store == nil || s.Content == nil || t == nil || !pid.Valid() || key == "" || op.StartedAt.IsZero() {
		return economy.TemporalState{}, economy.TemporalPolicy{}, time.Time{}, errors.New("invalid temporal access")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return economy.TemporalState{}, economy.TemporalPolicy{}, time.Time{}, err
	}
	now := op.StartedAt.UTC()
	// Frozen R5 ordering: owner 700, progression 710, temporal 721.
	if err := s.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return economy.TemporalState{}, economy.TemporalPolicy{}, now, err
	}
	progression, err := s.Store.LockProgressionTx(ctx, t, pid)
	if err != nil {
		return economy.TemporalState{}, economy.TemporalPolicy{}, now, err
	}
	state, exists, err := s.Store.LockTemporalTx(ctx, t, pid, key)
	if err != nil {
		return economy.TemporalState{}, economy.TemporalPolicy{}, now, err
	}
	if !exists {
		return economy.TemporalState{}, economy.TemporalPolicy{}, now, economy.ErrUnknownResource
	}
	if state.ContentRevision != revision {
		return economy.TemporalState{}, economy.TemporalPolicy{}, now, ErrContentRevisionConflict
	}
	policy, err := s.temporalPolicyAtTx(ctx, t, pid, key, revision, progression.Level, now)
	return state, policy, now, err
}

var _ TxTemporalDebiter = Service{}

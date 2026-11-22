package i5

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const GlueResourceKey = "glue"

type ScalarDailyFloorPolicySource interface {
	ScalarDailyFloorMinimumTx(context.Context, tx.Queryer) (int64, bool, error)
}
type ScalarDailyFloorReader interface {
	ReadScalarDailyFloorTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarDailyFloor, bool, error)
}
type scalarDailyFloorWriter interface {
	ScalarDailyFloorReader
	SaveScalarDailyFloorTx(context.Context, tx.Tx, economy.ScalarDailyFloor, int64) error
	SaveScalarTx(context.Context, tx.Tx, economy.ScalarBalance, bool) error
}

func dailyFloorMinimumTx(ctx context.Context, query tx.Queryer, source any, key string) (*int64, error) {
	if key != GlueResourceKey {
		return nil, nil
	}
	provider, qualified := source.(ScalarDailyFloorPolicySource)
	if !qualified {
		return nil, errors.New("I5 glue floor policy provider unavailable")
	}
	minimum, enabled, err := provider.ScalarDailyFloorMinimumTx(ctx, query)
	if err != nil {
		return nil, err
	}
	if !enabled {
		return nil, nil
	}
	if minimum < 0 {
		return nil, economy.ErrInvalidDailyFloor
	}
	return &minimum, nil
}
func effectiveDailyFloorTx(ctx context.Context, query tx.Queryer, source any, balance economy.ScalarBalance, minimum *int64, at time.Time) (economy.ScalarBalance, error) {
	if minimum == nil {
		return balance, nil
	}
	store, qualified := source.(ScalarDailyFloorReader)
	if !qualified {
		return economy.ScalarBalance{}, errors.New("I5 scalar floor reader unavailable")
	}
	anchor, exists, err := store.ReadScalarDailyFloorTx(ctx, query, balance.PlayerID, balance.ResourceKey)
	if err != nil {
		return economy.ScalarBalance{}, err
	}
	var previous *economy.ScalarDailyFloor
	observedAt := generation.EffectiveObservation(at, balance.UpdatedAt)
	if exists {
		previous = &anchor
		observedAt = generation.EffectiveObservation(observedAt, anchor.UpdatedAt)
	}
	// K4: the game-day window uses the raw decision time; only the guard and the
	// written timestamp move to the effective observation (K2/K3).
	plan, err := balance.PlanDailyFloor(previous, modes.Day(at), *minimum, observedAt)
	return plan.Balance, err
}

type preparedScalarDailyFloor struct {
	Plan            economy.DailyFloorPlan
	BalanceExisted  bool
	PreviousVersion int64
}

func prepareDailyFloorTx(ctx context.Context, query tx.Queryer, source any, balance economy.ScalarBalance, exists bool, minimum *int64, at time.Time) (*preparedScalarDailyFloor, error) {
	if minimum == nil {
		return nil, nil
	}
	store, qualified := source.(ScalarDailyFloorReader)
	if !qualified {
		return nil, errors.New("I5 scalar floor reader unavailable")
	}
	anchor, anchored, err := store.ReadScalarDailyFloorTx(ctx, query, balance.PlayerID, balance.ResourceKey)
	if err != nil {
		return nil, err
	}
	var previous *economy.ScalarDailyFloor
	previousVersion := int64(0)
	observedAt := generation.EffectiveObservation(at, balance.UpdatedAt)
	if anchored {
		previous = &anchor
		previousVersion = anchor.StateVersion
		observedAt = generation.EffectiveObservation(observedAt, anchor.UpdatedAt)
	}
	plan, err := balance.PlanDailyFloor(previous, modes.Day(at), *minimum, observedAt)
	if err != nil {
		return nil, err
	}
	return &preparedScalarDailyFloor{Plan: plan, BalanceExisted: exists, PreviousVersion: previousVersion}, nil
}
func applyDailyFloorTx(ctx context.Context, transaction tx.Tx, source any, prepared preparedScalarDailyFloor) error {
	if !prepared.Plan.Changed {
		return nil
	}
	store, qualified := source.(scalarDailyFloorWriter)
	if !qualified {
		return errors.New("I5 scalar floor writer unavailable")
	}
	if !prepared.BalanceExisted || prepared.Plan.Credit > 0 {
		if err := store.SaveScalarTx(ctx, transaction, prepared.Plan.Balance, prepared.BalanceExisted); err != nil {
			return err
		}
	}
	return store.SaveScalarDailyFloorTx(ctx, transaction, prepared.Plan.Anchor, prepared.PreviousVersion)
}

// The anchor shares the existing economy/scalar lock identity. Preparation is
// read-only so MaterialExchange can finish closing its plan before any write.
func settleDailyFloorTx(ctx context.Context, transaction tx.Tx, source any, balance economy.ScalarBalance, exists bool, minimum *int64, at time.Time) (economy.ScalarBalance, bool, error) {
	prepared, err := prepareDailyFloorTx(ctx, transaction, source, balance, exists, minimum, at)
	if err != nil {
		return economy.ScalarBalance{}, false, err
	}
	if prepared == nil {
		return balance, exists, nil
	}
	if err = applyDailyFloorTx(ctx, transaction, source, *prepared); err != nil {
		return economy.ScalarBalance{}, false, err
	}
	return prepared.Plan.Balance, exists || prepared.Plan.Changed, nil
}

func EffectiveScalarTx(ctx context.Context, query tx.Queryer, store ScalarProjectionStore, source any, player identity.PlayerID, key string, at time.Time) (int64, error) {
	if query == nil || store == nil || !player.Valid() || key == "" || at.IsZero() {
		return 0, economy.ErrInvalidDailyFloor
	}
	minimum, err := dailyFloorMinimumTx(ctx, query, source, key)
	if err != nil {
		return 0, err
	}
	balance, exists, err := store.ReadScalarTx(ctx, query, player, key)
	if err != nil {
		return 0, err
	}
	if !exists {
		balance = economy.ScalarBalance{PlayerID: player, ResourceKey: key, StateVersion: 1, UpdatedAt: at}
	}
	effective, err := effectiveDailyFloorTx(ctx, query, store, balance, minimum, at)
	if err != nil {
		return 0, err
	}
	return effective.Amount, nil
}

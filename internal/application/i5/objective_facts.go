package i5

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// OpenObjectiveLocker locks a player's incomplete, unclaimed objective rows.
type OpenObjectiveLocker interface {
	LockOpenObjectivesTx(context.Context, tx.Tx, identity.PlayerID) ([]objective.Instance, []ObjectiveDefinition, error)
}

// FactObserver converts recorded facts into a family's own side state. It runs
// in the same transaction, after objectives, and sees the whole fact batch.
type FactObserver interface {
	ObserveTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

// ObjectiveFacts is the objective fact port (I9_MODE_FRAMEWORK_V1 F11, I9_MODE_FOUNDATION_V1 MF3): a mode owner reports what
// it settled inside its own transaction, and every open objective accepting the fact kind advances once per fact identity.
type ObjectiveFacts struct {
	Owner    Service
	Open     OpenObjectiveLocker
	Observer FactObserver
}

func (f ObjectiveFacts) RecordTx(ctx context.Context, t tx.Tx, op operation.Context, facts ...objective.Fact) error {
	if f.Open == nil || f.Owner.Store == nil || f.Owner.Receipts == nil {
		return errors.New("objective fact port unavailable")
	}
	for _, fact := range facts {
		if err := fact.Validate(); err != nil {
			return err
		}
		if f.Owner.Missions != nil {
			if err := f.recordMission(ctx, t, op, fact); err != nil {
				return err
			}
		}
		if err := f.record(ctx, t, op, fact); err != nil {
			return err
		}
	}
	if f.Observer == nil {
		return nil
	}
	return f.Observer.ObserveTx(ctx, t, op, facts...)
}

func (f ObjectiveFacts) record(ctx context.Context, t tx.Tx, op operation.Context, fact objective.Fact) error {
	instances, stored, err := f.Open.LockOpenObjectivesTx(ctx, t, fact.PlayerID)
	if err != nil {
		return err
	}
	for index, instance := range instances {
		if instance.DefinitionRevision == "I9_MISSIONS_V1" {
			continue
		}
		definition, err := f.Owner.resolveObjectiveDefinitionTx(ctx, t, instance, stored[index])
		if err != nil {
			return err
		}
		if definition.Definition.AcceptedFactKind != fact.Kind {
			continue
		}
		if _, _, err := f.Owner.ApplyObjectiveFactTx(ctx, t, definition, instance, fact, op); err != nil {
			return err
		}
	}
	return nil
}

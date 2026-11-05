package socialrecall

import (
	"context"
	"errors"
	"math"
	"time"

	"gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrLoginFacts = errors.New("social recall: invalid canonical login facts")

type TaskRecord struct {
	Task         domain.Task
	StateVersion int64
	UpdatedAt    time.Time
}

type LoginOwner interface {
	ReadActiveRecallForTargetTx(context.Context, tx.Queryer, identity.PlayerID) (TaskRecord, bool, error)
	// Save includes releasing this task's target reservation in the caller transaction.
	SaveRecallLoginTransitionTx(context.Context, tx.Tx, TaskRecord, TaskRecord) error
}

type LoginReconciler struct{ Owner LoginOwner }

var _ bootstrap.CharacterLoginReconciler = LoginReconciler{}

func (LoginReconciler) Name() string { return "i9-10e.social-recall-completion" }

func (reconciler LoginReconciler) ReconcileCharacterLogin(ctx context.Context, transaction tx.Tx, actor identity.ActorContext, current operation.Context, at time.Time) error {
	if reconciler.Owner == nil || transaction == nil || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || current.ID.IsZero() || current.StartedAt.IsZero() || at.IsZero() {
		return ErrLoginFacts
	}
	previous, exists, err := reconciler.Owner.ReadActiveRecallForTargetTx(ctx, transaction, actor.PlayerID)
	if err != nil || !exists {
		return err
	}
	task := previous.Task
	if task.Validate() != nil || task.Target != actor.PlayerID || task.LogicalServerID != actor.LogicalServerID || previous.StateVersion < 1 || previous.UpdatedAt.IsZero() || previous.UpdatedAt.Before(task.StartedAt) {
		return ErrLoginFacts
	}
	if task.Status != domain.StatusActive {
		return nil
	}
	if at.Before(previous.UpdatedAt) {
		return nil
	}
	next, changed, err := task.Complete(at)
	if err != nil {
		return err
	}
	if !changed {
		next, changed, err = task.Expire(at)
	}
	if err != nil || !changed {
		return err
	}
	if previous.StateVersion == math.MaxInt64 {
		return ErrLoginFacts
	}
	return reconciler.Owner.SaveRecallLoginTransitionTx(ctx, transaction, previous, TaskRecord{Task: next, StateVersion: previous.StateVersion + 1, UpdatedAt: at.UTC()})
}

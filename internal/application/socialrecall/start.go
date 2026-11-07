package socialrecall

import (
	"context"
	"errors"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrStartFacts = errors.New("social recall: invalid start snapshot")
var ErrStartRefused = errors.New("social recall: target not eligible")

type TargetSnapshot struct {
	PlayerID     identity.PlayerID
	Revision     string
	ObservedAt   time.Time
	IsFriend     bool
	Online       bool
	OfflineSince time.Time
	Baseline     domain.Baseline
}

type TargetReader interface {
	ReadRecallTargetTx(context.Context, tx.Scope, identity.PlayerID, identity.PlayerID, string, time.Time) (TargetSnapshot, error)
}

type StartOwner interface {
	PrepareStartStateTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID, time.Time) (StartState, error)
	InsertTaskTx(context.Context, tx.Tx, TaskRecord) error
}

type StartRequest struct {
	Caller, Target                 identity.PlayerID
	LogicalServerID                identity.LogicalServerID
	ContentRevision, PolicyVersion string
	Limits                         domain.Limits
	Duration                       time.Duration
}

type Starter struct {
	Players playerroot.TxLocker
	Targets TargetReader
	Owner   StartOwner
}

// StartTx runs after the outer receipt recovery; its caller owns commit and reply persistence.
func (starter Starter) StartTx(ctx context.Context, scope tx.Scope, request StartRequest, at time.Time) (TaskRecord, error) {
	if starter.Players == nil || starter.Targets == nil || starter.Owner == nil || scope.Tx == nil || scope.Options.Isolation != tx.Serializable || scope.Options.ReadOnly || scope.Operation.ID.IsZero() || scope.Operation.StartedAt.IsZero() || scope.Attempt < 1 || at.IsZero() || characterasset.ValidateExactRevisionID(request.ContentRevision) != nil || strings.TrimSpace(request.PolicyVersion) == "" || request.Limits.Validate() != nil || request.Duration <= 0 {
		return TaskRecord{}, ErrStartFacts
	}
	if !request.Caller.Valid() || !request.Target.Valid() || request.Caller == request.Target || !request.LogicalServerID.Valid() || logicalserver.PlayerRegion(request.Caller) != request.LogicalServerID || logicalserver.PlayerRegion(request.Target) != request.LogicalServerID {
		return TaskRecord{}, ErrStartFacts
	}
	contentPin, contentBound := scope.Operation.Policies.Get("content")
	rosterPin, rosterBound := scope.Operation.Policies.Get("roster-metrics")
	if !contentBound || contentPin != request.ContentRevision || !rosterBound || rosterPin != characterasset.RosterMetricPolicy {
		return TaskRecord{}, ErrStartFacts
	}
	at = at.UTC()
	players, err := playerroot.CanonicalPlayerIDs([]identity.PlayerID{request.Caller, request.Target})
	if err != nil {
		return TaskRecord{}, err
	}
	roots, err := starter.Players.LockPlayerRootsTx(ctx, scope.Tx, request.LogicalServerID, players)
	if err != nil {
		return TaskRecord{}, err
	}
	if len(roots) != len(players) {
		return TaskRecord{}, ErrStartFacts
	}
	for index, root := range roots {
		if root.Validate() != nil || root.PlayerID != players[index] || root.LogicalServerID != request.LogicalServerID {
			return TaskRecord{}, ErrStartFacts
		}
	}
	target, err := starter.Targets.ReadRecallTargetTx(ctx, scope, request.Caller, request.Target, request.ContentRevision, at)
	if err != nil {
		return TaskRecord{}, err
	}
	if target.PlayerID != request.Target || target.Revision != request.ContentRevision || !target.ObservedAt.Equal(at) || target.Baseline.Validate() != nil || target.OfflineSince.After(at) {
		return TaskRecord{}, ErrStartFacts
	}
	if !target.IsFriend || target.Online || target.OfflineSince.IsZero() {
		return TaskRecord{}, ErrStartRefused
	}
	state, err := starter.Owner.PrepareStartStateTx(ctx, scope.Tx, request.Caller, request.Target, at)
	if err != nil {
		return TaskRecord{}, err
	}
	if state.ActiveTasks < 0 {
		return TaskRecord{}, ErrStartFacts
	}
	if state.ActiveTasks >= int64(request.Limits.MaxActiveTasks) {
		return TaskRecord{}, ErrStartRefused
	}
	eligible, err := domain.CanStart(domain.StartFacts{Caller: request.Caller, Target: request.Target, LogicalServerID: request.LogicalServerID, IsFriend: target.IsFriend, TargetAvailable: !target.Online, TargetReserved: state.TargetReserved, AlreadyCompleted: state.AlreadyCompleted, OfflineSince: target.OfflineSince}, int(state.ActiveTasks), request.Limits, at)
	if err != nil {
		return TaskRecord{}, err
	}
	if !eligible {
		return TaskRecord{}, ErrStartRefused
	}
	task, err := domain.NewTask(request.Caller, request.Target, request.LogicalServerID, scope.Operation.ID, at, request.Duration, target.Baseline)
	if err != nil {
		return TaskRecord{}, err
	}
	record := TaskRecord{Task: task, ContentRevision: request.ContentRevision, PolicyVersion: request.PolicyVersion, StateVersion: 1, UpdatedAt: at}
	if err := starter.Owner.InsertTaskTx(ctx, scope.Tx, record); err != nil {
		return TaskRecord{}, err
	}
	return record, nil
}

package socialrecallstore

import (
	"context"
	"encoding/hex"
	"errors"
	"math"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	application "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrStateConflict = errors.New("social recall: stale task state")

type Store struct{}

var _ application.LoginOwner = Store{}

func validRecord(record application.TaskRecord) bool {
	revision, err := hex.DecodeString(record.ContentRevision)
	return record.Task.Validate() == nil && record.StateVersion > 0 && !record.UpdatedAt.IsZero() && !record.UpdatedAt.Before(record.Task.StartedAt) && err == nil && len(revision) == 32 && record.ContentRevision == strings.ToLower(record.ContentRevision) && strings.TrimSpace(record.PolicyVersion) != ""
}

func (Store) InsertTaskTx(ctx context.Context, transaction tx.Tx, record application.TaskRecord) error {
	if transaction == nil || !validRecord(record) || record.StateVersion != 1 || record.Task.Status != domain.StatusActive || !record.UpdatedAt.Equal(record.Task.StartedAt) {
		return application.ErrLoginFacts
	}
	task := record.Task
	tag, err := transaction.Exec(ctx, `INSERT INTO social_recall_tasks(operation_id,caller_player_id,target_player_id,logical_server_id,content_revision,policy_version,started_at,expires_at,status,baseline_academy_level,baseline_owned_hero_count,baseline_charge_total,state_version,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,'ACTIVE',$9,$10,$11,1,$7)`, task.OperationID.String(), int64(task.Caller), int64(task.Target), int32(task.LogicalServerID), record.ContentRevision, record.PolicyVersion, task.StartedAt, task.ExpiresAt, task.Baseline.AcademyLevel, task.Baseline.OwnedHeroCount, task.Baseline.ChargeTotal)
	return checkedEffect(tag, err)
}

func (Store) ReadActiveRecallForTargetTx(ctx context.Context, query tx.Tx, target identity.PlayerID) (application.TaskRecord, bool, error) {
	if query == nil || !target.Valid() {
		return application.TaskRecord{}, false, application.ErrLoginFacts
	}
	var record application.TaskRecord
	var operationID string
	err := query.QueryRow(ctx, `SELECT operation_id::text,caller_player_id,target_player_id,logical_server_id,content_revision,policy_version,started_at,expires_at,status,baseline_academy_level,baseline_owned_hero_count,baseline_charge_total,state_version,updated_at FROM social_recall_tasks WHERE target_player_id=$1 AND status='ACTIVE' FOR UPDATE`, int64(target)).Scan(&operationID, &record.Task.Caller, &record.Task.Target, &record.Task.LogicalServerID, &record.ContentRevision, &record.PolicyVersion, &record.Task.StartedAt, &record.Task.ExpiresAt, &record.Task.Status, &record.Task.Baseline.AcademyLevel, &record.Task.Baseline.OwnedHeroCount, &record.Task.Baseline.ChargeTotal, &record.StateVersion, &record.UpdatedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return application.TaskRecord{}, false, nil
	}
	if err != nil {
		return record, false, err
	}
	record.Task.OperationID, err = ids.ParseUUID(operationID)
	if err != nil {
		return record, false, application.ErrLoginFacts
	}
	record.Task.StartedAt = record.Task.StartedAt.UTC()
	record.Task.ExpiresAt = record.Task.ExpiresAt.UTC()
	record.UpdatedAt = record.UpdatedAt.UTC()
	if !validRecord(record) || record.Task.Target != target {
		return record, false, application.ErrLoginFacts
	}
	return record, true, nil
}

func (Store) SaveRecallLoginTransitionTx(ctx context.Context, transaction tx.Tx, previous, next application.TaskRecord) error {
	if transaction == nil || !validRecord(previous) || !validRecord(next) || previous.Task.Status != domain.StatusActive || previous.StateVersion == math.MaxInt64 || next.StateVersion != previous.StateVersion+1 || next.UpdatedAt.Before(previous.UpdatedAt) || next.ContentRevision != previous.ContentRevision || next.PolicyVersion != previous.PolicyVersion {
		return application.ErrLoginFacts
	}
	expected, changed, err := previous.Task.Complete(next.UpdatedAt)
	if err != nil {
		return err
	}
	if !changed {
		expected, changed, err = previous.Task.Expire(next.UpdatedAt)
	}
	if err != nil {
		return err
	}
	if !changed {
		return application.ErrLoginFacts
	}
	expectedCompletion, nextCompletion := expected.CompletedAt, next.Task.CompletedAt
	expected.CompletedAt = nil
	nextTask := next.Task
	nextTask.CompletedAt = nil
	sameCompletion := expectedCompletion == nil && nextCompletion == nil || expectedCompletion != nil && nextCompletion != nil && expectedCompletion.Equal(*nextCompletion)
	if expected != nextTask || !sameCompletion {
		return application.ErrLoginFacts
	}
	tag, err := transaction.Exec(ctx, `UPDATE social_recall_tasks SET status=$3,completed_at=$4,state_version=$5,updated_at=$6 WHERE operation_id=$1 AND state_version=$2 AND status='ACTIVE'`, previous.Task.OperationID.String(), previous.StateVersion, next.Task.Status, next.Task.CompletedAt, next.StateVersion, next.UpdatedAt)
	return checkedEffect(tag, err)
}

func checkedEffect(tag tx.CommandTag, err error) error {
	if err != nil {
		return err
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return ErrStateConflict
	}
	return nil
}

// The caller must acquire its governed player roots before entering the task lane.
func (store Store) PrepareStartStateTx(ctx context.Context, transaction tx.Tx, caller, target identity.PlayerID, at time.Time) (application.StartState, error) {
	server := logicalserver.PlayerRegion(caller)
	if transaction == nil || !caller.Valid() || !target.Valid() || caller == target || !server.Valid() || logicalserver.PlayerRegion(target) != server || at.IsZero() {
		return application.StartState{}, application.ErrLoginFacts
	}
	at = at.UTC()
	previous, reserved, err := store.ReadActiveRecallForTargetTx(ctx, transaction, target)
	if err != nil {
		return application.StartState{}, err
	}
	if reserved && at.Before(previous.UpdatedAt) {
		return application.StartState{}, application.ErrLoginFacts
	}
	if reserved && !at.Before(previous.Task.ExpiresAt) {
		if previous.StateVersion == math.MaxInt64 {
			return application.StartState{}, application.ErrLoginFacts
		}
		next := previous
		next.Task, _, err = previous.Task.Expire(at)
		if err != nil {
			return application.StartState{}, err
		}
		next.StateVersion++
		next.UpdatedAt = at
		if err := store.SaveRecallLoginTransitionTx(ctx, transaction, previous, next); err != nil {
			return application.StartState{}, err
		}
		reserved = false
	}
	state := application.StartState{TargetReserved: reserved}
	err = transaction.QueryRow(ctx, `SELECT (SELECT count(*) FROM social_recall_tasks WHERE caller_player_id=$1 AND logical_server_id=$3 AND status='ACTIVE' AND expires_at>$4), EXISTS(SELECT 1 FROM social_recall_tasks WHERE caller_player_id=$1 AND target_player_id=$2 AND logical_server_id=$3 AND status='COMPLETED')`, int64(caller), int64(target), int32(server), at).Scan(&state.ActiveTasks, &state.AlreadyCompleted)
	return state, err
}

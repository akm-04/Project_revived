package socialrecall

import (
	"context"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type loginOwnerFake struct {
	record TaskRecord
	exists bool
	saves  int
	rooted bool
}

func (owner *loginOwnerFake) ReadActiveRecallForTargetTx(context.Context, tx.Tx, identity.PlayerID) (TaskRecord, bool, error) {
	if !owner.rooted {
		return TaskRecord{}, false, ErrLoginFacts
	}
	return owner.record, owner.exists, nil
}
func (owner *loginOwnerFake) SaveRecallLoginTransitionTx(_ context.Context, _ tx.Tx, previous TaskRecord, next TaskRecord) error {
	owner.saves++
	owner.record = next
	return nil
}
func (owner *loginOwnerFake) LockPlayerRootsTx(_ context.Context, _ tx.Tx, server identity.LogicalServerID, players []identity.PlayerID) ([]playerroot.Root, error) {
	owner.rooted = true
	return []playerroot.Root{{PlayerID: players[0], LogicalServerID: server}}, nil
}

func TestLoginReconcilerCompletesOnlyCanonicalTargetWithinWindow(t *testing.T) {
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	task, err := domain.NewTask(100002, 100001, 1, id, at, 72*time.Hour, domain.Baseline{AcademyLevel: 51})
	if err != nil {
		t.Fatal(err)
	}
	current := operation.Context{ID: id, StartedAt: at}
	actor := identity.ActorContext{PlayerID: 100001, LogicalServerID: 1}
	for _, cell := range []struct {
		name   string
		login  time.Time
		status domain.Status
		writes int
	}{{"before", at.Add(-time.Second), domain.StatusActive, 0}, {"at-start", at, domain.StatusCompleted, 1}, {"before-expiry", task.ExpiresAt.Add(-time.Second), domain.StatusCompleted, 1}, {"at-expiry", task.ExpiresAt, domain.StatusExpired, 1}} {
		t.Run(cell.name, func(t *testing.T) {
			owner := &loginOwnerFake{record: TaskRecord{Task: task, StateVersion: 1, UpdatedAt: at, ContentRevision: "source-pin", PolicyVersion: "policy-pin"}, exists: true}
			service := LoginReconciler{Owner: owner, Players: owner}
			transaction := struct{ tx.Tx }{}
			if err := service.ReconcileCharacterLogin(context.Background(), transaction, actor, current, cell.login); err != nil {
				t.Fatal(err)
			}
			if owner.record.ContentRevision != "source-pin" || owner.record.PolicyVersion != "policy-pin" {
				t.Fatal("login transition discarded captured source or policy", owner.record)
			}
			if owner.saves != cell.writes || owner.record.Task.Status != cell.status {
				t.Fatal(owner)
			}
			if err := service.ReconcileCharacterLogin(context.Background(), transaction, actor, current, cell.login); err != nil || owner.saves != cell.writes {
				t.Fatal("repeated login changed completion", owner, err)
			}
		})
	}
	owner := &loginOwnerFake{record: TaskRecord{Task: task, StateVersion: 1, UpdatedAt: at, ContentRevision: "source-pin", PolicyVersion: "policy-pin"}, exists: true}
	actor.PlayerID = 100003
	if err := (LoginReconciler{Owner: owner, Players: owner}).ReconcileCharacterLogin(context.Background(), struct{ tx.Tx }{}, actor, current, at); err == nil || owner.saves != 0 {
		t.Fatal("foreign target accepted", err)
	}
}

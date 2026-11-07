package socialrecall

import (
	"context"
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type startFixture struct {
	events   []string
	roots    []identity.PlayerID
	target   TargetSnapshot
	state    StartState
	inserted TaskRecord
}

func (fixture *startFixture) LockPlayerRootsTx(_ context.Context, _ tx.Tx, server identity.LogicalServerID, players []identity.PlayerID) ([]playerroot.Root, error) {
	fixture.events = append(fixture.events, "roots")
	fixture.roots = append([]identity.PlayerID{}, players...)
	return []playerroot.Root{{PlayerID: 100001, LogicalServerID: server}, {PlayerID: 100002, LogicalServerID: server}}, nil
}
func (fixture *startFixture) ReadRecallTargetTx(_ context.Context, _ tx.Scope, caller, target identity.PlayerID, revision string, at time.Time) (TargetSnapshot, error) {
	fixture.events = append(fixture.events, "target")
	return fixture.target, nil
}
func (fixture *startFixture) PrepareStartStateTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID, time.Time) (StartState, error) {
	fixture.events = append(fixture.events, "lane")
	return fixture.state, nil
}
func (fixture *startFixture) InsertTaskTx(_ context.Context, _ tx.Tx, record TaskRecord) error {
	fixture.events = append(fixture.events, "insert")
	fixture.inserted = record
	return nil
}
func startSetup(t *testing.T) (*startFixture, tx.Scope, StartRequest, time.Time) {
	t.Helper()
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	revision := strings.Repeat("a", 64)
	pins, err := policy.NewSet(policy.Ref{Name: "content", Version: revision}, policy.Ref{Name: "roster-metrics", Version: "C4C_PRIVATE_CURRENT_ROSTER_V1"})
	if err != nil {
		t.Fatal(err)
	}
	scope := tx.Scope{Tx: struct{ tx.Tx }{}, Operation: operation.Context{ID: identifier, StartedAt: at, Policies: pins}, Attempt: 1, Options: tx.Options{Isolation: tx.Serializable}}
	target := TargetSnapshot{PlayerID: 100002, Revision: revision, ObservedAt: at, IsFriend: true, OfflineSince: at.Add(-8 * 24 * time.Hour), Baseline: domain.Baseline{AcademyLevel: 51, OwnedHeroCount: 12, ChargeTotal: 100}}
	return &startFixture{target: target}, scope, StartRequest{Caller: 100001, Target: 100002, LogicalServerID: 1, ContentRevision: revision, PolicyVersion: "I9_10E_SOCIAL_RECALL_V1", Limits: domain.Limits{RequiredOffline: 7 * 24 * time.Hour, MaxActiveTasks: 3}, Duration: 72 * time.Hour}, at
}
func TestStartLocksBeforeTargetLaneAndCapturesBaseline(t *testing.T) {
	fixture, scope, request, at := startSetup(t)
	record, err := (Starter{Players: fixture, Targets: fixture, Owner: fixture}).StartTx(context.Background(), scope, request, at)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(fixture.events, []string{"roots", "target", "lane", "insert"}) || !reflect.DeepEqual(fixture.roots, []identity.PlayerID{100001, 100002}) {
		t.Fatal(fixture.events, fixture.roots)
	}
	if record != fixture.inserted || record.Task.Baseline != fixture.target.Baseline || record.Task.OperationID != scope.Operation.ID || record.ContentRevision != request.ContentRevision || record.PolicyVersion != request.PolicyVersion || record.StateVersion != 1 || !record.Task.ExpiresAt.Equal(at.Add(request.Duration)) {
		t.Fatal(record)
	}
}
func TestStartRefusesWithoutInserting(t *testing.T) {
	for _, name := range []string{"reserved", "completed", "limit", "not-friend", "online", "unknown-offline", "exact-seven-days", "future-facts", "foreign-facts", "bad-revision", "read-committed", "read-only"} {
		t.Run(name, func(t *testing.T) {
			fixture, scope, request, at := startSetup(t)
			switch name {
			case "reserved":
				fixture.state.TargetReserved = true
			case "completed":
				fixture.state.AlreadyCompleted = true
			case "limit":
				fixture.state.ActiveTasks = 3
			case "not-friend":
				fixture.target.IsFriend = false
			case "online":
				fixture.target.Online = true
			case "unknown-offline":
				fixture.target.OfflineSince = time.Time{}
			case "exact-seven-days":
				fixture.target.OfflineSince = at.Add(-7 * 24 * time.Hour)
			case "future-facts":
				fixture.target.ObservedAt = at.Add(time.Second)
			case "foreign-facts":
				fixture.target.PlayerID = 100003
			case "bad-revision":
				fixture.target.Revision = strings.Repeat("b", 64)
			case "read-committed":
				scope.Options.Isolation = tx.ReadCommitted
			case "read-only":
				scope.Options.ReadOnly = true
			}
			_, err := (Starter{Players: fixture, Targets: fixture, Owner: fixture}).StartTx(context.Background(), scope, request, at)
			if err == nil || !fixture.inserted.Task.OperationID.IsZero() {
				t.Fatal("refusal inserted task", err, fixture.events)
			}
			if name == "reserved" && !errors.Is(err, ErrStartRefused) {
				t.Fatal(err)
			}
		})
	}
}

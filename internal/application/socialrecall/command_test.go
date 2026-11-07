package socialrecall

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type commandTag int64

func (tag commandTag) RowsAffected() int64 { return int64(tag) }

type commandFixture struct {
	*startFixture
	at                                  time.Time
	revision                            string
	stored, pending                     receipt.Receipt
	contentError, putError, commitError error
	collision, dropReceipt              bool
}

func (fixture *commandFixture) Begin(context.Context, tx.Options) (tx.Tx, error) {
	fixture.pending = receipt.Receipt{}
	return fixture, nil
}
func (*commandFixture) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return commandTag(1), nil
}
func (*commandFixture) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (fixture *commandFixture) Commit(context.Context) error {
	if !fixture.dropReceipt && !fixture.pending.ID.IsZero() {
		fixture.stored = fixture.pending
	}
	return fixture.commitError
}
func (fixture *commandFixture) Rollback(context.Context) error {
	fixture.pending = receipt.Receipt{}
	return nil
}
func (fixture *commandFixture) Now(context.Context) (time.Time, error) { return fixture.at, nil }
func (fixture *commandFixture) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	fixture.events = append(fixture.events, "fence")
	return nil
}
func (fixture *commandFixture) FindTx(context.Context, tx.Queryer, receipt.Identity) (receipt.Receipt, bool, error) {
	fixture.events = append(fixture.events, "receipt")
	return fixture.stored, !fixture.stored.ID.IsZero(), nil
}
func (fixture *commandFixture) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	return fixture.stored, !fixture.stored.ID.IsZero(), nil
}
func (fixture *commandFixture) PutTx(_ context.Context, _ tx.Tx, value receipt.Receipt) (receipt.PutResult, error) {
	fixture.events = append(fixture.events, "put")
	if fixture.putError != nil {
		return receipt.PutResult{}, fixture.putError
	}
	if fixture.collision {
		return receipt.PutResult{}, nil
	}
	fixture.pending = value
	return receipt.PutResult{Inserted: true, Receipt: value}, nil
}
func (fixture *commandFixture) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	fixture.events = append(fixture.events, "active")
	return fixture.revision, fixture.contentError
}
func (fixture *commandFixture) SocialRecallRulesTx(context.Context, tx.Queryer, string) (domain.StartRules, error) {
	fixture.events = append(fixture.events, "rules")
	return domain.StartRules{Limits: domain.Limits{RequiredOffline: 7 * 24 * time.Hour, MaxActiveTasks: 3}, TaskDuration: 72 * time.Hour}, fixture.contentError
}
func (fixture *commandFixture) DoingRecallTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time, int) ([]DoingRecall, error) {
	fixture.events = append(fixture.events, "projection")
	return []DoingRecall{{PlayerID: 100002, PlayerName: "Target", RecallingTime: fixture.at.Unix()}}, nil
}
func commandSetup(t *testing.T) (StartService, *commandFixture, identity.ActorContext, operation.Context) {
	t.Helper()
	inner, scope, request, at := startSetup(t)
	fixture := &commandFixture{startFixture: inner, at: at, revision: request.ContentRevision}
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(identifier)
	if err != nil {
		t.Fatal(err)
	}
	actor := identity.ActorContext{PlayerID: request.Caller, LogicalServerID: 1, AccountUID: "recall-account", ContextID: contextID}
	current := scope.Operation
	current.Policies = policy.Set{}
	service := StartService{Timed: generation.TimedRunner{Binder: generation.Binder{Time: fixture}, Runner: tx.Runner{DB: fixture}}, Fence: fixture, Content: fixture, Starter: Starter{Players: fixture, Targets: fixture, Owner: fixture}, Projection: fixture, Receipts: fixture, ReceiptReader: fixture}
	return service, fixture, actor, current
}
func TestRecallCommandReplaysBeforeUnavailableContent(t *testing.T) {
	service, fixture, actor, current := commandSetup(t)
	first, err := service.Start(context.Background(), actor, 100002, current)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(fixture.events, []string{"fence", "receipt", "active", "rules", "roots", "target", "lane", "insert", "projection", "put"}) {
		t.Fatal(fixture.events)
	}
	fixture.events = nil
	fixture.contentError = errors.New("content unavailable")
	again, err := service.Start(context.Background(), actor, 100002, current)
	if err != nil || !reflect.DeepEqual(first, again) || !reflect.DeepEqual(fixture.events, []string{"fence", "receipt"}) {
		t.Fatal(again, err, fixture.events)
	}
	_, err = service.Start(context.Background(), actor, 100003, current)
	var conflict *receipt.ConflictError
	if !errors.As(err, &conflict) {
		t.Fatal("changed target replay accepted", err)
	}
}
func TestRecallCommandRefusesReceiptCollisionAndFailedPut(t *testing.T) {
	for _, collision := range []bool{false, true} {
		t.Run(map[bool]string{false: "put-error", true: "collision"}[collision], func(t *testing.T) {
			service, fixture, actor, current := commandSetup(t)
			fixture.collision = collision
			if !collision {
				fixture.putError = errors.New("put failed")
			}
			if _, err := service.Start(context.Background(), actor, 100002, current); err == nil {
				t.Fatal("terminal write failure accepted")
			}
			if !fixture.stored.ID.IsZero() || !fixture.pending.ID.IsZero() {
				t.Fatal("failed command committed receipt")
			}
		})
	}
}
func TestRecallCommandUnknownCommitUsesReceiptOnly(t *testing.T) {
	service, fixture, actor, current := commandSetup(t)
	fixture.commitError = errors.New("lost commit acknowledgment")
	if _, err := service.Start(context.Background(), actor, 100002, current); err != nil {
		t.Fatal("committed receipt not recovered", err)
	}
	service, fixture, actor, current = commandSetup(t)
	fixture.commitError = errors.New("lost commit acknowledgment")
	fixture.dropReceipt = true
	if _, err := service.Start(context.Background(), actor, 100002, current); err == nil {
		t.Fatal("receipt absence treated as replay permission")
	}
}

func TestRecallCommandRejectsCorruptOrForeignReceipt(t *testing.T) {
	for _, name := range []string{"account", "context", "policy", "missing-content-ref", "missing-roster-ref", "missing-recall-ref", "start-time", "fingerprint", "entropy", "negative-baseline", "missing-target", "duplicate-target", "future-row", "unknown-field"} {
		t.Run(name, func(t *testing.T) {
			service, fixture, actor, current := commandSetup(t)
			if _, err := service.Start(context.Background(), actor, 100002, current); err != nil {
				t.Fatal(err)
			}
			terminal := startTerminal{}
			if err := json.Unmarshal(fixture.stored.ResultPayload, &terminal); err != nil {
				t.Fatal(err)
			}
			switch name {
			case "account":
				fixture.stored.ActorAccountUID = "other"
			case "context":
				fixture.stored.ContextID = ids.UUID{}
			case "policy":
				fixture.stored.PolicyVersion = "other"
			case "missing-content-ref":
				fixture.stored.OperationPolicyRefs, _ = policy.NewSet(policy.Ref{Name: "roster-metrics", Version: "C4C_PRIVATE_CURRENT_ROSTER_V1"}, policy.Ref{Name: "socialrecall", Version: RecallPolicyVersion})
			case "missing-roster-ref":
				fixture.stored.OperationPolicyRefs, _ = policy.NewSet(policy.Ref{Name: "content", Version: fixture.revision}, policy.Ref{Name: "socialrecall", Version: RecallPolicyVersion})
			case "missing-recall-ref":
				fixture.stored.OperationPolicyRefs, _ = policy.NewSet(policy.Ref{Name: "content", Version: fixture.revision}, policy.Ref{Name: "roster-metrics", Version: "C4C_PRIVATE_CURRENT_ROSTER_V1"})
			case "start-time":
				fixture.stored.OperationStartedAt = fixture.stored.OperationStartedAt.Add(time.Second)
			case "fingerprint":
				fixture.stored.RequestFingerprint = [32]byte{}
			case "entropy":
				terminal.EntropySeed[0] ^= 1
			case "negative-baseline":
				terminal.Record.Task.Baseline.ChargeTotal = -1
			case "missing-target":
				terminal.Doing = nil
			case "duplicate-target":
				terminal.Doing = append(terminal.Doing, terminal.Doing[0])
			case "future-row":
				terminal.Doing[0].RecallingTime++
			}
			raw, err := json.Marshal(terminal)
			if err != nil {
				t.Fatal(err)
			}
			if name == "unknown-field" {
				var fields map[string]any
				if err := json.Unmarshal(raw, &fields); err != nil {
					t.Fatal(err)
				}
				fields["Unexpected"] = true
				raw, err = json.Marshal(fields)
				if err != nil {
					t.Fatal(err)
				}
			}
			fixture.stored.ResultPayload = raw
			fixture.events = nil
			if _, err := service.Start(context.Background(), actor, 100002, current); err == nil {
				t.Fatal("invalid stored reply accepted", name)
			}
			if !reflect.DeepEqual(fixture.events, []string{"fence", "receipt"}) {
				t.Fatal("corrupt replay reached current configuration", fixture.events)
			}
		})
	}
}

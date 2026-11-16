package conquerschool

import (
	"context"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	cd "gxb.local/backend/v2/internal/domain/combat"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builder opens.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceConquerSchool STARTs 1569 twice for one mission
// with a changed formation. The client sends the team it fights with
// (model/ConquerSchool.lua:173-176), so the choice is player-changeable and
// ClientSummaryAttested supersedes; bind folds formation and pet into the
// fingerprint (conquerschool/mode.go:137).
func TestStartChoiceConformanceConquerSchool(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	combat := &startChoiceCombat{}
	mode := Mode{Combat: combat}
	st := session{run: d.Run{Loop: 1, CurrentID: 10001, Generation: "conquer-school:1"}, revision: startChoiceRevision}
	firstOperation := startChoiceScope(t, ids.UUID{1}, at)
	if _, err := mode.bind(context.Background(), firstOperation, actor, st, []int64{101}, 0); err != nil {
		t.Fatalf("first START: %v", err)
	}
	if _, err := mode.bind(context.Background(), startChoiceScope(t, ids.UUID{2}, at), actor, st, []int64{201}, 0); err != nil {
		t.Fatalf("second START: %v", err)
	}
	if _, err := mode.bind(context.Background(), firstOperation, actor, st, []int64{201}, 0); err != nil {
		t.Fatalf("same-operation changed START: %v", err)
	}
	if len(combat.requests) != 3 {
		t.Fatalf("captured %d START requests, want three", len(combat.requests))
	}
	first, second, sameOperation := combat.requests[0], combat.requests[1], combat.requests[2]
	for _, request := range []appcombat.StartRequest{first, second, sameOperation} {
		if request.Mode != cd.ModeConquerSchool {
			t.Fatalf("built mode %q", request.Mode)
		}
		if request.Locator != first.Locator || request.GenerationRef != first.GenerationRef {
			t.Fatal("STARTed two different stages")
		}
	}
	if first.StartFingerprint == second.StartFingerprint {
		t.Fatal("a changed formation kept the first fingerprint")
	}
	if first.Battle.Formation[0] != 101 || second.Battle.Formation[0] != 201 {
		t.Fatalf("frozen formations %v / %v", first.Battle.Formation, second.Battle.Formation)
	}
	// The same operation with a changed formation must also change the
	// fingerprint, so the choice itself is folded rather than only the operation.
	if first.StartFingerprint == sameOperation.StartFingerprint {
		t.Fatal("a changed formation under one operation kept the same fingerprint")
	}
}

// startChoiceCombat records the StartRequest the mode builder produced.
type startChoiceCombat struct {
	Combat
	requests []appcombat.StartRequest
}

func (c *startChoiceCombat) StartTx(_ context.Context, _ tx.Tx, _ ca.CoherentReadScope, request appcombat.StartRequest) (appcombat.Started, error) {
	c.requests = append(c.requests, request)
	return appcombat.Started{Attempt: cd.Attempt{ID: ids.UUID{byte(len(c.requests))}}}, nil
}

func startChoiceScope(t *testing.T, id ids.UUID, at time.Time) gen.TimedScope {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	timed, err := gen.NewTimedOperation(operation.Context{ID: id, StartedAt: at, Policies: policies}, at)
	if err != nil {
		t.Fatal(err)
	}
	return gen.TimedScope{Tx: startChoiceTx{}, Operation: timed, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}
}

type startChoiceTx struct{}

func (startChoiceTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (startChoiceTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (startChoiceTx) Commit(context.Context) error                                { return nil }
func (startChoiceTx) Rollback(context.Context) error                              { return nil }

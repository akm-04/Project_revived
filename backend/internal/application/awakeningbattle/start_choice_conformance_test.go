package awakeningbattle

import (
	"context"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builder opens.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceAwakeningBlood STARTs 866 twice for one twice-awake
// mission. The stock request carries no team (stockruntime/awakening_blood_
// dispatcher.go:41-44); the battle team is the frozen occurrence's owner
// (awakeningbattle/mode.go:83,98), fixed by the mission, so both STARTs carry
// one replay identity and combat.Service replays the first (service.go:143-145).
func TestStartChoiceConformanceAwakeningBlood(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	occurrence := objective.AwakeInstance{Mission: 2001002, Type: 2, OwnerID: 9001, Generation: 1, Revision: startChoiceRevision}
	combat := &startChoiceCombat{}
	mode := startChoiceMode(at, occurrence, combat)
	if _, err := mode.Start(context.Background(), actor, 2001002, startChoiceOperation(t, ids.UUID{1}, at)); err != nil {
		t.Fatalf("first START: %v", err)
	}
	if _, err := mode.Start(context.Background(), actor, 2001002, startChoiceOperation(t, ids.UUID{2}, at)); err != nil {
		t.Fatalf("second START: %v", err)
	}
	if len(combat.requests) != 2 {
		t.Fatalf("captured %d START requests, want two", len(combat.requests))
	}
	first, second := combat.requests[0], combat.requests[1]
	if first.Mode != cd.ModeAwakeningBlood || second.Mode != cd.ModeAwakeningBlood {
		t.Fatalf("built modes %q and %q", first.Mode, second.Mode)
	}
	if first.Locator != second.Locator || first.GenerationRef != second.GenerationRef || first.StartFingerprint != second.StartFingerprint {
		t.Fatal("a mission-fixed team STARTed two different replay identities")
	}
	if len(first.Battle.TeamA) != 1 || first.Battle.TeamA[0].Identity != occurrence.OwnerID || len(second.Battle.TeamA) != 1 || second.Battle.TeamA[0].Identity != occurrence.OwnerID {
		t.Fatalf("frozen teams differ from the occurrence owner: %+v / %+v", first.Battle.TeamA, second.Battle.TeamA)
	}
}

func startChoiceMode(at time.Time, occurrence objective.AwakeInstance, combat *startChoiceCombat) Mode {
	return Mode{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Fresh:       startChoiceQueryer{},
		Content:     startChoiceContent{},
		Fence:       startChoiceFence{},
		Heroes:      startChoiceHeroes{},
		Missions:    startChoiceMissions{occurrence: occurrence},
		Combat:      combat,
		Receipts:    startChoiceReceipts{},
		ReceiptRead: startChoiceReceiptRead{},
	}
}

// startChoiceCombat records the StartRequest the mode builder produced and
// answers like a frozen START. An existing unresolved attempt is the one the
// combat owner would find, so the mode's expiry branch is observable.
type startChoiceCombat struct {
	Combat
	requests []appcombat.StartRequest
	existing *cd.Attempt
	evidence []string
	closes   []appcombat.TerminalRequest
	calls    []string
}

func (c *startChoiceCombat) StartTx(_ context.Context, _ tx.Tx, _ ca.CoherentReadScope, request appcombat.StartRequest) (appcombat.Started, error) {
	c.calls = append(c.calls, "start")
	c.requests = append(c.requests, request)
	return appcombat.Started{Attempt: cd.Attempt{ID: ids.UUID{byte(len(c.requests))}}}, nil
}

func (c *startChoiceCombat) StartEvidenceTx(_ context.Context, _ tx.Queryer, _ cd.Locator, fingerprint string) (cd.Attempt, bool, error) {
	c.calls = append(c.calls, "evidence")
	c.evidence = append(c.evidence, fingerprint)
	if c.existing == nil {
		return cd.Attempt{}, false, nil
	}
	return *c.existing, true, nil
}

func (c *startChoiceCombat) CloseTx(_ context.Context, _ tx.Tx, request appcombat.TerminalRequest) (appcombat.Closed, error) {
	c.calls = append(c.calls, "close")
	c.closes = append(c.closes, request)
	closed := *c.existing
	c.existing = nil
	return appcombat.Closed{Attempt: closed}, nil
}

func (c *startChoiceCombat) AttestSummaryTx(context.Context, tx.Tx, appcombat.SummaryRequest) (appcombat.SummaryAttested, error) {
	return appcombat.SummaryAttested{}, nil
}

type startChoiceHeroes struct{ i5.AwakeningHeroes }

func (startChoiceHeroes) LockAwakeningHeroesTx(context.Context, tx.Tx, identity.PlayerID, string) ([]i5.AwakeningHero, error) {
	return nil, nil
}

type startChoiceMissions struct {
	i5.AwakeningBloodPort
	occurrence objective.AwakeInstance
}

func (m startChoiceMissions) FreezeAwakeningBloodTx(context.Context, tx.Queryer, identity.PlayerID, int64) (i5.AwakeningBloodContext, error) {
	return i5.AwakeningBloodContext{Occurrence: m.occurrence, WindowSeconds: 600}, nil
}

type startChoiceContent struct{}

func (startChoiceContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return startChoiceRevision, nil
}

type startChoiceFence struct{}

func (startChoiceFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type startChoiceReceipts struct{ receipt.Store }

type startChoiceReceiptRead struct{ receipt.Reader }

type startChoiceQueryer struct{}

func (startChoiceQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type startChoiceTx struct{}

func (startChoiceTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (startChoiceTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (startChoiceTx) Commit(context.Context) error                                { return nil }
func (startChoiceTx) Rollback(context.Context) error                              { return nil }

type startChoiceBeginner struct{}

func (startChoiceBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return startChoiceTx{}, nil
}

type startChoiceClock struct{ at time.Time }

func (c startChoiceClock) Now(context.Context) (time.Time, error) { return c.at, nil }

func startChoiceOperation(t *testing.T, id ids.UUID, at time.Time) operation.Context {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at, Policies: policies}
}

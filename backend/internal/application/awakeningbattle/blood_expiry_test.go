package awakeningbattle

import (
	"context"
	"testing"
	"time"

	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
)

var bloodExpiryAt = time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)

func bloodExpiryOccurrence() objective.AwakeInstance {
	return objective.AwakeInstance{Mission: 2001002, Type: 2, OwnerID: 9001, Generation: 1, Revision: startChoiceRevision}
}

func bloodExpiryActor() identity.ActorContext {
	return identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
}

func bloodExpiryAttempt(deadline time.Time) cd.Attempt {
	return cd.Attempt{ID: ids.UUID{7}, GenerationRef: "blood:2001002:1", StartFingerprint: "old", ResultDeadline: deadline, State: cd.Staged}
}

// TestStartExpiredAttemptClosesAndReplaces spends an attempt whose result
// deadline has passed: START retires it exactly once, then inserts a successor
// with a later deadline.
func TestStartExpiredAttemptClosesAndReplaces(t *testing.T) {
	existing := bloodExpiryAttempt(bloodExpiryAt)
	combat := &startChoiceCombat{existing: &existing}
	mode := startChoiceMode(bloodExpiryAt, bloodExpiryOccurrence(), combat)
	if _, err := mode.Start(context.Background(), bloodExpiryActor(), 2001002, startChoiceOperation(t, ids.UUID{1}, bloodExpiryAt)); err != nil {
		t.Fatalf("START: %v", err)
	}
	if len(combat.closes) != 1 {
		t.Fatalf("closed %d expired attempts, want one", len(combat.closes))
	}
	closed := combat.closes[0]
	if closed.TerminalKind != "AWAKENING_BLOOD_EXPIRED" || closed.SemanticReceiptID != "blood-expired:"+existing.ID.String() {
		t.Fatalf("close terminal %q receipt %q", closed.TerminalKind, closed.SemanticReceiptID)
	}
	if closed.GenerationRef != existing.GenerationRef || !closed.At.Equal(bloodExpiryAt) {
		t.Fatalf("close generation %q at %v", closed.GenerationRef, closed.At)
	}
	if len(combat.requests) != 1 {
		t.Fatalf("captured %d START requests, want one", len(combat.requests))
	}
	if !combat.requests[0].ResultDeadline.After(existing.ResultDeadline) {
		t.Fatalf("successor deadline %v not after the expired %v", combat.requests[0].ResultDeadline, existing.ResultDeadline)
	}
	if len(combat.evidence) != 1 || combat.evidence[0] != combat.requests[0].StartFingerprint {
		t.Fatalf("evidence fingerprint %v differs from START %q", combat.evidence, combat.requests[0].StartFingerprint)
	}
	if len(combat.calls) != 3 || combat.calls[0] != "evidence" || combat.calls[1] != "close" || combat.calls[2] != "start" {
		t.Fatalf("call order %v, want evidence, close, start", combat.calls)
	}
}

// TestStartLiveAttemptReplaysWithoutClose keeps the pre-deadline replay: an
// attempt still inside its window is not closed and the same START proceeds.
func TestStartLiveAttemptReplaysWithoutClose(t *testing.T) {
	existing := bloodExpiryAttempt(bloodExpiryAt.Add(time.Hour))
	combat := &startChoiceCombat{existing: &existing}
	mode := startChoiceMode(bloodExpiryAt, bloodExpiryOccurrence(), combat)
	if _, err := mode.Start(context.Background(), bloodExpiryActor(), 2001002, startChoiceOperation(t, ids.UUID{1}, bloodExpiryAt)); err != nil {
		t.Fatalf("START: %v", err)
	}
	if len(combat.closes) != 0 {
		t.Fatalf("closed a live attempt: %+v", combat.closes)
	}
	if len(combat.requests) != 1 {
		t.Fatalf("captured %d START requests, want one", len(combat.requests))
	}
	if len(combat.calls) != 2 || combat.calls[0] != "evidence" || combat.calls[1] != "start" {
		t.Fatalf("call order %v, want evidence, start", combat.calls)
	}
}

// TestStartWithoutAttemptDoesNotClose proves a fresh mission never reaches the
// close path.
func TestStartWithoutAttemptDoesNotClose(t *testing.T) {
	combat := &startChoiceCombat{}
	mode := startChoiceMode(bloodExpiryAt, bloodExpiryOccurrence(), combat)
	if _, err := mode.Start(context.Background(), bloodExpiryActor(), 2001002, startChoiceOperation(t, ids.UUID{1}, bloodExpiryAt)); err != nil {
		t.Fatalf("START: %v", err)
	}
	if len(combat.closes) != 0 {
		t.Fatalf("closed without an attempt: %+v", combat.closes)
	}
	if len(combat.requests) != 1 {
		t.Fatalf("captured %d START requests, want one", len(combat.requests))
	}
}

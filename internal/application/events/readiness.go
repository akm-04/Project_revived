package events

import (
	"context"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/events"
)

// Readiness states of an events.definition.list row (EA-13).
const (
	ReadinessReady                = "READY"
	ReadinessHookUnbuilt          = "HOOK_UNBUILT"
	ReadinessClientContentMissing = "CLIENT_CONTENT_MISSING"
	ReadinessSyncConflict         = "SYNC_CONFLICT"
)

// Readiness is the one scheduling gate. events.schedule refuses exactly when
// State is not READY, and events.definition.list reports the same state.
type Readiness struct {
	State        string
	MissingPaths []string
	refusal      *operator.Refusal
}

// Refusal is the schedule refusal of a non-READY state, nil when READY.
func (readiness Readiness) Refusal() *operator.Refusal { return readiness.refusal }

// EvaluateReadiness is the only copy of the hook and OTA coverage gate.
func EvaluateReadiness(ctx context.Context, definition events.Definition, hooks HookRegistry, coverage Coverage) (Readiness, error) {
	if refusal := hookGate(definition, hooks); refusal != nil {
		return Readiness{State: ReadinessHookUnbuilt, refusal: refusal}, nil
	}
	if coverage == nil {
		return Readiness{}, ErrUnavailable
	}
	covered, err := coverage.Covers(ctx, definition.ClientRequirements.CoversRequest())
	if err != nil {
		return Readiness{}, err
	}
	if refusal := coverageGate(covered); refusal != nil {
		return Readiness{State: ReadinessClientContentMissing, MissingPaths: covered.MissingClientPaths, refusal: refusal}, nil
	}
	return Readiness{State: ReadinessReady}, nil
}

package audit

import (
	"context"
	"errors"
	"time"
)

// Event is a sanitized security/operator audit fact. Durable operator audit
// storage is internal/adapters/postgres/auditstore; this port cannot authorize writes.
type Event struct {
	OccurredAt    time.Time
	ActorKind     string
	ActorID       string
	Action        string
	TargetKind    string
	TargetKey     string
	Outcome       string
	ReasonCode    string
	CorrelationID string
	PolicyVersion string
}

func (e Event) Validate() error {
	if e.OccurredAt.IsZero() || e.ActorKind == "" || e.Action == "" || e.Outcome == "" {
		return errors.New("invalid audit event")
	}
	return nil
}

type Emitter interface{ Emit(context.Context, Event) }
type NopEmitter struct{}

func (NopEmitter) Emit(context.Context, Event) {}

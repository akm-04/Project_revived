package generation

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/foundation/operation"
)

var ErrInvalidTimedOperation = errors.New("invalid timed operation")

// TimeAuthority supplies the authoritative instant used by durable I6A temporal
// decisions. Production is backed by PostgreSQL time; process wall clock is not
// an implementation of this port.
type TimeAuthority interface {
	Now(context.Context) (time.Time, error)
}

// TimedOperation binds one existing semantic operation to one authoritative
// durable-decision instant. Fields are private so retry code cannot resample or
// mutate the binding accidentally.
type TimedOperation struct {
	operation  operation.Context
	decisionAt time.Time
}

func NewTimedOperation(op operation.Context, decisionAt time.Time) (TimedOperation, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() || decisionAt.IsZero() {
		return TimedOperation{}, ErrInvalidTimedOperation
	}
	out := TimedOperation{operation: op, decisionAt: decisionAt.UTC()}
	if err := out.Validate(); err != nil {
		return TimedOperation{}, err
	}
	return out, nil
}

func (t TimedOperation) Validate() error {
	if t.operation.ID.IsZero() || t.operation.StartedAt.IsZero() || t.decisionAt.IsZero() || t.decisionAt.Location() != time.UTC {
		return ErrInvalidTimedOperation
	}
	return nil
}

// Operation returns the unchanged semantic operation context. In particular,
// StartedAt retains its pre-I6 transport/receipt meaning.
func (t TimedOperation) Operation() operation.Context { return t.operation }
func (t TimedOperation) DecisionAt() time.Time        { return t.decisionAt }

// Binder samples authoritative time exactly once before an owner transaction
// retry loop. Callers pass the returned TimedOperation unchanged to every retry
// and any unknown-COMMIT reconciliation.
type Binder struct{ Time TimeAuthority }

func (b Binder) Bind(ctx context.Context, op operation.Context) (TimedOperation, error) {
	if b.Time == nil {
		return TimedOperation{}, errors.New("nil durable time authority")
	}
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return TimedOperation{}, ErrInvalidTimedOperation
	}
	decisionAt, err := b.Time.Now(ctx)
	if err != nil {
		return TimedOperation{}, err
	}
	return NewTimedOperation(op, decisionAt)
}

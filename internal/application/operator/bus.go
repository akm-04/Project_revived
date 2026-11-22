package operator

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrUnavailable = errors.New("operator: unavailable")

// Record is one operator_commands row.
type Record struct {
	SemanticKey   string
	ModuleCommand string
	PayloadSHA256 string
	Principal     string
	Role          string
	Scope         string
	Reason        string
	State         string
	Result        json.RawMessage
	CreatedAt     time.Time
	FinishedAt    *time.Time
}

// Store is the operator_commands port. ClaimTx locks the key's row first (the
// bus lock order: the command row before any owner lock): it inserts an
// ACCEPTED row, or returns the existing row locked FOR UPDATE.
type Store interface {
	ClaimTx(ctx context.Context, transaction tx.Tx, command Command, at time.Time) (existing *Record, err error)
	// RetryFailedTx turns a FAILED row with the same payload back to ACCEPTED.
	RetryFailedTx(ctx context.Context, transaction tx.Tx, semanticKey string) error
	FinishTx(ctx context.Context, transaction tx.Tx, semanticKey, state string, result json.RawMessage, at time.Time) error
	ReadTx(ctx context.Context, query tx.Queryer, semanticKey string) (*Record, error)
}

// Handler applies one command inside the bus transaction and returns the typed
// result. Returning a *Refusal records REFUSED and commits nothing else.
type Handler func(ctx context.Context, scope tx.Scope, command Command) (any, error)

// Outcome is what the edge answers: the stored state and result. Replayed is
// true when the semantic key had already finished with the same payload.
type Outcome struct {
	State    string
	Result   json.RawMessage
	Replayed bool
}

type Bus struct {
	Runner   tx.Runner
	Clock    clock.Clock
	Store    Store
	Handlers map[string]Handler
}

func profile() tx.Profile {
	return tx.Profile{Name: "operator-command", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 20 * time.Second, TransactionTimeout: 60 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 120 * time.Second}
}

func retryPolicy() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 16, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}
}

// Execute runs one command: claim the key, call the owner, store the result,
// all in one serializable transaction. A handler error that is not a Refusal
// rolls everything back and is recorded as FAILED in its own transaction; the
// same key with the same payload may then be retried.
func (bus Bus) Execute(ctx context.Context, command Command) (Outcome, error) {
	if bus.Runner.DB == nil || bus.Clock == nil || bus.Store == nil {
		return Outcome{}, ErrUnavailable
	}
	handler, registered := bus.Handlers[command.ModuleCommand]
	if !registered {
		return Outcome{}, Refuse(CodeUnknownCommand, "unknown command", nil)
	}
	current, err := (operation.Factory{Clock: bus.Clock}).New(policy.Set{})
	if err != nil {
		return Outcome{}, err
	}
	var outcome Outcome
	var handlerErr error
	_, err = bus.Runner.Run(ctx, current, profile(), tx.Options{Isolation: tx.Serializable}, retryPolicy(), resolver{bus, command}, func(ctx context.Context, scope tx.Scope) error {
		outcome, handlerErr = Outcome{}, nil
		existing, err := bus.Store.ClaimTx(ctx, scope.Tx, command, current.StartedAt)
		if err != nil {
			return err
		}
		if existing != nil {
			replay, done, err := bus.settleExisting(ctx, scope.Tx, command, *existing)
			if done || err != nil {
				outcome = replay
				return err
			}
		}
		result, err := handler(ctx, scope, command)
		var refusal *Refusal
		state := StateApplied
		switch {
		case errors.As(err, &refusal):
			state, result = StateRefused, refusal
		case err != nil:
			handlerErr = err
			return err
		}
		encoded, err := json.Marshal(result)
		if err != nil {
			return err
		}
		if err := bus.Store.FinishTx(ctx, scope.Tx, command.Envelope.SemanticKey, state, encoded, bus.Clock.Now().UTC()); err != nil {
			return err
		}
		outcome = Outcome{State: state, Result: encoded}
		return nil
	})
	if handlerErr != nil && errors.Is(err, handlerErr) && !tx.IsDefiniteAbortError(err) {
		bus.recordFailure(ctx, command, handlerErr)
		return Outcome{}, handlerErr
	}
	if err != nil {
		return Outcome{}, err
	}
	return outcome, nil
}

// settleExisting answers a key that already has a row. done is false only when
// a FAILED row with the same payload was reopened for this retry.
func (bus Bus) settleExisting(ctx context.Context, transaction tx.Tx, command Command, existing Record) (Outcome, bool, error) {
	if existing.ModuleCommand != command.ModuleCommand || existing.PayloadSHA256 != command.PayloadSHA256 {
		return Outcome{}, true, Refuse(CodeKeyReused, "this semantic key was used with another command or payload", nil)
	}
	switch existing.State {
	case StateApplied, StateRefused:
		return Outcome{State: existing.State, Result: existing.Result, Replayed: true}, true, nil
	case StateFailed:
		return Outcome{}, false, bus.Store.RetryFailedTx(ctx, transaction, command.Envelope.SemanticKey)
	}
	// ACCEPTED rows exist only inside an open transaction; seeing one committed is a defect.
	return Outcome{}, true, errors.New("operator: command row left ACCEPTED")
}

func (bus Bus) recordFailure(ctx context.Context, command Command, cause error) {
	current, err := (operation.Factory{Clock: bus.Clock}).New(policy.Set{})
	if err != nil {
		return
	}
	detail, _ := json.Marshal(map[string]string{"error": cause.Error()})
	// Best effort: the command already failed; a lost FAILED row only loses its audit line.
	_, _ = bus.Runner.Run(ctx, current, profile(), tx.Options{Isolation: tx.Serializable}, retryPolicy(), nil, func(ctx context.Context, scope tx.Scope) error {
		existing, err := bus.Store.ClaimTx(ctx, scope.Tx, command, current.StartedAt)
		if err != nil || (existing != nil && existing.State != StateFailed) {
			return err
		}
		return bus.Store.FinishTx(ctx, scope.Tx, command.Envelope.SemanticKey, StateFailed, detail, bus.Clock.Now().UTC())
	})
}

// resolver settles an unknown commit by the key's row: a finished row with the
// same payload proves the commit.
type resolver struct {
	bus     Bus
	command Command
}

func (r resolver) Resolve(ctx context.Context, request tx.ResolutionRequest) (tx.Resolution, error) {
	var record *Record
	result, err := r.bus.Runner.Run(ctx, request.Operation, profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		var err error
		record, err = r.bus.Store.ReadTx(ctx, scope.Tx, r.command.Envelope.SemanticKey)
		return err
	})
	if err != nil || result.Outcome != tx.DefiniteCommit {
		return tx.Resolution{}, err
	}
	finished := record != nil && (record.State == StateApplied || record.State == StateRefused)
	if !finished || record.PayloadSHA256 != r.command.PayloadSHA256 || record.ModuleCommand != r.command.ModuleCommand {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: Outcome{State: record.State, Result: record.Result}}, nil
}

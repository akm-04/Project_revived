package tx

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/foundation/operation"
)

type Isolation uint8

const (
	ReadCommitted Isolation = iota + 1
	RepeatableRead
	Serializable
)

func (i Isolation) String() string {
	switch i {
	case ReadCommitted:
		return "read_committed"
	case RepeatableRead:
		return "repeatable_read"
	case Serializable:
		return "serializable"
	default:
		return "unknown"
	}
}

type Options struct {
	Isolation Isolation
	ReadOnly  bool
}

type CommandTag interface{ RowsAffected() int64 }
type Row interface{ Scan(dest ...any) error }
type Queryer interface {
	QueryRow(context.Context, string, ...any) Row
}
type Execer interface {
	Exec(context.Context, string, ...any) (CommandTag, error)
}
type Tx interface {
	Queryer
	Execer
	Commit(context.Context) error
	Rollback(context.Context) error
}
type Beginner interface {
	Begin(context.Context, Options) (Tx, error)
}

type Profile struct {
	Name               string
	AcquireTimeout     time.Duration
	LockTimeout        time.Duration
	StatementTimeout   time.Duration
	TransactionTimeout time.Duration
	CleanupTimeout     time.Duration
	ReconcileTimeout   time.Duration
	OperationTimeout   time.Duration
}

func (p Profile) Validate() error {
	if p.Name == "" {
		return errors.New("transaction profile name is required")
	}
	vals := []time.Duration{p.AcquireTimeout, p.LockTimeout, p.StatementTimeout, p.TransactionTimeout, p.CleanupTimeout, p.ReconcileTimeout, p.OperationTimeout}
	for _, v := range vals {
		if v <= 0 {
			return fmt.Errorf("transaction profile %s requires finite positive durations", p.Name)
		}
	}
	if p.AcquireTimeout >= p.OperationTimeout {
		return fmt.Errorf("acquire timeout must be inside operation timeout")
	}
	if p.TransactionTimeout > p.OperationTimeout {
		return fmt.Errorf("transaction timeout must be <= operation timeout")
	}
	if p.LockTimeout > p.TransactionTimeout || p.StatementTimeout > p.TransactionTimeout {
		return fmt.Errorf("lock/statement timeout must be <= transaction timeout")
	}
	return nil
}

type RetryPolicy struct {
	MaxAttempts                           int
	RetryDefiniteAbort                    bool
	AllowReplayAfterAuthoritativeNegative bool
}

func (p RetryPolicy) validate() error {
	if p.MaxAttempts < 1 {
		return errors.New("MaxAttempts must be >= 1")
	}
	return nil
}

type Scope struct {
	Tx        Tx
	Operation operation.Context
	Attempt   int
}
type Body func(context.Context, Scope) error

type CommitOutcome uint8

const (
	OutcomeNone CommitOutcome = iota
	DefiniteAbort
	DefiniteCommit
	UnknownCommitOutcome
)

func (o CommitOutcome) String() string {
	switch o {
	case DefiniteAbort:
		return "definite_abort"
	case DefiniteCommit:
		return "definite_commit"
	case UnknownCommitOutcome:
		return "unknown_commit_outcome"
	default:
		return "none"
	}
}

type ResolutionState uint8

const (
	ResolutionUnknown ResolutionState = iota
	ResolutionCommitted
	// ResolutionAbsent is not a generic "receipt not found" state. It means an
	// operation-specific terminal/owner fence authoritatively proves that the
	// ambiguous transaction cannot later become visible.
	ResolutionAbsent
)

type Resolution struct {
	State    ResolutionState
	Evidence any
}
type ResolutionRequest struct {
	Operation   operation.Context
	CommitError error
	Attempt     int
}
type UnknownCommitResolver interface {
	Resolve(context.Context, ResolutionRequest) (Resolution, error)
}

type Reconciliation struct {
	Attempt  int
	State    ResolutionState
	Evidence any
}

type Result struct {
	Outcome         CommitOutcome
	Attempts        int
	Reconciled      bool
	Evidence        any
	Reconciliations []Reconciliation
}

type UnknownCommitError struct {
	Cause           error
	ResolutionError error
}

func (e *UnknownCommitError) Error() string {
	if e.ResolutionError != nil {
		return fmt.Sprintf("unknown commit outcome: %v (reconciliation: %v)", e.Cause, e.ResolutionError)
	}
	return fmt.Sprintf("unknown commit outcome: %v", e.Cause)
}
func (e *UnknownCommitError) Unwrap() error { return e.Cause }

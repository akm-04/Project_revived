package generation

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrInvalidTimedRunner  = errors.New("invalid timed transaction runner")
	ErrTimedOperationDrift = errors.New("timed operation drift")
)

// TimedScope is the application transaction scope for I6A durable temporal
// decisions. The TimedOperation is bound once before tx.Runner enters its retry
// loop and is reused unchanged for every definite-abort retry.
type TimedScope struct {
	Tx        tx.Tx
	Operation TimedOperation
	Attempt   int
}

type TimedBody func(context.Context, TimedScope) error

// TimedResolutionRequest carries the exact same retry-stable TimedOperation to
// UNKNOWN-COMMIT reconciliation. A resolver still must obey the foundation
// contract: generic absence is not replay authorization.
type TimedResolutionRequest struct {
	Operation   TimedOperation
	CommitError error
	Attempt     int
}

type TimedUnknownCommitResolver interface {
	ResolveTimed(context.Context, TimedResolutionRequest) (tx.Resolution, error)
}

// TimedRunner composes I6A authoritative decision-time binding with the
// accepted foundation tx.Runner. It does not change tx retry/UNKNOWN-COMMIT
// semantics; it only makes decision-time stability structural.
type TimedRunner struct {
	Binder Binder
	Runner tx.Runner
}

// Run binds database-authoritative decision time exactly once before any owner
// transaction begins. The returned TimedOperation is the exact binding used by
// all body attempts and any UNKNOWN-COMMIT resolver invocation.
func (r TimedRunner) Run(
	ctx context.Context,
	op operation.Context,
	profile tx.Profile,
	opts tx.Options,
	retry tx.RetryPolicy,
	resolver TimedUnknownCommitResolver,
	body TimedBody,
) (TimedOperation, tx.Result, error) {
	if body == nil {
		return TimedOperation{}, tx.Result{}, ErrInvalidTimedRunner
	}
	timed, err := r.Binder.Bind(ctx, op)
	if err != nil {
		return TimedOperation{}, tx.Result{}, err
	}

	var foundationResolver tx.UnknownCommitResolver
	if resolver != nil {
		foundationResolver = timedResolverAdapter{timed: timed, inner: resolver}
	}

	res, err := r.Runner.Run(ctx, timed.Operation(), profile, opts, retry, foundationResolver, func(txctx context.Context, scope tx.Scope) error {
		if !sameOperation(scope.Operation, timed.Operation()) {
			return ErrTimedOperationDrift
		}
		return body(txctx, TimedScope{Tx: scope.Tx, Operation: timed, Attempt: scope.Attempt})
	})
	return timed, res, err
}

type timedResolverAdapter struct {
	timed TimedOperation
	inner TimedUnknownCommitResolver
}

func (a timedResolverAdapter) Resolve(ctx context.Context, req tx.ResolutionRequest) (tx.Resolution, error) {
	if a.inner == nil || !sameOperation(req.Operation, a.timed.Operation()) {
		return tx.Resolution{}, ErrTimedOperationDrift
	}
	return a.inner.ResolveTimed(ctx, TimedResolutionRequest{
		Operation:   a.timed,
		CommitError: req.CommitError,
		Attempt:     req.Attempt,
	})
}

func sameOperation(a, b operation.Context) bool {
	return a.ID == b.ID &&
		a.StartedAt.Equal(b.StartedAt) &&
		a.EntropySeed == b.EntropySeed &&
		a.Policies.Equal(b.Policies)
}

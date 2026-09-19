package tx

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/foundation/operation"
)

type Runner struct {
	DB        Beginner
	Admission Admission
	Hooks     Hooks
}

func (r Runner) Run(ctx context.Context, op operation.Context, profile Profile, opts Options, retry RetryPolicy, resolver UnknownCommitResolver, body Body) (Result, error) {
	if r.DB == nil {
		return Result{}, errors.New("nil transaction beginner")
	}
	if r.Admission == nil {
		r.Admission = NoopAdmission{}
	}
	if r.Hooks == nil {
		r.Hooks = NopHooks{}
	}
	if body == nil {
		return Result{}, errors.New("nil transaction body")
	}
	if err := profile.Validate(); err != nil {
		return Result{}, err
	}
	if err := retry.validate(); err != nil {
		return Result{}, err
	}
	opCtx, cancel := withMaxTimeout(ctx, profile.OperationTimeout)
	defer cancel()
	var reconciliationHistory []Reconciliation
	for attempt := 1; attempt <= retry.MaxAttempts; attempt++ {
		res, action, err := r.attempt(opCtx, op, attempt, profile, opts, retry, resolver, body)
		if len(res.Reconciliations) > 0 {
			reconciliationHistory = append(reconciliationHistory, res.Reconciliations...)
		}
		if action == actionRetry {
			continue
		}
		if len(reconciliationHistory) > 0 {
			res.Reconciled = true
			res.Reconciliations = append([]Reconciliation(nil), reconciliationHistory...)
			if res.Evidence == nil {
				res.Evidence = reconciliationHistory[len(reconciliationHistory)-1].Evidence
			}
		}
		return res, err
	}
	res := Result{Outcome: DefiniteAbort, Attempts: retry.MaxAttempts}
	if len(reconciliationHistory) > 0 {
		res.Reconciled = true
		res.Reconciliations = append([]Reconciliation(nil), reconciliationHistory...)
		res.Evidence = reconciliationHistory[len(reconciliationHistory)-1].Evidence
	}
	return res, errors.New("transaction retry budget exhausted")
}

type nextAction uint8

const (
	actionReturn nextAction = iota
	actionRetry
)

func (r Runner) attempt(ctx context.Context, op operation.Context, attempt int, profile Profile, opts Options, retry RetryPolicy, resolver UnknownCommitResolver, body Body) (Result, nextAction, error) {
	started := time.Now()
	acquireCtx, acqCancel := context.WithTimeout(ctx, profile.AcquireTimeout)
	release, err := r.Admission.Acquire(acquireCtx)
	if err != nil {
		acqCancel()
		r.event(op, profile, attempt, "admission", OutcomeNone, err, time.Since(started))
		return Result{Attempts: attempt}, actionReturn, err
	}
	defer release()
	dbtx, err := r.DB.Begin(acquireCtx, opts)
	acqCancel()
	if err != nil {
		r.event(op, profile, attempt, "begin", OutcomeNone, err, time.Since(started))
		return Result{Attempts: attempt}, actionReturn, err
	}
	// Every transaction handle obtained from Begin must be finalized exactly as
	// far as the driver lets us. This defer is installed immediately after Begin
	// so panic/error/cancellation paths cannot strand a pooled transaction. A
	// failed Commit remains semantically UNKNOWN even if this later cleanup
	// rollback succeeds; cleanup never rewrites the commit outcome.
	finalizer := transactionFinalizer{profile: profile, tx: dbtx}
	defer finalizer.finish()

	txCtx, txCancel := withMaxTimeout(ctx, profile.TransactionTimeout)
	defer txCancel()
	if err = applyTimeouts(txCtx, dbtx, profile); err != nil {
		_ = finalizer.rollback()
		outcome := DefiniteAbort
		r.event(op, profile, attempt, "configure", outcome, err, time.Since(started))
		if IsDefiniteAbortError(err) && retry.RetryDefiniteAbort && attempt < retry.MaxAttempts {
			return Result{Outcome: outcome, Attempts: attempt}, actionRetry, nil
		}
		return Result{Outcome: outcome, Attempts: attempt}, actionReturn, err
	}
	if err = body(txCtx, Scope{Tx: dbtx, Operation: op, Attempt: attempt}); err != nil {
		_ = finalizer.rollback()
		r.event(op, profile, attempt, "body", DefiniteAbort, err, time.Since(started))
		if IsDefiniteAbortError(err) && retry.RetryDefiniteAbort && attempt < retry.MaxAttempts {
			return Result{Outcome: DefiniteAbort, Attempts: attempt}, actionRetry, nil
		}
		return Result{Outcome: DefiniteAbort, Attempts: attempt}, actionReturn, err
	}
	// Commit is attempted once. A transport error at this boundary is never an
	// ordinary retry signal.
	err = dbtx.Commit(txCtx)
	if err == nil {
		finalizer.markFinalized()
		r.event(op, profile, attempt, "commit", DefiniteCommit, nil, time.Since(started))
		return Result{Outcome: DefiniteCommit, Attempts: attempt}, actionReturn, nil
	}
	if IsDefiniteAbortError(err) {
		r.event(op, profile, attempt, "commit", DefiniteAbort, err, time.Since(started))
		if retry.RetryDefiniteAbort && attempt < retry.MaxAttempts {
			return Result{Outcome: DefiniteAbort, Attempts: attempt}, actionRetry, nil
		}
		return Result{Outcome: DefiniteAbort, Attempts: attempt}, actionReturn, err
	}
	// Any other Commit error is conservatively ambiguous. Never call body again
	// before a strong fresh-connection resolver proves committed or absent.
	if resolver == nil {
		u := &UnknownCommitError{Cause: err}
		r.event(op, profile, attempt, "commit", UnknownCommitOutcome, u, time.Since(started))
		return Result{Outcome: UnknownCommitOutcome, Attempts: attempt}, actionReturn, u
	}
	reconcileCtx, reconcileCancel := context.WithTimeout(context.WithoutCancel(ctx), profile.ReconcileTimeout)
	resolution, rerr := resolver.Resolve(reconcileCtx, ResolutionRequest{Operation: op, CommitError: err, Attempt: attempt})
	reconcileCancel()
	if rerr != nil {
		u := &UnknownCommitError{Cause: err, ResolutionError: rerr}
		r.event(op, profile, attempt, "reconcile", UnknownCommitOutcome, u, time.Since(started))
		return Result{Outcome: UnknownCommitOutcome, Attempts: attempt}, actionReturn, u
	}
	switch resolution.State {
	case ResolutionCommitted:
		r.event(op, profile, attempt, "reconcile", DefiniteCommit, nil, time.Since(started))
		return Result{Outcome: DefiniteCommit, Attempts: attempt, Reconciled: true, Evidence: resolution.Evidence, Reconciliations: []Reconciliation{{Attempt: attempt, State: ResolutionCommitted, Evidence: resolution.Evidence}}}, actionReturn, nil
	case ResolutionAbsent:
		if retry.AllowReplayAfterAuthoritativeNegative && attempt < retry.MaxAttempts {
			r.event(op, profile, attempt, "reconcile_absent", DefiniteAbort, nil, time.Since(started))
			return Result{Outcome: DefiniteAbort, Attempts: attempt, Reconciled: true, Evidence: resolution.Evidence, Reconciliations: []Reconciliation{{Attempt: attempt, State: ResolutionAbsent, Evidence: resolution.Evidence}}}, actionRetry, nil
		}
		u := &UnknownCommitError{Cause: fmt.Errorf("%w; authoritative absence is not replay authorization", err)}
		r.event(op, profile, attempt, "reconcile_absent", UnknownCommitOutcome, u, time.Since(started))
		return Result{Outcome: UnknownCommitOutcome, Attempts: attempt, Reconciled: true, Evidence: resolution.Evidence, Reconciliations: []Reconciliation{{Attempt: attempt, State: ResolutionAbsent, Evidence: resolution.Evidence}}}, actionReturn, u
	default:
		u := &UnknownCommitError{Cause: err}
		r.event(op, profile, attempt, "reconcile_unknown", UnknownCommitOutcome, u, time.Since(started))
		return Result{Outcome: UnknownCommitOutcome, Attempts: attempt}, actionReturn, u
	}
}

func applyTimeouts(ctx context.Context, t Tx, p Profile) error {
	settings := [][2]string{{"lock_timeout", pgDuration(p.LockTimeout)}, {"statement_timeout", pgDuration(p.StatementTimeout)}, {"transaction_timeout", pgDuration(p.TransactionTimeout)}}
	for _, s := range settings {
		if _, err := t.Exec(ctx, "SELECT set_config($1, $2, true)", s[0], s[1]); err != nil {
			return err
		}
	}
	return nil
}
func pgDuration(d time.Duration) string {
	ms := d.Milliseconds()
	if ms < 1 {
		ms = 1
	}
	return fmt.Sprintf("%dms", ms)
}

type transactionFinalizer struct {
	profile   Profile
	tx        Tx
	finalized bool
}

func (f *transactionFinalizer) markFinalized() { f.finalized = true }

func (f *transactionFinalizer) rollback() error {
	if f.finalized || f.tx == nil {
		return nil
	}
	// Cleanup must not inherit caller cancellation. It is deliberately bounded
	// by the profile so a broken driver cannot strand the request forever.
	ctx, cancel := context.WithTimeout(context.Background(), f.profile.CleanupTimeout)
	defer cancel()
	err := f.tx.Rollback(ctx)
	if err == nil {
		f.finalized = true
	}
	return err
}

func (f *transactionFinalizer) finish() {
	if !f.finalized {
		_ = f.rollback()
	}
}
func withMaxTimeout(parent context.Context, d time.Duration) (context.Context, context.CancelFunc) {
	if deadline, ok := parent.Deadline(); ok && time.Until(deadline) <= d {
		return context.WithCancel(parent)
	}
	return context.WithTimeout(parent, d)
}
func (r Runner) event(op operation.Context, p Profile, a int, phase string, out CommitOutcome, err error, d time.Duration) {
	state := ""
	if err != nil {
		state = SQLState(err)
	}
	r.Hooks.OnEvent(Event{Operation: op, Profile: p.Name, Attempt: a, Phase: phase, Outcome: out, SQLState: state, Duration: d})
}

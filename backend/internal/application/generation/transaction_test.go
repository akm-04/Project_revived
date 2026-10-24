package generation

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type timedStateErr string

func (e timedStateErr) Error() string    { return string(e) }
func (e timedStateErr) SQLState() string { return string(e) }

type timedTag int64

func (t timedTag) RowsAffected() int64 { return int64(t) }

type timedRow struct{}

func (timedRow) Scan(...any) error { return nil }

type timedFakeTx struct {
	commitErr     error
	rollbackCount int
}

func (f *timedFakeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return timedTag(1), nil
}
func (f *timedFakeTx) QueryRow(context.Context, string, ...any) tx.Row { return timedRow{} }
func (f *timedFakeTx) Commit(context.Context) error                    { return f.commitErr }
func (f *timedFakeTx) Rollback(context.Context) error {
	f.rollbackCount++
	return nil
}

type timedFakeDB struct {
	mu  sync.Mutex
	txs []*timedFakeTx
	n   int
}

func (d *timedFakeDB) Begin(context.Context, tx.Options) (tx.Tx, error) {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.n >= len(d.txs) {
		return nil, errors.New("unexpected transaction begin")
	}
	out := d.txs[d.n]
	d.n++
	return out, nil
}

type timedResolver struct {
	states   []tx.ResolutionState
	requests []TimedResolutionRequest
}

func (r *timedResolver) ResolveTimed(_ context.Context, req TimedResolutionRequest) (tx.Resolution, error) {
	r.requests = append(r.requests, req)
	if len(r.requests) > len(r.states) {
		return tx.Resolution{}, errors.New("unexpected resolution")
	}
	return tx.Resolution{State: r.states[len(r.requests)-1], Evidence: "timed-proof"}, nil
}

func timedProfile() tx.Profile {
	return tx.Profile{
		Name: "I6A_TEST", AcquireTimeout: time.Second, LockTimeout: time.Second,
		StatementTimeout: time.Second, TransactionTimeout: 2 * time.Second,
		CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: 3 * time.Second,
	}
}

func TestTimedRunnerDefiniteAbortRetryReusesOneDecisionBinding(t *testing.T) {
	decision := time.Unix(900, 123).UTC()
	authority := &fakeTimeAuthority{at: decision}
	db := &timedFakeDB{txs: []*timedFakeTx{{}, {}}}
	runner := TimedRunner{Binder: Binder{Time: authority}, Runner: tx.Runner{DB: db}}

	var first TimedOperation
	calls := 0
	bound, res, err := runner.Run(context.Background(), opFixture(), timedProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 2, RetryDefiniteAbort: true}, nil, func(_ context.Context, scope TimedScope) error {
		calls++
		if calls == 1 {
			first = scope.Operation
			return timedStateErr("40001")
		}
		if !sameOperation(scope.Operation.Operation(), first.Operation()) || scope.Operation.DecisionAt() != first.DecisionAt() {
			t.Fatal("timed operation changed across definite-abort retry")
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if authority.calls != 1 || calls != 2 || res.Attempts != 2 || res.Outcome != tx.DefiniteCommit {
		t.Fatalf("authority=%d body=%d res=%+v", authority.calls, calls, res)
	}
	if bound.DecisionAt() != decision || !sameOperation(bound.Operation(), opFixture()) {
		t.Fatalf("returned binding drifted: %#v", bound)
	}
	if db.txs[0].rollbackCount != 1 {
		t.Fatalf("first definite-abort transaction rollback count=%d", db.txs[0].rollbackCount)
	}
}

func TestTimedRunnerUnknownCommitResolverReceivesSameBindingAndDoesNotBlindReplay(t *testing.T) {
	decision := time.Unix(901, 0).UTC()
	authority := &fakeTimeAuthority{at: decision}
	db := &timedFakeDB{txs: []*timedFakeTx{{commitErr: errors.New("lost commit ack")}}}
	resolver := &timedResolver{states: []tx.ResolutionState{tx.ResolutionCommitted}}
	runner := TimedRunner{Binder: Binder{Time: authority}, Runner: tx.Runner{DB: db}}

	bodyCalls := 0
	bound, res, err := runner.Run(context.Background(), opFixture(), timedProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, resolver, func(_ context.Context, scope TimedScope) error {
		bodyCalls++
		if scope.Operation.DecisionAt() != decision {
			t.Fatal("body did not receive bound authoritative time")
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if bodyCalls != 1 || authority.calls != 1 || len(resolver.requests) != 1 {
		t.Fatalf("body=%d authority=%d resolutions=%d", bodyCalls, authority.calls, len(resolver.requests))
	}
	req := resolver.requests[0]
	if req.Attempt != 1 || req.Operation.DecisionAt() != decision || !sameOperation(req.Operation.Operation(), bound.Operation()) {
		t.Fatalf("resolver binding drift: %#v", req)
	}
	if !res.Reconciled || res.Outcome != tx.DefiniteCommit || res.Evidence != "timed-proof" {
		t.Fatalf("res=%+v", res)
	}
}

func TestTimedRunnerAuthoritativeNegativeReplayStillReusesOriginalDecision(t *testing.T) {
	decision := time.Unix(902, 0).UTC()
	authority := &fakeTimeAuthority{at: decision}
	db := &timedFakeDB{txs: []*timedFakeTx{{commitErr: errors.New("lost commit ack")}, {}}}
	resolver := &timedResolver{states: []tx.ResolutionState{tx.ResolutionAbsent}}
	runner := TimedRunner{Binder: Binder{Time: authority}, Runner: tx.Runner{DB: db}}

	bodyCalls := 0
	_, res, err := runner.Run(context.Background(), opFixture(), timedProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 2, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, resolver, func(_ context.Context, scope TimedScope) error {
		bodyCalls++
		if scope.Operation.DecisionAt() != decision {
			t.Fatalf("attempt %d resampled decision time: %v", scope.Attempt, scope.Operation.DecisionAt())
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if bodyCalls != 2 || authority.calls != 1 || db.n != 2 {
		t.Fatalf("body=%d authority=%d begins=%d", bodyCalls, authority.calls, db.n)
	}
	if res.Outcome != tx.DefiniteCommit || !res.Reconciled || len(res.Reconciliations) != 1 || res.Reconciliations[0].State != tx.ResolutionAbsent {
		t.Fatalf("res=%+v", res)
	}
}

func TestTimedRunnerResolutionUnknownNeverReplays(t *testing.T) {
	authority := &fakeTimeAuthority{at: time.Unix(903, 0).UTC()}
	db := &timedFakeDB{txs: []*timedFakeTx{{commitErr: errors.New("lost commit ack")}, {}}}
	resolver := &timedResolver{states: []tx.ResolutionState{tx.ResolutionUnknown}}
	bodyCalls := 0
	_, res, err := (TimedRunner{Binder: Binder{Time: authority}, Runner: tx.Runner{DB: db}}).Run(context.Background(), opFixture(), timedProfile(), tx.Options{}, tx.RetryPolicy{MaxAttempts: 2, AllowReplayAfterAuthoritativeNegative: true}, resolver, func(context.Context, TimedScope) error {
		bodyCalls++
		return nil
	})
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) || res.Outcome != tx.UnknownCommitOutcome {
		t.Fatalf("res=%+v err=%v", res, err)
	}
	if bodyCalls != 1 || db.n != 1 || authority.calls != 1 {
		t.Fatalf("blind replay/time resample: body=%d begins=%d authority=%d", bodyCalls, db.n, authority.calls)
	}
}

func TestTimedRunnerAndBinderFailBeforeSideEffectsForInvalidInput(t *testing.T) {
	authority := &fakeTimeAuthority{at: time.Unix(904, 0).UTC()}
	badOp := operation.Context{}
	if _, err := (Binder{Time: authority}).Bind(context.Background(), badOp); !errors.Is(err, ErrInvalidTimedOperation) {
		t.Fatalf("invalid op got %v", err)
	}
	if authority.calls != 0 {
		t.Fatalf("invalid operation queried authoritative time %d times", authority.calls)
	}

	if _, _, err := (TimedRunner{Binder: Binder{Time: authority}}).Run(context.Background(), opFixture(), timedProfile(), tx.Options{}, tx.RetryPolicy{MaxAttempts: 1}, nil, nil); !errors.Is(err, ErrInvalidTimedRunner) {
		t.Fatalf("nil body got %v", err)
	}
	if authority.calls != 0 {
		t.Fatalf("nil body queried authoritative time %d times", authority.calls)
	}
}

func TestTimedRunnerForwardsFoundationOptionsWitness(t *testing.T) {
	authority := &fakeTimeAuthority{at: time.Unix(905, 0).UTC()}
	db := &timedFakeDB{txs: []*timedFakeTx{{}}}
	runner := TimedRunner{Binder: Binder{Time: authority}, Runner: tx.Runner{DB: db}}
	want := tx.Options{Isolation: tx.Serializable, ReadOnly: true}
	_, _, err := runner.Run(context.Background(), opFixture(), timedProfile(), want, tx.RetryPolicy{MaxAttempts: 1}, nil, func(_ context.Context, scope TimedScope) error {
		if scope.Options != want {
			t.Fatalf("options=%+v want=%+v", scope.Options, want)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

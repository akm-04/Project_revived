package tx

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type stateErr string

func (e stateErr) Error() string    { return string(e) }
func (e stateErr) SQLState() string { return string(e) }

type tag int64

func (t tag) RowsAffected() int64 { return int64(t) }

type fakeRow struct{}

func (fakeRow) Scan(...any) error { return nil }

type fakeTx struct {
	bodyErr        error
	commitErr      error
	rolled         bool
	rollbackCount  int
	rollbackErr    error
	settings       int
	rollbackCtxErr error
}

func (f *fakeTx) Exec(context.Context, string, ...any) (CommandTag, error) {
	f.settings++
	return tag(1), nil
}
func (f *fakeTx) QueryRow(context.Context, string, ...any) Row { return fakeRow{} }
func (f *fakeTx) Commit(context.Context) error                 { return f.commitErr }
func (f *fakeTx) Rollback(ctx context.Context) error {
	f.rolled = true
	f.rollbackCount++
	f.rollbackCtxErr = ctx.Err()
	return f.rollbackErr
}

type fakeDB struct {
	mu  sync.Mutex
	txs []*fakeTx
	n   int
}

func (d *fakeDB) Begin(context.Context, Options) (Tx, error) {
	d.mu.Lock()
	defer d.mu.Unlock()
	t := d.txs[d.n]
	d.n++
	return t, nil
}

type resolver struct {
	states []ResolutionState
	n      int
}

func (r *resolver) Resolve(context.Context, ResolutionRequest) (Resolution, error) {
	s := r.states[r.n]
	r.n++
	return Resolution{State: s, Evidence: "proof"}, nil
}
func opctx() operation.Context {
	return operation.Context{ID: ids.UUID{1}, StartedAt: time.Unix(1, 0).UTC(), EntropySeed: [32]byte{9}}
}
func profile() Profile {
	return Profile{Name: "NORMAL_WRITE", AcquireTimeout: time.Second, LockTimeout: time.Second, StatementTimeout: time.Second, TransactionTimeout: 2 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: 3 * time.Second}
}

func TestRetryDefiniteAbortKeepsOperationContextStable(t *testing.T) {
	d := &fakeDB{txs: []*fakeTx{{}, {}}}
	calls := 0
	var first [32]byte
	run := Runner{DB: d}
	res, err := run.Run(context.Background(), opctx(), profile(), Options{Isolation: Serializable}, RetryPolicy{MaxAttempts: 2, RetryDefiniteAbort: true}, nil, func(_ context.Context, s Scope) error {
		calls++
		x := s.Operation.Derive("x", 1)
		if calls == 1 {
			first = x
			return stateErr("40001")
		}
		if x != first {
			t.Fatal("entropy changed across retry")
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if res.Outcome != DefiniteCommit || res.Attempts != 2 || calls != 2 {
		t.Fatalf("res=%+v calls=%d", res, calls)
	}
	if !d.txs[0].rolled {
		t.Fatal("first attempt not rolled back")
	}
}
func TestUnknownCommitNeverBlindRetries(t *testing.T) {
	d := &fakeDB{txs: []*fakeTx{{commitErr: errors.New("connection reset")}, {}}}
	calls := 0
	_, err := (Runner{DB: d}).Run(context.Background(), opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 2, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, nil, func(context.Context, Scope) error { calls++; return nil })
	var u *UnknownCommitError
	if !errors.As(err, &u) {
		t.Fatalf("expected unknown commit, got %v", err)
	}
	if calls != 1 {
		t.Fatalf("blind replayed %d times", calls)
	}
}
func TestUnknownCommitReceiptReconciliationCommitted(t *testing.T) {
	d := &fakeDB{txs: []*fakeTx{{commitErr: errors.New("lost ack")}}}
	r := &resolver{states: []ResolutionState{ResolutionCommitted}}
	calls := 0
	res, err := (Runner{DB: d}).Run(context.Background(), opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 2, AllowReplayAfterAuthoritativeNegative: true}, r, func(context.Context, Scope) error { calls++; return nil })
	if err != nil {
		t.Fatal(err)
	}
	if !res.Reconciled || res.Outcome != DefiniteCommit || calls != 1 {
		t.Fatalf("res=%+v calls=%d", res, calls)
	}
}
func TestExplicitAuthoritativeNegativeProofMayReplayWithPolicy(t *testing.T) {
	d := &fakeDB{txs: []*fakeTx{{commitErr: errors.New("lost ack")}, {}}}
	// ResolutionAbsent is reserved for an operation-specific terminal/owner
	// fence. Generic receipt misses return ResolutionUnknown instead.
	r := &resolver{states: []ResolutionState{ResolutionAbsent}}
	calls := 0
	res, err := (Runner{DB: d}).Run(context.Background(), opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 2, AllowReplayAfterAuthoritativeNegative: true}, r, func(context.Context, Scope) error { calls++; return nil })
	if err != nil {
		t.Fatal(err)
	}
	if calls != 2 || res.Outcome != DefiniteCommit {
		t.Fatalf("res=%+v calls=%d", res, calls)
	}
	if !res.Reconciled || len(res.Reconciliations) != 1 || res.Reconciliations[0].State != ResolutionAbsent || res.Reconciliations[0].Attempt != 1 || res.Evidence != "proof" {
		t.Fatalf("reconciliation history lost across authorized retry: %+v", res)
	}
}
func TestBodyFailureRollbackUsesFreshCleanupContext(t *testing.T) {
	ft := &fakeTx{}
	d := &fakeDB{txs: []*fakeTx{ft}}
	ctx, cancel := context.WithCancel(context.Background())
	_, err := (Runner{DB: d}).Run(ctx, opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 1}, nil, func(context.Context, Scope) error { cancel(); return context.Canceled })
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("err=%v", err)
	}
	if !ft.rolled {
		t.Fatal("rollback missing")
	}
	if ft.rollbackCtxErr != nil {
		t.Fatalf("rollback reused canceled ctx: %v", ft.rollbackCtxErr)
	}
}
func TestPanicInBodyFinalizesTransactionAndRethrows(t *testing.T) {
	ft := &fakeTx{}
	d := &fakeDB{txs: []*fakeTx{ft}}
	const sentinel = "boom"
	var recovered any
	func() {
		defer func() { recovered = recover() }()
		_, _ = (Runner{DB: d}).Run(context.Background(), opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 1}, nil, func(context.Context, Scope) error {
			panic(sentinel)
		})
	}()
	if recovered != sentinel {
		t.Fatalf("panic not rethrown: %v", recovered)
	}
	if !ft.rolled || ft.rollbackCount != 1 {
		t.Fatalf("panic path did not finalize transaction: rolled=%v count=%d", ft.rolled, ft.rollbackCount)
	}
	if ft.rollbackCtxErr != nil {
		t.Fatalf("panic cleanup inherited canceled context: %v", ft.rollbackCtxErr)
	}
}

func TestUnknownCommitCleanupCannotRewriteOutcome(t *testing.T) {
	ft := &fakeTx{commitErr: errors.New("lost commit ack")}
	d := &fakeDB{txs: []*fakeTx{ft}}
	res, err := (Runner{DB: d}).Run(context.Background(), opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 1}, nil, func(context.Context, Scope) error { return nil })
	var u *UnknownCommitError
	if !errors.As(err, &u) || res.Outcome != UnknownCommitOutcome {
		t.Fatalf("res=%+v err=%v", res, err)
	}
	if !ft.rolled || ft.rollbackCount != 1 {
		t.Fatalf("unknown commit handle was not cleanup-finalized: rolled=%v count=%d", ft.rolled, ft.rollbackCount)
	}
}

func TestResolutionUnknownNeverReplaysEvenWhenNegativeReplayPolicyEnabled(t *testing.T) {
	d := &fakeDB{txs: []*fakeTx{{commitErr: errors.New("lost ack")}, {}}}
	r := &resolver{states: []ResolutionState{ResolutionUnknown}}
	calls := 0
	res, err := (Runner{DB: d}).Run(context.Background(), opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 2, AllowReplayAfterAuthoritativeNegative: true}, r, func(context.Context, Scope) error { calls++; return nil })
	var u *UnknownCommitError
	if !errors.As(err, &u) || res.Outcome != UnknownCommitOutcome {
		t.Fatalf("res=%+v err=%v", res, err)
	}
	if calls != 1 {
		t.Fatalf("unknown resolution replayed body %d times", calls)
	}
}

func TestTimeoutSettingsApplied(t *testing.T) {
	ft := &fakeTx{}
	d := &fakeDB{txs: []*fakeTx{ft}}
	_, err := (Runner{DB: d}).Run(context.Background(), opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 1}, nil, func(context.Context, Scope) error { return nil })
	if err != nil {
		t.Fatal(err)
	}
	if ft.settings != 3 {
		t.Fatalf("settings=%d", ft.settings)
	}
}

func TestAdmissionSaturatesBeforeBegin(t *testing.T) {
	gate := NewSemaphore(1)
	release, err := gate.Acquire(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	defer release()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Millisecond)
	defer cancel()
	if _, err := gate.Acquire(ctx); !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("expected bounded admission timeout, got %v", err)
	}
}

func TestDriverProvenRollbackAtCommitIsDefiniteAbort(t *testing.T) {
	d := &fakeDB{txs: []*fakeTx{{commitErr: MarkDefiniteAbort(errors.New("commit became rollback"))}, {}}}
	calls := 0
	res, err := (Runner{DB: d}).Run(context.Background(), opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 2, RetryDefiniteAbort: true}, nil, func(context.Context, Scope) error { calls++; return nil })
	if err != nil {
		t.Fatal(err)
	}
	if res.Outcome != DefiniteCommit || calls != 2 {
		t.Fatalf("res=%+v calls=%d", res, calls)
	}
}

type contextCheckingResolver struct{ sawErr error }

func (r *contextCheckingResolver) Resolve(ctx context.Context, _ ResolutionRequest) (Resolution, error) {
	r.sawErr = ctx.Err()
	return Resolution{State: ResolutionCommitted}, nil
}

func TestUnknownCommitReconciliationSurvivesCallerCancellation(t *testing.T) {
	ft := &fakeTx{commitErr: errors.New("lost commit ack")}
	d := &fakeDB{txs: []*fakeTx{ft}}
	r := &contextCheckingResolver{}
	ctx, cancel := context.WithCancel(context.Background())
	_, err := (Runner{DB: d}).Run(ctx, opctx(), profile(), Options{}, RetryPolicy{MaxAttempts: 1}, r, func(context.Context, Scope) error {
		cancel()
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if r.sawErr != nil {
		t.Fatalf("reconciliation inherited canceled request context: %v", r.sawErr)
	}
}

func TestProfileRequiresReconcileTimeout(t *testing.T) {
	p := profile()
	p.ReconcileTimeout = 0
	if err := p.Validate(); err == nil {
		t.Fatal("expected missing reconcile timeout to fail")
	}
}

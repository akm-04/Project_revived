package tx

import (
	"context"
	"errors"
	"testing"
	"time"
)

func shortAcquireProfile() Profile {
	p := profile()
	p.AcquireTimeout = 50 * time.Millisecond
	return p
}

func heldSemaphore(t *testing.T, releaseAfter time.Duration) *Semaphore {
	t.Helper()
	s := NewSemaphore(1)
	release, err := s.Acquire(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	time.AfterFunc(releaseAfter, release)
	return s
}

func noopBody(context.Context, Scope) error { return nil }

// C1-1: without a request deadline a full queue still fails at the profile's acquire timeout.
func TestAdmissionWaitDefaultsToProfileAcquireTimeout(t *testing.T) {
	r := Runner{DB: &fakeDB{txs: []*fakeTx{{}}}, Admission: heldSemaphore(t, 300*time.Millisecond)}
	_, err := r.Run(context.Background(), opctx(), shortAcquireProfile(), Options{Isolation: Serializable}, RetryPolicy{MaxAttempts: 1}, nil, noopBody)
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("err=%v want deadline exceeded", err)
	}
}

// C1-1: a request queues until its admission deadline instead of failing at the acquire timeout.
func TestAdmissionWaitExtendsToRequestDeadline(t *testing.T) {
	r := Runner{DB: &fakeDB{txs: []*fakeTx{{}}}, Admission: heldSemaphore(t, 150*time.Millisecond)}
	ctx := WithAdmissionDeadline(context.Background(), time.Now().Add(time.Second))
	res, err := r.Run(ctx, opctx(), shortAcquireProfile(), Options{Isolation: Serializable}, RetryPolicy{MaxAttempts: 1}, nil, noopBody)
	if err != nil || res.Outcome != DefiniteCommit {
		t.Fatalf("res=%+v err=%v want commit after queueing", res, err)
	}
}

func TestAdmissionWaitExpiredRequestDoesNotRenewAcquireTimeout(t *testing.T) {
	ctx := WithAdmissionDeadline(context.Background(), time.Now().Add(-time.Second))
	if got := admissionWait(ctx, shortAcquireProfile()); got != 0 {
		t.Fatalf("wait=%v want no remaining wait", got)
	}
}

// C1-5: the edge reads one rolling measurement of queue-to-commit time; it is zero before the first sample.
func TestSemaphoreExpectedWaitIsRollingMeanOfQueueToCommit(t *testing.T) {
	s := NewSemaphore(16)
	if got := s.ExpectedWait(); got != 0 {
		t.Fatalf("expected wait without samples=%v want 0", got)
	}
	s.Observe(100 * time.Millisecond)
	s.Observe(200 * time.Millisecond)
	s.Observe(400 * time.Millisecond)
	if got := s.ExpectedWait(); got/time.Millisecond != 233 {
		t.Fatalf("rolling mean=%v want 233ms", got)
	}
	// Bounded memory: the ring keeps only the newest admissionWaitSamples durations.
	for i := 0; i < 10*admissionWaitSamples; i++ {
		s.Observe(time.Second)
	}
	if got := s.ExpectedWait(); got != time.Second {
		t.Fatalf("mean after old samples aged out=%v want 1s", got)
	}
}

type recordingAdmission struct{ observed []time.Duration }

func (r *recordingAdmission) Acquire(context.Context) (func(), error) { return func() {}, nil }
func (r *recordingAdmission) Observe(d time.Duration)                 { r.observed = append(r.observed, d) }

// C1-5: the runner records queue-to-commit only when the transaction commits; a rolled-back attempt is not a wait
// estimate sample.
func TestRunnerRecordsQueueToCommitOnCommitOnly(t *testing.T) {
	admission := &recordingAdmission{}
	run := Runner{DB: &fakeDB{txs: []*fakeTx{{}}}, Admission: admission}
	if _, err := run.Run(context.Background(), opctx(), profile(), Options{Isolation: Serializable}, RetryPolicy{MaxAttempts: 1}, nil, noopBody); err != nil {
		t.Fatal(err)
	}
	if len(admission.observed) != 1 || admission.observed[0] <= 0 {
		t.Fatalf("observed=%v want one positive queue-to-commit sample", admission.observed)
	}
	failing := &recordingAdmission{}
	failingRun := Runner{DB: &fakeDB{txs: []*fakeTx{{}}}, Admission: failing}
	if _, err := failingRun.Run(context.Background(), opctx(), profile(), Options{Isolation: Serializable}, RetryPolicy{MaxAttempts: 1}, nil, func(context.Context, Scope) error {
		return stateErr("40001")
	}); err == nil {
		t.Fatal("expected abort")
	}
	if len(failing.observed) != 0 {
		t.Fatalf("observed=%v want no sample for a rolled-back attempt", failing.observed)
	}
}

// C1-2: the body's context says it already holds a connection; the outer one does not.
func TestBodyContextIsMarkedAsHoldingAConnection(t *testing.T) {
	var inside bool
	r := Runner{DB: &fakeDB{txs: []*fakeTx{{}}}}
	_, err := r.Run(context.Background(), opctx(), profile(), Options{Isolation: Serializable}, RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, _ Scope) error {
		inside = HoldsConnection(ctx)
		return nil
	})
	if err != nil || !inside || HoldsConnection(context.Background()) {
		t.Fatalf("inside=%v err=%v", inside, err)
	}
}

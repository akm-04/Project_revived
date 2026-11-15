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

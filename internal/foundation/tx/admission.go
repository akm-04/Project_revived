package tx

import (
	"context"
	"errors"
	"sync"
	"time"
)

var ErrAdmissionClosed = errors.New("transaction admission closed")

// admissionWaitSamples bounds the rolling queue-to-commit measurement (C1-5).
const admissionWaitSamples = 256

type Admission interface {
	Acquire(context.Context) (func(), error)
	// Observe records one transaction's measured queue-to-commit duration for ExpectedWait.
	Observe(time.Duration)
}

type Semaphore struct {
	slots chan struct{}
	// The edge reads ExpectedWait under mu; the ring keeps the last admissionWaitSamples transactions.
	mu      sync.Mutex
	samples [admissionWaitSamples]time.Duration
	next    int
	count   int
	total   time.Duration
}

func NewSemaphore(max int) *Semaphore {
	if max < 1 {
		panic("admission max must be >=1")
	}
	return &Semaphore{slots: make(chan struct{}, max)}
}
func (s *Semaphore) Acquire(ctx context.Context) (func(), error) {
	select {
	case s.slots <- struct{}{}:
		var done bool
		return func() {
			if !done {
				done = true
				<-s.slots
			}
		}, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

// Observe records one measured queue-to-commit duration. Only the most recent samples count.
func (s *Semaphore) Observe(duration time.Duration) {
	if duration < 0 {
		duration = 0
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.count == len(s.samples) {
		s.total -= s.samples[s.next]
	} else {
		s.count++
	}
	s.samples[s.next] = duration
	s.total += duration
	s.next = (s.next + 1) % len(s.samples)
}

// ExpectedWait is the rolling mean of measured queue-to-commit durations, or zero before the first sample. It is
// the one read method the HTTP edge consults before admitting a request (C1-5).
func (s *Semaphore) ExpectedWait() time.Duration {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.count == 0 {
		return 0
	}
	return s.total / time.Duration(s.count)
}

type NoopAdmission struct{}

func (NoopAdmission) Acquire(context.Context) (func(), error) { return func() {}, nil }
func (NoopAdmission) Observe(time.Duration)                   {}

type admissionDeadlineKey struct{}

// WithAdmissionDeadline bounds how long the request's transactions may queue for admission and a connection. The
// edge sets it from the client's patience: before it a queued request beats a refused one (C1-1), after it nobody
// waits for the reply. A transaction that starts in time still runs to its own profile limits.
func WithAdmissionDeadline(ctx context.Context, deadline time.Time) context.Context {
	return context.WithValue(ctx, admissionDeadlineKey{}, deadline)
}

func admissionWait(ctx context.Context, p Profile) time.Duration {
	deadline, ok := ctx.Value(admissionDeadlineKey{}).(time.Time)
	if !ok {
		return p.AcquireTimeout
	}
	return max(time.Until(deadline), 0)
}

type holdsConnectionKey struct{}

// HoldsConnection reports whether ctx belongs to a transaction body, which already holds a pooled connection; a
// second acquisition from there can starve the pool (C1-2).
func HoldsConnection(ctx context.Context) bool {
	held, _ := ctx.Value(holdsConnectionKey{}).(bool)
	return held
}

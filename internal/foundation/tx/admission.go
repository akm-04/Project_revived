package tx

import (
	"context"
	"errors"
	"time"
)

var ErrAdmissionClosed = errors.New("transaction admission closed")

type Admission interface {
	Acquire(context.Context) (func(), error)
}

type Semaphore struct{ slots chan struct{} }

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

type NoopAdmission struct{}

func (NoopAdmission) Acquire(context.Context) (func(), error) { return func() {}, nil }

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
	return max(time.Until(deadline), p.AcquireTimeout)
}

type holdsConnectionKey struct{}

// HoldsConnection reports whether ctx belongs to a transaction body, which already holds a pooled connection; a
// second acquisition from there can starve the pool (C1-2).
func HoldsConnection(ctx context.Context) bool {
	held, _ := ctx.Value(holdsConnectionKey{}).(bool)
	return held
}

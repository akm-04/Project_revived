package tx

import (
	"context"
	"errors"
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

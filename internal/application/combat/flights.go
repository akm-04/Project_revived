package combat

import (
	"context"
	"sync"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// Flight is one in-process resolution of an attempt; repeated mode requests
// and reconcile providers wait on it instead of launching another worker.
// Resolved and Err are readable once Done is closed.
type Flight struct {
	Done     chan struct{}
	Resolved Resolved
	Err      error
}

var flights sync.Map

// ResolveDetached resolves an attempt on a context detached from the caller,
// so the work survives the request that started it.
func (s Service) ResolveDetached(ctx context.Context, op operation.Context, attemptID ids.UUID) *Flight {
	f := &Flight{Done: make(chan struct{})}
	if running, loaded := flights.LoadOrStore(attemptID, f); loaded {
		return running.(*Flight)
	}
	detached := context.WithoutCancel(ctx)
	go func() {
		f.Resolved, f.Err = s.Resolve(detached, op, attemptID)
		flights.Delete(attemptID)
		close(f.Done)
	}()
	return f
}

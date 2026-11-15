//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"sync"

	cb "gxb.local/backend/v2/internal/application/combat"
	cd "gxb.local/backend/v2/internal/domain/combat"
)

// permanentOnceWorker fails the first resolution permanently, then delegates to
// the real worker so a retried fight can resolve.
type permanentOnceWorker struct {
	mu     sync.Mutex
	worker cb.Worker
	failed bool
}

func (w *permanentOnceWorker) Resolve(ctx context.Context, snapshot []byte, hash string, root [32]byte) (cb.WorkerOutput, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	if !w.failed {
		w.failed = true
		return cb.WorkerOutput{}, fmt.Errorf("%w: native fixture", cd.ErrResolverPermanent)
	}
	return w.worker.Resolve(ctx, snapshot, hash, root)
}

func permanentFirst(service cb.Service) cb.Service {
	service.Worker = &permanentOnceWorker{worker: service.Worker}
	return service
}

// saturatedOnceWorker refuses the first resolution as an admission fault, then
// delegates to the real worker so a retried fight can resolve.
type saturatedOnceWorker struct {
	mu     sync.Mutex
	worker cb.Worker
	failed bool
}

func (w *saturatedOnceWorker) Resolve(ctx context.Context, snapshot []byte, hash string, root [32]byte) (cb.WorkerOutput, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	if !w.failed {
		w.failed = true
		return cb.WorkerOutput{}, cb.ErrWorkerSaturated
	}
	return w.worker.Resolve(ctx, snapshot, hash, root)
}

func saturatedFirst(service cb.Service) cb.Service {
	service.Worker = &saturatedOnceWorker{worker: service.Worker}
	return service
}

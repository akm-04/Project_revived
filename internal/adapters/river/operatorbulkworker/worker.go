//go:build postgres && river

// Package operatorbulkworker runs the operator bulk settlement job through
// River. The worker owns no state: it re-enters the operator grant applier,
// whose per-recipient keys make a resumed run exactly-once.
package operatorbulkworker

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"
	"gxb.local/backend/v2/internal/adapters/postgres"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
)

const ApplyKind = "operator_bulk_apply"
const Queue = "operator_bulk"

const applyPeriod = 15 * time.Second

var uniqueWhileQueued = river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
	rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRunning,
	rivertype.JobStateRetryable, rivertype.JobStateScheduled}}

// Applier settles pending bulk targets.
type Applier interface {
	ApplyPending(context.Context) (int, error)
}

type applyArgs struct{}

func (applyArgs) Kind() string { return ApplyKind }

type applyWorker struct {
	river.WorkerDefaults[applyArgs]
	Applier Applier
}

func (w *applyWorker) Work(ctx context.Context, _ *river.Job[applyArgs]) error {
	if w == nil || w.Applier == nil {
		return errors.New("nil operator bulk applier")
	}
	_, err := w.Applier.ApplyPending(ctx)
	return err
}

// Register installs the bulk settlement worker on the shared River bundle.
func Register(workers *river.Workers, applier Applier) error {
	if workers == nil || applier == nil {
		return errors.New("operator bulk worker registration requires workers and an applier")
	}
	return river.AddWorkerSafely(workers, &applyWorker{Applier: applier})
}

type Runtime struct{ river *riveradapter.Runtime }

// New validates the pinned River schema and builds the bulk worker client.
func New(p *postgres.Pool, applier Applier) (*Runtime, error) {
	if p == nil || applier == nil {
		return nil, errors.New("operator bulk worker requires a pool and an applier")
	}
	if err := riveradapter.ValidateDeployment(context.Background(), p.Raw()); err != nil {
		return nil, err
	}
	dispatch, err := gen.NewDispatchRegistry()
	if err != nil {
		return nil, err
	}
	runtime, err := riveradapter.NewRuntime(p.Raw(), dispatch, riveradapter.RuntimeConfig{
		Queues:          map[string]int{Queue: 1},
		SoftStopTimeout: 15 * time.Second,
		JobTimeout:      2 * time.Minute,
		RegisterWorkers: func(workers *river.Workers) error { return Register(workers, applier) },
	})
	if err != nil {
		return nil, err
	}
	return &Runtime{river: runtime}, nil
}

func (r *Runtime) schedule(ctx context.Context) {
	if err := r.river.Insert(ctx, applyArgs{}, &river.InsertOpts{Queue: Queue, UniqueOpts: uniqueWhileQueued}); err != nil && ctx.Err() == nil {
		log.Printf("operator bulk apply insert failed: %v", err)
	}
}

// Run starts the worker client and schedules one apply job at once and then on
// its period, so a crash-resumed pending target is picked up without a submit.
func (r *Runtime) Run(ctx context.Context) error {
	if r == nil || r.river == nil {
		return errors.New("nil operator bulk runtime")
	}
	if err := r.river.Start(ctx); err != nil {
		return err
	}
	ticker := time.NewTicker(applyPeriod)
	defer ticker.Stop()
	r.schedule(ctx)
	for ctx.Err() == nil {
		select {
		case <-ticker.C:
			r.schedule(ctx)
		case <-ctx.Done():
		}
	}
	drain, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	return r.river.Stop(drain)
}

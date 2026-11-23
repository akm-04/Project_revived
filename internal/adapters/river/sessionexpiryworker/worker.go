//go:build postgres && river

// Package sessionexpiryworker runs the identity idle-session sweep River job.
// It owns no canonical state: the identity owner's IdleExpirySweep applies each
// bounded batch through its own transaction.
package sessionexpiryworker

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const Kind = "identity_idle_session_sweep"
const PhysicalQueue = "identity_maintenance"
const Period = time.Minute

var uniqueWhileQueued = river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
	rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRunning,
	rivertype.JobStateRetryable, rivertype.JobStateScheduled}}

type sweepArgs struct{}

func (sweepArgs) Kind() string { return Kind }

type sweepWorker struct {
	river.WorkerDefaults[sweepArgs]
	Sweep *appidentity.IdleExpirySweep
}

func (w *sweepWorker) Work(c context.Context, _ *river.Job[sweepArgs]) error {
	if w == nil || w.Sweep == nil {
		return errors.New("nil idle session sweep worker")
	}
	revoked, err := w.Sweep.Run(c)
	if err != nil {
		return err
	}
	if revoked > 0 {
		log.Printf("identity idle session sweep revoked %d sessions", revoked)
	}
	return nil
}

// Register installs the sweep worker on the shared River bundle.
func Register(workers *river.Workers, sweep *appidentity.IdleExpirySweep) error {
	if workers == nil || sweep == nil {
		return errors.New("idle session worker registration requires workers and a sweep")
	}
	return river.AddWorkerSafely(workers, &sweepWorker{Sweep: sweep})
}

type Runtime struct {
	river *riveradapter.Runtime
}

// New validates the pinned River schema and builds the idle session worker.
func New(p *postgres.Pool) (*Runtime, error) {
	if p == nil {
		return nil, errors.New("idle session worker requires a pool")
	}
	if err := riveradapter.ValidateDeployment(context.Background(), p.Raw()); err != nil {
		return nil, err
	}
	dispatch, err := gen.NewDispatchRegistry()
	if err != nil {
		return nil, err
	}
	sweep := &appidentity.IdleExpirySweep{
		Runner:     tx.Runner{DB: p},
		Store:      identitystore.Store{},
		Operations: operation.Factory{Clock: clock.System{}},
	}
	runtime, err := riveradapter.NewRuntime(p.Raw(), dispatch, riveradapter.RuntimeConfig{
		Queues:          map[string]int{PhysicalQueue: 1},
		SoftStopTimeout: 15 * time.Second,
		JobTimeout:      time.Minute,
		RegisterWorkers: func(workers *river.Workers) error { return Register(workers, sweep) },
	})
	if err != nil {
		return nil, err
	}
	return &Runtime{river: runtime}, nil
}

func (r *Runtime) schedule(c context.Context) {
	if err := r.river.Insert(c, sweepArgs{}, &river.InsertOpts{Queue: PhysicalQueue, UniqueOpts: uniqueWhileQueued}); err != nil && c.Err() == nil {
		log.Printf("identity idle session %s insert failed: %v", Kind, err)
	}
}

// Run starts the worker client, inserts one sweep at once, then every Period,
// and waits for cancellation.
func (r *Runtime) Run(c context.Context) error {
	if r == nil || r.river == nil {
		return errors.New("nil idle session worker runtime")
	}
	if err := r.river.Start(c); err != nil {
		return err
	}
	ticker := time.NewTicker(Period)
	defer ticker.Stop()
	r.schedule(c)
	for c.Err() == nil {
		select {
		case <-ticker.C:
			r.schedule(c)
		case <-c.Done():
		}
	}
	drain, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	return r.river.Stop(drain)
}

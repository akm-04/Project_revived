//go:build postgres && river

// Package eventsworker runs the I11A E4 events maintenance jobs through River:
// the default-cycle materialiser and the settlement job (I11A_EVENTS_V1 ruling
// 8, EA-9). It owns no state; both jobs re-enter application/events.
package eventsworker

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

const CycleMaterialiseKind = "events_cycle_materialise"
const SettlementKind = "events_settlement"
const PhysicalQueue = "events_maintenance"

const defaultPeriod = time.Minute

// Jobs is the events application surface the workers re-enter.
type Jobs interface {
	MaterialiseCycle(context.Context) error
	SettleDue(context.Context) error
}

// uniqueWhileQueued skips an insert while a copy of the job waits or runs, so
// the leadership-elected API process never stacks a slow run.
var uniqueWhileQueued = river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
	rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRunning,
	rivertype.JobStateRetryable, rivertype.JobStateScheduled}}

type materialiseArgs struct{}

func (materialiseArgs) Kind() string { return CycleMaterialiseKind }

type settlementArgs struct{}

func (settlementArgs) Kind() string { return SettlementKind }

type materialiseWorker struct {
	river.WorkerDefaults[materialiseArgs]
	Jobs Jobs
}

func (w *materialiseWorker) Work(ctx context.Context, job *river.Job[materialiseArgs]) error {
	if w == nil || w.Jobs == nil {
		return errors.New("nil events materialise worker")
	}
	return w.Jobs.MaterialiseCycle(ctx)
}

type settlementWorker struct {
	river.WorkerDefaults[settlementArgs]
	Jobs Jobs
}

func (w *settlementWorker) Work(ctx context.Context, job *river.Job[settlementArgs]) error {
	if w == nil || w.Jobs == nil {
		return errors.New("nil events settlement worker")
	}
	return w.Jobs.SettleDue(ctx)
}

// Register installs both feature workers on the shared River bundle.
func Register(workers *river.Workers, jobs Jobs) error {
	if workers == nil || jobs == nil {
		return errors.New("events worker registration requires workers and jobs")
	}
	if err := river.AddWorkerSafely(workers, &materialiseWorker{Jobs: jobs}); err != nil {
		return err
	}
	return river.AddWorkerSafely(workers, &settlementWorker{Jobs: jobs})
}

type Runtime struct {
	river  *riveradapter.Runtime
	period time.Duration
}

// New validates the pinned River schema and builds the events worker client.
func New(p *postgres.Pool, jobs Jobs, period time.Duration) (*Runtime, error) {
	if p == nil || jobs == nil {
		return nil, errors.New("events worker requires a pool and jobs")
	}
	if period <= 0 {
		period = defaultPeriod
	}
	if err := riveradapter.ValidateDeployment(context.Background(), p.Raw()); err != nil {
		return nil, err
	}
	dispatch, err := gen.NewDispatchRegistry()
	if err != nil {
		return nil, err
	}
	runtime, err := riveradapter.NewRuntime(p.Raw(), dispatch, riveradapter.RuntimeConfig{
		Queues:          map[string]int{PhysicalQueue: 1},
		SoftStopTimeout: 15 * time.Second,
		JobTimeout:      2 * time.Minute,
		RegisterWorkers: func(workers *river.Workers) error { return Register(workers, jobs) },
	})
	if err != nil {
		return nil, err
	}
	return &Runtime{river: runtime, period: period}, nil
}

func (r *Runtime) schedule(ctx context.Context, args river.JobArgs) {
	if err := r.river.Insert(ctx, args, &river.InsertOpts{Queue: PhysicalQueue, UniqueOpts: uniqueWhileQueued}); err != nil && ctx.Err() == nil {
		log.Printf("events %s insert failed: %v", args.Kind(), err)
	}
}

// Run starts the worker client, inserts both jobs at once and then on the
// period, and waits for cancellation.
func (r *Runtime) Run(ctx context.Context) error {
	if r == nil || r.river == nil {
		return errors.New("nil events worker runtime")
	}
	if err := r.river.Start(ctx); err != nil {
		return err
	}
	ticker := time.NewTicker(r.period)
	defer ticker.Stop()
	r.schedule(ctx, materialiseArgs{})
	r.schedule(ctx, settlementArgs{})
	for ctx.Err() == nil {
		select {
		case <-ticker.C:
			r.schedule(ctx, materialiseArgs{})
			r.schedule(ctx, settlementArgs{})
		case <-ctx.Done():
		}
	}
	drain, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	return r.river.Stop(drain)
}

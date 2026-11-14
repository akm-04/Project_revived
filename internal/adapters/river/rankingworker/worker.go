//go:build postgres && river

// Package rankingworker runs the R7 ranking maintenance jobs through River.
// The workers own no canonical state; they re-enter the ranking service, whose
// methods keep every write in an owner transaction.
package rankingworker

import (
	"context"
	"errors"
	"time"

	"github.com/riverqueue/river"
	"gxb.local/backend/v2/internal/adapters/postgres"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	appranking "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

const ScoresRefreshKind = "ranking_scores_refresh"
const ScoresBackfillKind = "ranking_scores_backfill"
const BoardSettleKind = "ranking_board_settle"
const PhysicalQueue = "ranking_maintenance"

// Jobs is the ranking application surface the workers re-enter.
type Jobs interface {
	RefreshActiveScores(context.Context, operation.Context) error
	BackfillScores(context.Context, operation.Context) error
	SettleBoardBoundaries(context.Context, operation.Context) error
}

type refreshArgs struct{}

func (refreshArgs) Kind() string { return ScoresRefreshKind }

type backfillArgs struct{}

func (backfillArgs) Kind() string { return ScoresBackfillKind }

type settleArgs struct{}

func (settleArgs) Kind() string { return BoardSettleKind }

type jobRunner struct {
	Jobs       Jobs
	Operations operation.Factory
	Run        func(context.Context, operation.Context) error
}

func (r jobRunner) run(c context.Context) error {
	if r.Jobs == nil || r.Run == nil {
		return errors.New("ranking worker dependencies unavailable")
	}
	op, e := r.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	return r.Run(c, op)
}

type scoreRefreshWorker struct {
	river.WorkerDefaults[refreshArgs]
	jobRunner
}

func (w *scoreRefreshWorker) Work(c context.Context, job *river.Job[refreshArgs]) error {
	if w == nil {
		return errors.New("nil ranking refresh worker")
	}
	return w.run(c)
}

type scoreBackfillWorker struct {
	river.WorkerDefaults[backfillArgs]
	jobRunner
}

func (w *scoreBackfillWorker) Work(c context.Context, job *river.Job[backfillArgs]) error {
	if w == nil {
		return errors.New("nil ranking backfill worker")
	}
	return w.run(c)
}

type boardSettleWorker struct {
	river.WorkerDefaults[settleArgs]
	jobRunner
}

func (w *boardSettleWorker) Work(c context.Context, job *river.Job[settleArgs]) error {
	if w == nil {
		return errors.New("nil ranking settle worker")
	}
	return w.run(c)
}

// Register installs the three feature workers on the shared River bundle.
func Register(workers *river.Workers, jobs Jobs) error {
	if workers == nil || jobs == nil {
		return errors.New("ranking worker registration requires workers and jobs")
	}
	factory := operation.Factory{Clock: clock.System{}}
	refresh := &scoreRefreshWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Run: jobs.RefreshActiveScores}}
	backfill := &scoreBackfillWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Run: jobs.BackfillScores}}
	settle := &boardSettleWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Run: jobs.SettleBoardBoundaries}}
	if e := river.AddWorkerSafely(workers, refresh); e != nil {
		return e
	}
	if e := river.AddWorkerSafely(workers, backfill); e != nil {
		return e
	}
	return river.AddWorkerSafely(workers, settle)
}

// PeriodicJobs schedules the refresh and boundary settlement jobs. The
// backfill is inserted once at deploy, not scheduled.
func PeriodicJobs(refreshPeriod time.Duration) []*river.PeriodicJob {
	if refreshPeriod <= 0 {
		refreshPeriod = appranking.DefaultRankRefreshPeriod
	}
	return []*river.PeriodicJob{
		river.NewPeriodicJob(river.PeriodicInterval(refreshPeriod), func() (river.JobArgs, *river.InsertOpts) {
			return refreshArgs{}, &river.InsertOpts{Queue: PhysicalQueue}
		}, &river.PeriodicJobOpts{ID: ScoresRefreshKind, RunOnStart: true}),
		river.NewPeriodicJob(river.PeriodicInterval(time.Minute), func() (river.JobArgs, *river.InsertOpts) {
			return settleArgs{}, &river.InsertOpts{Queue: PhysicalQueue}
		}, &river.PeriodicJobOpts{ID: BoardSettleKind, RunOnStart: true}),
	}
}

type Runtime struct{ river *riveradapter.Runtime }

// New validates the pinned River schema and builds the ranking worker client.
func New(p *postgres.Pool, jobs Jobs, refreshPeriod time.Duration) (*Runtime, error) {
	if p == nil || jobs == nil {
		return nil, errors.New("ranking worker requires a pool and jobs")
	}
	if e := riveradapter.ValidateDeployment(context.Background(), p.Raw()); e != nil {
		return nil, e
	}
	dispatch, e := gen.NewDispatchRegistry()
	if e != nil {
		return nil, e
	}
	runtime, e := riveradapter.NewRuntime(p.Raw(), dispatch, riveradapter.RuntimeConfig{
		Queues:          map[string]int{PhysicalQueue: 2},
		SoftStopTimeout: 15 * time.Second,
		JobTimeout:      2 * time.Minute,
		RegisterWorkers: func(workers *river.Workers) error { return Register(workers, jobs) },
		PeriodicJobs:    PeriodicJobs(refreshPeriod),
	})
	if e != nil {
		return nil, e
	}
	return &Runtime{river: runtime}, nil
}

// EnqueueBackfill inserts the one-shot deploy backfill. River uniqueness by
// kind/args keeps repeated starts from stacking copies.
func (r *Runtime) EnqueueBackfill(c context.Context) error {
	if r == nil || r.river == nil {
		return errors.New("nil ranking worker runtime")
	}
	return r.river.Insert(c, backfillArgs{}, &river.InsertOpts{Queue: PhysicalQueue, UniqueOpts: river.UniqueOpts{ByArgs: true}})
}

// Run starts the worker client and waits for cancellation.
func (r *Runtime) Run(c context.Context) error {
	if r == nil || r.river == nil {
		return errors.New("nil ranking worker runtime")
	}
	if e := r.river.Start(c); e != nil {
		return e
	}
	<-c.Done()
	drain, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	return r.river.Stop(drain)
}

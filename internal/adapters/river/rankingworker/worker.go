//go:build postgres && river

// Package rankingworker runs the R7 ranking maintenance jobs through River.
// The workers own no canonical state; they re-enter the ranking service, whose
// methods keep every write in an owner transaction.
package rankingworker

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	appranking "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

const ScoresRefreshKind = "ranking_scores_refresh"
const ScoresBackfillKind = "ranking_scores_backfill"
const BoardSettleKind = "ranking_board_settle"
const PhysicalQueue = "ranking_maintenance"

const settlePeriod = time.Minute

// uniqueWhileQueued skips an insert while a copy of the job waits or runs. Every
// API process inserts on its own ticker, so the jobs run whichever River client
// holds leadership (A-028), and a slow run never stacks a second copy.
var uniqueWhileQueued = river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
	rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRunning,
	rivertype.JobStateRetryable, rivertype.JobStateScheduled}}

// Jobs is the ranking application surface the workers re-enter.
type Jobs interface {
	RefreshActiveScores(context.Context, operation.Context, []playerroot.Root) error
	BackfillScores(context.Context, operation.Context, []playerroot.Root) error
	SettleBoardBoundaries(context.Context, operation.Context, []playerroot.Root) error
}

// Roots is the I4-owned player enumeration. It lives at the adapter edge so the
// ranking application package never scans all players.
type Roots func(context.Context) ([]playerroot.Root, error)

type refreshArgs struct{}

func (refreshArgs) Kind() string { return ScoresRefreshKind }

type backfillArgs struct{}

func (backfillArgs) Kind() string { return ScoresBackfillKind }

type settleArgs struct{}

func (settleArgs) Kind() string { return BoardSettleKind }

type jobRunner struct {
	Jobs       Jobs
	Operations operation.Factory
	Roots      Roots
	Run        func(context.Context, operation.Context, []playerroot.Root) error
}

func (r jobRunner) run(c context.Context) error {
	if r.Jobs == nil || r.Run == nil || r.Roots == nil {
		return errors.New("ranking worker dependencies unavailable")
	}
	op, e := r.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	roots, e := r.Roots(c)
	if e != nil {
		return e
	}
	return r.Run(c, op, roots)
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
func Register(workers *river.Workers, jobs Jobs, roots Roots) error {
	if workers == nil || jobs == nil || roots == nil {
		return errors.New("ranking worker registration requires workers, jobs and roots")
	}
	factory := operation.Factory{Clock: clock.System{}}
	refresh := &scoreRefreshWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Roots: roots, Run: jobs.RefreshActiveScores}}
	backfill := &scoreBackfillWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Roots: roots, Run: jobs.BackfillScores}}
	settle := &boardSettleWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Roots: roots, Run: jobs.SettleBoardBoundaries}}
	if e := river.AddWorkerSafely(workers, refresh); e != nil {
		return e
	}
	if e := river.AddWorkerSafely(workers, backfill); e != nil {
		return e
	}
	return river.AddWorkerSafely(workers, settle)
}

type Runtime struct {
	river         *riveradapter.Runtime
	refreshPeriod time.Duration
}

// New validates the pinned River schema and builds the ranking worker client.
func New(p *postgres.Pool, jobs Jobs, refreshPeriod time.Duration) (*Runtime, error) {
	if p == nil || jobs == nil {
		return nil, errors.New("ranking worker requires a pool and jobs")
	}
	if refreshPeriod <= 0 {
		refreshPeriod = appranking.DefaultRankRefreshPeriod
	}
	if e := riveradapter.ValidateDeployment(context.Background(), p.Raw()); e != nil {
		return nil, e
	}
	dispatch, e := gen.NewDispatchRegistry()
	if e != nil {
		return nil, e
	}
	roots := func(c context.Context) ([]playerroot.Root, error) {
		return (i4store.PlayerRootLocker{}).ListPlayerRootsTx(c, p)
	}
	runtime, e := riveradapter.NewRuntime(p.Raw(), dispatch, riveradapter.RuntimeConfig{
		Queues:          map[string]int{PhysicalQueue: 2},
		SoftStopTimeout: 15 * time.Second,
		JobTimeout:      2 * time.Minute,
		RegisterWorkers: func(workers *river.Workers) error { return Register(workers, jobs, roots) },
	})
	if e != nil {
		return nil, e
	}
	return &Runtime{river: runtime, refreshPeriod: refreshPeriod}, nil
}

// EnqueueBackfill inserts the one-shot deploy backfill. River uniqueness by
// kind/args keeps repeated starts from stacking copies.
func (r *Runtime) EnqueueBackfill(c context.Context) error {
	if r == nil || r.river == nil {
		return errors.New("nil ranking worker runtime")
	}
	return r.river.Insert(c, backfillArgs{}, &river.InsertOpts{Queue: PhysicalQueue, UniqueOpts: river.UniqueOpts{ByArgs: true}})
}

func (r *Runtime) schedule(c context.Context, args river.JobArgs) {
	if e := r.river.Insert(c, args, &river.InsertOpts{Queue: PhysicalQueue, UniqueOpts: uniqueWhileQueued}); e != nil && c.Err() == nil {
		log.Printf("ranking %s insert failed: %v", args.Kind(), e)
	}
}

// Run starts the worker client, inserts the refresh and settlement jobs at once
// and then on their periods, and waits for cancellation.
func (r *Runtime) Run(c context.Context) error {
	if r == nil || r.river == nil {
		return errors.New("nil ranking worker runtime")
	}
	if e := r.river.Start(c); e != nil {
		return e
	}
	refresh, settle := time.NewTicker(r.refreshPeriod), time.NewTicker(settlePeriod)
	defer refresh.Stop()
	defer settle.Stop()
	r.schedule(c, refreshArgs{})
	r.schedule(c, settleArgs{})
	for c.Err() == nil {
		select {
		case <-refresh.C:
			r.schedule(c, refreshArgs{})
		case <-settle.C:
			r.schedule(c, settleArgs{})
		case <-c.Done():
		}
	}
	drain, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	return r.river.Stop(drain)
}

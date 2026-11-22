//go:build postgres && river

// Package retentionworker runs the R8 data_retention_sweep River job. The
// worker owns no canonical state: every rule is a bounded statement inside a
// READ COMMITTED transaction in retentionstore.
package retentionworker

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/riverqueue/river"
	"github.com/riverqueue/river/rivertype"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const Kind = "data_retention_sweep"
const PhysicalQueue = "retention_maintenance"
const Period = 10 * time.Minute

// otaObservabilityRetentionDays is fixed by ruling 7 (OA-5): the two OTA
// observability tables do not follow GXB_RETENTION_DAYS.
const otaObservabilityRetentionDays = 15

var uniqueWhileQueued = river.UniqueOpts{ByArgs: true, ByState: []rivertype.JobState{
	rivertype.JobStateAvailable, rivertype.JobStatePending, rivertype.JobStateRunning,
	rivertype.JobStateRetryable, rivertype.JobStateScheduled}}

// Rule is one retention rule: a bounded DELETE that the sweep repeats until it
// finds no rows or the run budget is spent.
type Rule struct {
	Name   string
	Delete func(context.Context, tx.Tx) (int64, error)
}

// Sweeper runs the rules in order. It is separated from River so the loop and
// its budget are unit-testable without a database.
type Sweeper struct {
	Begin  func(context.Context, tx.Options) (tx.Tx, error)
	Rules  func(time.Time) []Rule
	Budget time.Duration
	Now    func() time.Time
	Logf   func(string, ...any)
}

// NewRules builds the production rule order at run time: receipts, the R5D
// settlements, the combat chain and its blobs, the cache snapshots, then media history. The "existing
// purges" row stays with its adventure, occult, illusion and client-log owners.
func NewRules(policies retentionstore.Policies) func(time.Time) []Rule {
	store := retentionstore.Store{}
	retentionDays := time.Duration(policies.RetentionDays) * 24 * time.Hour
	cacheDays := time.Duration(policies.CacheRetentionDays) * 24 * time.Hour
	mediaDays := time.Duration(policies.ProfileMediaHistoryDays) * 24 * time.Hour
	otaDays := time.Duration(otaObservabilityRetentionDays) * 24 * time.Hour
	return func(now time.Time) []Rule {
		return []Rule{
			{Name: "receipts", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteReplayOnlyReceipts(c, t, now.Add(-retentionDays))
			}},
			{Name: "attempt-settlements", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteExpiredAttemptSettlements(c, t, now.Add(-retentionDays))
			}},
			{Name: "combat-chain", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteExpiredCombatChain(c, t, now.Add(-retentionDays))
			}},
			{Name: "combat-blobs", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteUnreferencedCombatBlobs(c, t)
			}},
			{Name: "ranking-snapshots", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteStaleRankingSnapshots(c, t, now.Add(-cacheDays))
			}},
			{Name: "hero-recommend-snapshots", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteStaleHeroRecommendSnapshots(c, t, now.Add(-cacheDays))
			}},
			{Name: "media-history", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteExpiredMediaHistory(c, t, now.Add(-mediaDays))
			}},
			{Name: "ota-asset-misses", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteExpiredOTAAssetMisses(c, t, now.Add(-otaDays))
			}},
			{Name: "ota-asset-served", Delete: func(c context.Context, t tx.Tx) (int64, error) {
				return store.DeleteExpiredOTAAssetServedDaily(c, t, now.Add(-otaDays))
			}},
		}
	}
}

// Run repeats batches per rule until the rule finds no rows or the budget is
// spent. A failing rule logs and the run continues with the next rule.
func (s *Sweeper) Run(c context.Context) {
	if s == nil || s.Begin == nil || s.Rules == nil {
		return
	}
	now := s.now()
	budget := s.budget()
	deadline := now.Add(budget)
	for _, rule := range s.Rules(now) {
		if c.Err() != nil || !s.now().Before(deadline) {
			return
		}
		started := s.now()
		deleted := int64(0)
		for s.now().Before(deadline) {
			count, err := s.batch(c, rule)
			if err != nil {
				s.logf("retention rule %s failed after %d rows in %s: %v", rule.Name, deleted, s.now().Sub(started), err)
				break
			}
			deleted += count
			if count == 0 {
				break
			}
		}
		s.logf("retention rule %s deleted %d rows in %s", rule.Name, deleted, s.now().Sub(started))
	}
}

func (s *Sweeper) batch(c context.Context, rule Rule) (int64, error) {
	transaction, err := s.Begin(c, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		return 0, err
	}
	count, err := rule.Delete(c, transaction)
	if err != nil {
		_ = transaction.Rollback(c)
		return 0, err
	}
	if err = transaction.Commit(c); err != nil {
		return 0, err
	}
	return count, nil
}

func (s *Sweeper) now() time.Time {
	if s.Now == nil {
		return time.Now()
	}
	return s.Now()
}

func (s *Sweeper) budget() time.Duration {
	if s.Budget <= 0 {
		return retentionstore.DefaultRetentionRunBudget
	}
	return s.Budget
}

func (s *Sweeper) logf(format string, arguments ...any) {
	if s.Logf == nil {
		log.Printf(format, arguments...)
		return
	}
	s.Logf(format, arguments...)
}

type sweepArgs struct{}

func (sweepArgs) Kind() string { return Kind }

type sweepWorker struct {
	river.WorkerDefaults[sweepArgs]
	Sweeper *Sweeper
}

func (w *sweepWorker) Work(c context.Context, _ *river.Job[sweepArgs]) error {
	if w == nil || w.Sweeper == nil {
		return errors.New("nil retention sweep worker")
	}
	w.Sweeper.Run(c)
	return nil
}

// Register installs the sweep worker on the shared River bundle.
func Register(workers *river.Workers, sweeper *Sweeper) error {
	if workers == nil || sweeper == nil {
		return errors.New("retention worker registration requires workers and a sweeper")
	}
	return river.AddWorkerSafely(workers, &sweepWorker{Sweeper: sweeper})
}

type Runtime struct {
	river *riveradapter.Runtime
}

// New validates the pinned River schema and builds the retention worker client.
func New(p *postgres.Pool, policies retentionstore.Policies) (*Runtime, error) {
	if p == nil {
		return nil, errors.New("retention worker requires a pool")
	}
	if err := policies.Validate(); err != nil {
		return nil, err
	}
	if err := riveradapter.ValidateDeployment(context.Background(), p.Raw()); err != nil {
		return nil, err
	}
	dispatch, err := gen.NewDispatchRegistry()
	if err != nil {
		return nil, err
	}
	sweeper := &Sweeper{Begin: p.Begin, Rules: NewRules(policies), Budget: policies.RunBudget, Now: time.Now, Logf: log.Printf}
	runtime, err := riveradapter.NewRuntime(p.Raw(), dispatch, riveradapter.RuntimeConfig{
		Queues:          map[string]int{PhysicalQueue: 1},
		SoftStopTimeout: 15 * time.Second,
		JobTimeout:      policies.RunBudget + time.Minute,
		RegisterWorkers: func(workers *river.Workers) error { return Register(workers, sweeper) },
	})
	if err != nil {
		return nil, err
	}
	return &Runtime{river: runtime}, nil
}

func (r *Runtime) schedule(c context.Context) {
	if err := r.river.Insert(c, sweepArgs{}, &river.InsertOpts{Queue: PhysicalQueue, UniqueOpts: uniqueWhileQueued}); err != nil && c.Err() == nil {
		log.Printf("retention %s insert failed: %v", Kind, err)
	}
}

// Run starts the worker client, inserts one sweep at once, then every Period,
// and waits for cancellation.
func (r *Runtime) Run(c context.Context) error {
	if r == nil || r.river == nil {
		return errors.New("nil retention worker runtime")
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

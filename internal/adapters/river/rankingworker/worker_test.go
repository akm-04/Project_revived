//go:build postgres && river

package rankingworker

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/riverqueue/river"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type recordingJobs struct {
	mu      sync.Mutex
	calls   map[string]int
	lastOps map[string]operation.Context
}

func (j *recordingJobs) record(name string, o operation.Context) error {
	j.mu.Lock()
	defer j.mu.Unlock()
	j.calls[name]++
	j.lastOps[name] = o
	return nil
}
func (j *recordingJobs) RefreshActiveScores(_ context.Context, o operation.Context, _ []playerroot.Root) error {
	return j.record("refresh", o)
}
func (j *recordingJobs) BackfillScores(_ context.Context, o operation.Context, _ []playerroot.Root) error {
	return j.record("backfill", o)
}
func (j *recordingJobs) SettleBoardBoundaries(_ context.Context, o operation.Context, _ []playerroot.Root) error {
	return j.record("settle", o)
}

func TestRankingWorkersRegisterAndDispatchToTheirJobs(t *testing.T) {
	jobs := &recordingJobs{calls: map[string]int{}, lastOps: map[string]operation.Context{}}
	roots := func(context.Context) ([]playerroot.Root, error) {
		return []playerroot.Root{{PlayerID: 1, LogicalServerID: 1}}, nil
	}
	workers := river.NewWorkers()
	if e := Register(workers, jobs, roots); e != nil {
		t.Fatal(e)
	}
	if e := Register(workers, jobs, roots); e == nil {
		t.Fatal("duplicate worker registration accepted")
	}
	if e := uniqueWhileQueued.ByState; len(e) == 0 {
		t.Fatal("ranking jobs insert without a single-flight rule")
	}
	c := context.Background()
	factory := operation.Factory{Clock: clock.Fixed{T: time.Now().UTC()}}
	refresh := &scoreRefreshWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Roots: roots, Run: jobs.RefreshActiveScores}}
	backfill := &scoreBackfillWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Roots: roots, Run: jobs.BackfillScores}}
	settle := &boardSettleWorker{jobRunner: jobRunner{Jobs: jobs, Operations: factory, Roots: roots, Run: jobs.SettleBoardBoundaries}}
	if e := refresh.Work(c, &river.Job[refreshArgs]{}); e != nil {
		t.Fatal(e)
	}
	if e := backfill.Work(c, &river.Job[backfillArgs]{}); e != nil {
		t.Fatal(e)
	}
	if e := settle.Work(c, &river.Job[settleArgs]{}); e != nil {
		t.Fatal(e)
	}
	if jobs.calls["refresh"] != 1 || jobs.calls["backfill"] != 1 || jobs.calls["settle"] != 1 {
		t.Fatal(jobs.calls)
	}
	for name, o := range jobs.lastOps {
		if o.ID.IsZero() || o.StartedAt.IsZero() {
			t.Fatal("worker ran without a semantic operation", name)
		}
	}
}

//go:build postgres && river

package rankingworker

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"
	"gxb.local/backend/v2/internal/adapters/postgres"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func (j *recordingJobs) count(name string) int {
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.calls[name]
}

// A-028: another River client takes leadership first; the ranking jobs must
// still run, and a repeated insert must not queue a second copy.
func TestRankingJobsRunWithoutRiverLeadership(t *testing.T) {
	dsn := os.Getenv("GXB_R7_RIVER_DSN")
	if dsn == "" {
		t.Skip("GXB_R7_RIVER_DSN with a migrated disposable database is required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	migrator, e := rivermigrate.New(riverpgxv5.New(p.Raw()), nil)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = migrator.Migrate(c, rivermigrate.DirectionUp, nil); e != nil {
		t.Fatal(e)
	}

	dispatch, e := gen.NewDispatchRegistry()
	if e != nil {
		t.Fatal(e)
	}
	holder, e := riveradapter.NewRuntime(p.Raw(), dispatch, riveradapter.RuntimeConfig{Queues: map[string]int{"leadership_holder": 1}, SoftStopTimeout: time.Second})
	if e != nil {
		t.Fatal(e)
	}
	if e = holder.Start(c); e != nil {
		t.Fatal(e)
	}
	defer holder.Stop(context.Background())
	var leader string
	for leader == "" && c.Err() == nil {
		_ = p.QueryRow(c, `SELECT leader_id FROM river_leader`).Scan(&leader)
		time.Sleep(100 * time.Millisecond)
	}

	jobs := &recordingJobs{calls: map[string]int{}, lastOps: map[string]operation.Context{}}
	ranking, e := New(p, jobs, time.Second)
	if e != nil {
		t.Fatal(e)
	}
	run, stop := context.WithCancel(c)
	done := make(chan error, 1)
	go func() { done <- ranking.Run(run) }()
	for (jobs.count("refresh") < 2 || jobs.count("settle") < 1) && c.Err() == nil {
		time.Sleep(100 * time.Millisecond)
	}
	stop()
	if e = <-done; e != nil {
		t.Fatal(e)
	}
	if jobs.count("refresh") < 2 || jobs.count("settle") < 1 {
		t.Fatalf("ranking jobs did not run beside another leader: %v", jobs.calls)
	}
	var after string
	if e = p.QueryRow(c, `SELECT leader_id FROM river_leader`).Scan(&after); e != nil || after != leader {
		t.Fatalf("leadership moved to the ranking client (%q -> %q, %v); the test proves nothing", leader, after, e)
	}

	idle, e := New(p, jobs, time.Second)
	if e != nil {
		t.Fatal(e)
	}
	idle.schedule(c, refreshArgs{})
	idle.schedule(c, refreshArgs{})
	var queued int
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE kind=$1 AND state='available'`, ScoresRefreshKind).Scan(&queued); e != nil || queued != 1 {
		t.Fatalf("queued refresh copies=%d err=%v, want 1", queued, e)
	}
}

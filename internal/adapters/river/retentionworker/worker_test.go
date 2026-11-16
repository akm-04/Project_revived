//go:build postgres && river

package retentionworker

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/riverqueue/river"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeTx struct{}

func (fakeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return fakeTag(0), nil
}

func (fakeTx) QueryRow(context.Context, string, ...any) tx.Row { return nil }

func (fakeTx) Commit(context.Context) error { return nil }

func (fakeTx) Rollback(context.Context) error { return nil }

type fakeTag int64

func (t fakeTag) RowsAffected() int64 { return int64(t) }

func fakeBegin(context.Context, tx.Options) (tx.Tx, error) { return fakeTx{}, nil }

func TestSweepLogsFailingRuleAndContinues(t *testing.T) {
	var logs []string
	afterRan := false
	sweeper := Sweeper{
		Begin:  fakeBegin,
		Budget: time.Minute,
		Now:    func() time.Time { return time.Unix(0, 0) },
		Logf:   func(format string, arguments ...any) { logs = append(logs, fmt.Sprintf(format, arguments...)) },
		Rules: func(time.Time) []Rule {
			return []Rule{
				{Name: "broken", Delete: func(context.Context, tx.Tx) (int64, error) { return 0, errors.New("rule exploded") }},
				{Name: "after", Delete: func(context.Context, tx.Tx) (int64, error) { afterRan = true; return 0, nil }},
			}
		},
	}
	sweeper.Run(context.Background())
	if !afterRan {
		t.Fatal("the run stopped after a failing rule")
	}
	joined := strings.Join(logs, "\n")
	if !strings.Contains(joined, "broken") || !strings.Contains(joined, "rule exploded") {
		t.Fatalf("failing rule was not logged: %q", joined)
	}
}

func TestSweepStopsAtBudget(t *testing.T) {
	start := time.Unix(0, 0)
	current := start
	firstBatches, secondBatches := 0, 0
	sweeper := Sweeper{
		Begin:  fakeBegin,
		Budget: time.Minute,
		Now:    func() time.Time { return current },
		Logf:   func(string, ...any) {},
		Rules: func(time.Time) []Rule {
			return []Rule{
				{Name: "endless", Delete: func(context.Context, tx.Tx) (int64, error) {
					firstBatches++
					current = start.Add(2 * time.Minute)
					return 1, nil
				}},
				{Name: "after-budget", Delete: func(context.Context, tx.Tx) (int64, error) {
					secondBatches++
					return 0, nil
				}},
			}
		},
	}
	sweeper.Run(context.Background())
	if firstBatches != 1 {
		t.Fatalf("endless rule batches=%d want 1", firstBatches)
	}
	if secondBatches != 0 {
		t.Fatalf("a rule started after the budget was spent (%d batches)", secondBatches)
	}
}

func TestSweepWorkerRegistersAndRuns(t *testing.T) {
	sweeper := &Sweeper{
		Begin:  fakeBegin,
		Budget: time.Minute,
		Now:    func() time.Time { return time.Unix(0, 0) },
		Logf:   func(string, ...any) {},
		Rules:  func(time.Time) []Rule { return nil },
	}
	workers := river.NewWorkers()
	if err := Register(workers, sweeper); err != nil {
		t.Fatal(err)
	}
	if err := Register(workers, sweeper); err == nil {
		t.Fatal("duplicate worker registration accepted")
	}
	if err := (&sweepWorker{Sweeper: sweeper}).Work(context.Background(), &river.Job[sweepArgs]{}); err != nil {
		t.Fatal(err)
	}
}

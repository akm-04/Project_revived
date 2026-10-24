//go:build postgres && river

package riveradapter

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/foundation/obligation"
)

// RuntimeConfig is mechanism-only River execution configuration. Queue names
// and concurrency are operational controls; they do not define gameplay phase
// or ownership semantics.
type RuntimeConfig struct {
	Queues          map[string]int
	SoftStopTimeout time.Duration
	PollOnly        bool
	JobTimeout      time.Duration
}

func (c RuntimeConfig) riverQueues() (map[string]river.QueueConfig, error) {
	if len(c.Queues) == 0 {
		return nil, errors.New("River runtime requires at least one explicit queue")
	}
	out := make(map[string]river.QueueConfig, len(c.Queues))
	for name, maxWorkers := range c.Queues {
		name = strings.TrimSpace(name)
		if name == "" || maxWorkers <= 0 {
			return nil, errors.New("invalid River queue configuration")
		}
		if _, exists := out[name]; exists {
			return nil, errors.New("duplicate normalized River queue name")
		}
		out[name] = river.QueueConfig{MaxWorkers: maxWorkers}
	}
	return out, nil
}

// Runtime composes one River client as both transaction-bound enqueue mechanism
// and worker executor. Domain/application code never receives the River client.
type Runtime struct{ client *river.Client[pgx.Tx] }

func NewRuntime(pool *pgxpool.Pool, dispatcher appgeneration.ObligationDispatcher, cfg RuntimeConfig) (*Runtime, error) {
	if pool == nil {
		return nil, errors.New("nil PostgreSQL pool for River runtime")
	}
	workers, err := NewWorkers(dispatcher)
	if err != nil {
		return nil, err
	}
	queues, err := cfg.riverQueues()
	if err != nil {
		return nil, err
	}
	client, err := river.NewClient(riverpgxv5.New(pool), &river.Config{
		Queues:          queues,
		Workers:         workers,
		SoftStopTimeout: cfg.SoftStopTimeout,
		PollOnly:        cfg.PollOnly,
		JobTimeout:      cfg.JobTimeout,
	})
	if err != nil {
		return nil, err
	}
	return &Runtime{client: client}, nil
}

func (r *Runtime) Start(ctx context.Context) error {
	if r == nil || r.client == nil {
		return errors.New("nil River runtime")
	}
	return r.client.Start(ctx)
}

func (r *Runtime) Stop(ctx context.Context) error {
	if r == nil || r.client == nil {
		return errors.New("nil River runtime")
	}
	return r.client.Stop(ctx)
}

func (r *Runtime) Queue() obligation.Queue {
	if r == nil || r.client == nil {
		return nil
	}
	return Queue{Client: r.client}
}

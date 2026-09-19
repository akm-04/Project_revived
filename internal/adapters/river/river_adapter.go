//go:build postgres && river

package riveradapter

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/riverqueue/river"
	"gxb.local/backend/v2/internal/adapters/postgres"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/foundation/obligation"
	ftx "gxb.local/backend/v2/internal/foundation/tx"
)

// JobKind is a River mechanism identity, not a gameplay semantic identity.
// Semantic obligation kind/profile remain immutable fields in jobArgs and are
// dispatched by the application registry after the worker wakes.
const JobKind = "gxb_obligation"

// Queue intentionally discards River job identity. Correctness and dedupe come
// from canonical GXB state/receipts when workers reload the owner.
type Queue struct{ Client *river.Client[pgx.Tx] }

type jobArgs struct {
	ObligationKind string          `json:"obligation_kind"`
	SemanticKey    string          `json:"semantic_key"`
	Profile        string          `json:"profile,omitempty"`
	ScheduledFor   time.Time       `json:"scheduled_for,omitempty"`
	Queue          string          `json:"queue"`
	Payload        json.RawMessage `json:"payload"`
}

func (jobArgs) Kind() string { return JobKind }

func jobArgsFromObligation(o obligation.Obligation) jobArgs {
	return jobArgs{
		ObligationKind: o.Kind,
		SemanticKey:    o.SemanticKey,
		Profile:        o.Profile,
		ScheduledFor:   o.DueAt.UTC(),
		Queue:          o.Queue,
		Payload:        append(json.RawMessage(nil), o.Args...),
	}
}

func (a jobArgs) obligation() obligation.Obligation {
	var due time.Time
	if !a.ScheduledFor.IsZero() {
		due = a.ScheduledFor.UTC()
	}
	return obligation.Obligation{
		Kind:        a.ObligationKind,
		SemanticKey: a.SemanticKey,
		DueAt:       due,
		Args:        append(json.RawMessage(nil), a.Payload...),
		Queue:       a.Queue,
		Profile:     a.Profile,
	}
}

func (q Queue) InsertTx(ctx context.Context, t ftx.Tx, o obligation.Obligation) error {
	if q.Client == nil {
		return errors.New("nil River client")
	}
	if err := o.Validate(); err != nil {
		return err
	}
	raw, ok := postgres.UnwrapTx(t)
	if !ok {
		return errors.New("transaction is not pgx-backed")
	}
	opts := &river.InsertOpts{Queue: o.Queue}
	if !o.DueAt.IsZero() {
		opts.ScheduledAt = o.DueAt.UTC()
	}
	_, err := q.Client.InsertTx(ctx, raw, jobArgsFromObligation(o), opts)
	return err
}

// obligationWorker is the sole generic River worker for GXB durable
// obligations. It does no gameplay mutation itself; it re-enters application
// authority through an explicit dispatcher whose owner handler reloads/fences
// canonical state.
type obligationWorker struct {
	river.WorkerDefaults[jobArgs]
	Dispatcher appgeneration.ObligationDispatcher
}

func (w *obligationWorker) Work(ctx context.Context, job *river.Job[jobArgs]) error {
	if w == nil || w.Dispatcher == nil {
		return errors.New("nil GXB obligation dispatcher")
	}
	if job == nil {
		return errors.New("nil River obligation job")
	}
	o := job.Args.obligation()
	if err := o.Validate(); err != nil {
		return fmt.Errorf("invalid River obligation evidence: %w", err)
	}
	return w.Dispatcher.Dispatch(ctx, o)
}

// NewWorkers creates the exact v0.47-compatible worker bundle for one static
// mechanism kind. AddWorkerSafely is used so startup misconfiguration returns a
// fail-closed error instead of relying on panic recovery.
func NewWorkers(dispatcher appgeneration.ObligationDispatcher) (*river.Workers, error) {
	if dispatcher == nil {
		return nil, errors.New("nil GXB obligation dispatcher")
	}
	workers := river.NewWorkers()
	if err := river.AddWorkerSafely(workers, &obligationWorker{Dispatcher: dispatcher}); err != nil {
		return nil, err
	}
	return workers, nil
}

var _ obligation.Queue = Queue{}
var _ river.Worker[jobArgs] = (*obligationWorker)(nil)

//go:build postgres && river

package riveradapter

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/riverqueue/river"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/foundation/obligation"
)

type dispatchFunc func(context.Context, obligation.Obligation) error

func (f dispatchFunc) Dispatch(ctx context.Context, o obligation.Obligation) error { return f(ctx, o) }

func TestJobArgsUseStaticRiverKindAndRoundTripEvidence(t *testing.T) {
	in := obligation.Obligation{Kind: "generation.transition", SemanticKey: "k", DueAt: time.Unix(42, 7).UTC(), Args: json.RawMessage(`{"owner":"x"}`), Queue: "lifecycle", Profile: "v1"}
	a := jobArgsFromObligation(in)
	if a.Kind() != JobKind || JobKind != "gxb_obligation" {
		t.Fatalf("kind=%q", a.Kind())
	}
	got := a.obligation()
	if got.Kind != in.Kind || got.SemanticKey != in.SemanticKey || got.Profile != in.Profile || got.Queue != in.Queue || !got.DueAt.Equal(in.DueAt) || string(got.Args) != string(in.Args) {
		t.Fatalf("round trip mismatch: %#v", got)
	}
	a.Payload[0] = '['
	if string(in.Args) == string(a.Payload) {
		t.Fatal("job args alias caller payload")
	}
}

func TestWorkerDispatchesSemanticEvidence(t *testing.T) {
	var got obligation.Obligation
	w := &obligationWorker{Dispatcher: dispatchFunc(func(_ context.Context, o obligation.Obligation) error {
		got = o
		return nil
	})}
	args := jobArgsFromObligation(obligation.Obligation{Kind: "known", SemanticKey: "key", Args: json.RawMessage(`{}`), Queue: "lifecycle", Profile: "p"})
	if err := w.Work(context.Background(), &river.Job[jobArgs]{Args: args}); err != nil {
		t.Fatal(err)
	}
	if got.Kind != "known" || got.SemanticKey != "key" || got.Profile != "p" {
		t.Fatalf("got %#v", got)
	}
}

func TestWorkerFailsClosedForUnknownRouteAndInvalidEvidence(t *testing.T) {
	reg, err := appgeneration.NewDispatchRegistry(appgeneration.DispatchRegistration{Kind: "known", Handler: appgeneration.ObligationHandlerFunc(func(context.Context, obligation.Obligation) error { return nil })})
	if err != nil {
		t.Fatal(err)
	}
	w := &obligationWorker{Dispatcher: reg}
	unknown := jobArgsFromObligation(obligation.Obligation{Kind: "unknown", SemanticKey: "key", Args: json.RawMessage(`{}`), Queue: "lifecycle"})
	if err := w.Work(context.Background(), &river.Job[jobArgs]{Args: unknown}); !errors.Is(err, appgeneration.ErrUnknownObligationRoute) {
		t.Fatalf("unknown route got %v", err)
	}
	invalid := unknown
	invalid.Payload = json.RawMessage(`{`)
	if err := w.Work(context.Background(), &river.Job[jobArgs]{Args: invalid}); err == nil {
		t.Fatal("invalid payload succeeded")
	}
	if err := (*obligationWorker)(nil).Work(context.Background(), &river.Job[jobArgs]{Args: unknown}); err == nil {
		t.Fatal("nil worker succeeded")
	}
}

func TestNewWorkersRejectsNilDispatcher(t *testing.T) {
	if _, err := NewWorkers(nil); err == nil {
		t.Fatal("nil dispatcher succeeded")
	}
	if _, err := NewWorkers(dispatchFunc(func(context.Context, obligation.Obligation) error { return nil })); err != nil {
		t.Fatal(err)
	}
}

package generation

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/obligation"
)

func obligationFixture(kind, profile string) obligation.Obligation {
	return obligation.Obligation{
		Kind: kind, Profile: profile, SemanticKey: "activity/server:7/generation:1/settle",
		DueAt: time.Unix(500, 0).UTC(), Args: json.RawMessage(`{"generation":"g1"}`), Queue: "lifecycle",
	}
}

func TestDispatchRegistryRoutesExactKindAndProfile(t *testing.T) {
	var got obligation.Obligation
	r, err := NewDispatchRegistry(DispatchRegistration{Kind: "generation.transition", Profile: "v1", Handler: ObligationHandlerFunc(func(_ context.Context, o obligation.Obligation) error {
		got = o
		// Try to mutate the handler copy; caller evidence must not change.
		o.Args[0] = '['
		return nil
	})})
	if err != nil {
		t.Fatal(err)
	}
	in := obligationFixture("generation.transition", "v1")
	before := append([]byte(nil), in.Args...)
	if err := r.Dispatch(context.Background(), in); err != nil {
		t.Fatal(err)
	}
	if got.Kind != in.Kind || got.Profile != in.Profile || got.SemanticKey != in.SemanticKey {
		t.Fatalf("dispatch mismatch: %#v", got)
	}
	if string(in.Args) != string(before) {
		t.Fatal("handler mutated caller evidence")
	}
}

func TestDispatchRegistryUnknownRouteFailsClosed(t *testing.T) {
	r, err := NewDispatchRegistry(DispatchRegistration{Kind: "known", Profile: "p1", Handler: ObligationHandlerFunc(func(context.Context, obligation.Obligation) error { return nil })})
	if err != nil {
		t.Fatal(err)
	}
	for _, in := range []obligation.Obligation{obligationFixture("unknown", "p1"), obligationFixture("known", "p2")} {
		err := r.Dispatch(context.Background(), in)
		if !errors.Is(err, ErrUnknownObligationRoute) {
			t.Fatalf("route %s/%s got %v", in.Kind, in.Profile, err)
		}
		var typed *UnknownObligationRouteError
		if !errors.As(err, &typed) || typed.SemanticKey != in.SemanticKey {
			t.Fatalf("missing observable route evidence: %v", err)
		}
	}
}

func TestDispatchRegistryRejectsInvalidOrDuplicateRegistration(t *testing.T) {
	h := ObligationHandlerFunc(func(context.Context, obligation.Obligation) error { return nil })
	for _, regs := range [][]DispatchRegistration{
		{{Kind: "", Handler: h}},
		{{Kind: "known", Handler: nil}},
		{{Kind: "known", Profile: "p", Handler: h}, {Kind: " known ", Profile: "p", Handler: h}},
	} {
		if _, err := NewDispatchRegistry(regs...); !errors.Is(err, ErrInvalidDispatchRegistration) {
			t.Fatalf("got %v", err)
		}
	}
}

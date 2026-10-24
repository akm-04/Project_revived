//go:build postgres && river

package riveradapter

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/foundation/obligation"
)

func TestRuntimeConfigRequiresExplicitBoundedQueues(t *testing.T) {
	bad := []RuntimeConfig{
		{},
		{Queues: map[string]int{"": 1}},
		{Queues: map[string]int{"q": 0}},
		{Queues: map[string]int{"q": -1}},
		{Queues: map[string]int{" q ": 1, "q": 2}},
	}
	for _, cfg := range bad {
		if _, err := cfg.riverQueues(); err == nil {
			t.Fatalf("config %#v succeeded", cfg)
		}
	}
	got, err := (RuntimeConfig{Queues: map[string]int{" lifecycle ": 2}}).riverQueues()
	if err != nil {
		t.Fatal(err)
	}
	if q, ok := got["lifecycle"]; !ok || q.MaxWorkers != 2 {
		t.Fatalf("queues=%#v", got)
	}
}

func TestRuntimeFailsClosedWithoutPoolOrDispatcher(t *testing.T) {
	if _, err := NewRuntime(nil, dispatchFunc(func(context.Context, obligation.Obligation) error { return nil }), RuntimeConfig{Queues: map[string]int{"q": 1}}); err == nil {
		t.Fatal("nil pool succeeded")
	}
	if q := (*Runtime)(nil).Queue(); q != nil {
		t.Fatal("nil runtime returned queue")
	}
}

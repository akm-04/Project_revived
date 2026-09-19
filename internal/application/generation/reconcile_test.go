package generation

import (
	"context"
	"errors"
	"testing"
	"time"
)

type reconcileProviderFunc struct {
	name string
	fn   func(context.Context, TimedOperation, int) (ReconcileResult, error)
}

func (p *reconcileProviderFunc) Name() string { return p.name }
func (p *reconcileProviderFunc) Reconcile(ctx context.Context, op TimedOperation, limit int) (ReconcileResult, error) {
	return p.fn(ctx, op, limit)
}

func TestReconcileKernelUsesOneDecisionInstantAcrossProviders(t *testing.T) {
	a := &fakeTimeAuthority{at: time.Unix(900, 0).UTC()}
	var seen []time.Time
	mk := func(name string) *reconcileProviderFunc {
		return &reconcileProviderFunc{name: name, fn: func(_ context.Context, op TimedOperation, limit int) (ReconcileResult, error) {
			seen = append(seen, op.DecisionAt())
			return ReconcileResult{Provider: name, Scanned: limit}, nil
		}}
	}
	reg, err := NewReconcileRegistry(mk("activity_fixture"), mk("guild_fixture"))
	if err != nil {
		t.Fatal(err)
	}
	out, err := (ReconcileKernel{Binder: Binder{Time: a}, Providers: reg}).Run(context.Background(), opFixture(), 7)
	if err != nil {
		t.Fatal(err)
	}
	if a.calls != 1 || len(seen) != 2 || seen[0] != seen[1] || seen[0] != a.at || len(out) != 2 {
		t.Fatalf("calls=%d seen=%v out=%v", a.calls, seen, out)
	}
}

func TestReconcileKernelRejectsUnsupportedAndUnboundedRuns(t *testing.T) {
	reg, err := NewReconcileRegistry()
	if err != nil {
		t.Fatal(err)
	}
	k := ReconcileKernel{Binder: Binder{Time: &fakeTimeAuthority{at: time.Unix(1, 0).UTC()}}, Providers: reg}
	if _, err := k.Run(context.Background(), opFixture(), 1); !errors.Is(err, ErrNoReconcileProviders) {
		t.Fatalf("empty providers: %v", err)
	}
	p := &reconcileProviderFunc{name: "fixture", fn: func(context.Context, TimedOperation, int) (ReconcileResult, error) {
		return ReconcileResult{Provider: "fixture"}, nil
	}}
	reg, _ = NewReconcileRegistry(p)
	k.Providers = reg
	for _, limit := range []int{0, -1, MaxReconcileBatch + 1} {
		if _, err := k.Run(context.Background(), opFixture(), limit); !errors.Is(err, ErrInvalidReconciler) {
			t.Fatalf("limit=%d err=%v", limit, err)
		}
	}
}

func TestReconcileKernelFailsOnProviderErrorOrInvalidEvidence(t *testing.T) {
	boom := errors.New("owner unavailable")
	for _, p := range []*reconcileProviderFunc{
		{name: "fixture", fn: func(context.Context, TimedOperation, int) (ReconcileResult, error) { return ReconcileResult{}, boom }},
		{name: "fixture", fn: func(context.Context, TimedOperation, int) (ReconcileResult, error) {
			return ReconcileResult{Provider: "other"}, nil
		}},
		{name: "fixture", fn: func(context.Context, TimedOperation, int) (ReconcileResult, error) {
			return ReconcileResult{Provider: "fixture", Scanned: 2}, nil
		}},
	} {
		reg, _ := NewReconcileRegistry(p)
		_, err := (ReconcileKernel{Binder: Binder{Time: &fakeTimeAuthority{at: time.Unix(1, 0).UTC()}}, Providers: reg}).Run(context.Background(), opFixture(), 1)
		if err == nil {
			t.Fatal("invalid provider result succeeded")
		}
	}
}

func TestReconcileRegistryRejectsNilBlankAndDuplicateProviders(t *testing.T) {
	ok := &reconcileProviderFunc{name: "same", fn: func(context.Context, TimedOperation, int) (ReconcileResult, error) {
		return ReconcileResult{Provider: "same"}, nil
	}}
	blank := &reconcileProviderFunc{name: " ", fn: ok.fn}
	for _, providers := range [][]ReconcileProvider{{nil}, {blank}, {ok, ok}} {
		if _, err := NewReconcileRegistry(providers...); !errors.Is(err, ErrInvalidReconciler) {
			t.Fatalf("got %v", err)
		}
	}
}

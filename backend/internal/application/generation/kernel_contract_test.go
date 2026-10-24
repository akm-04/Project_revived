package generation

import (
	"context"
	"encoding/json"
	"errors"
	"sync"
	"testing"
	"time"

	domaingeneration "gxb.local/backend/v2/internal/domain/generation"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
)

type fixtureOwnerState struct {
	mu          sync.Mutex
	generation  domaingeneration.GenerationID
	dueAt       time.Time
	settled     bool
	settleCount int
	wakeup      bool
	wakeups     int
}

type fixtureArgs struct {
	Generation string `json:"generation"`
}

type fixtureOwnerHandler struct {
	state      *fixtureOwnerState
	decisionAt time.Time
}

var errFixtureNotDue = errors.New("fixture transition not due")

func (h fixtureOwnerHandler) HandleObligation(_ context.Context, o obligation.Obligation) error {
	var args fixtureArgs
	if err := json.Unmarshal(o.Args, &args); err != nil {
		return err
	}
	h.state.mu.Lock()
	defer h.state.mu.Unlock()
	if args.Generation != h.state.generation.UUID().String() {
		return nil // stale generation: safe semantic no-op
	}
	if h.state.settled {
		return nil // duplicate delivery: already converged
	}
	if h.decisionAt.Before(h.state.dueAt) {
		return errFixtureNotDue
	}
	h.state.settled = true
	h.state.settleCount++
	h.state.wakeup = false
	return nil
}

type fixtureReconciler struct{ state *fixtureOwnerState }

func (p *fixtureReconciler) Name() string { return "fixture_owner" }
func (p *fixtureReconciler) Reconcile(_ context.Context, op TimedOperation, limit int) (ReconcileResult, error) {
	p.state.mu.Lock()
	defer p.state.mu.Unlock()
	result := ReconcileResult{Provider: p.Name()}
	if limit == 0 {
		return result, nil
	}
	result.Scanned = 1
	if p.state.settled || op.DecisionAt().Before(p.state.dueAt) {
		result.Noops = 1
		return result, nil
	}
	if !p.state.wakeup {
		p.state.wakeup = true
		p.state.wakeups++
		result.Wakeups = 1
	} else {
		result.Noops = 1
	}
	return result, nil
}

func generationID(last byte) domaingeneration.GenerationID {
	var u ids.UUID
	u[15] = last
	id, err := domaingeneration.GenerationIDFrom(u)
	if err != nil {
		panic(err)
	}
	return id
}

func fixtureObligation(g domaingeneration.GenerationID, due time.Time) obligation.Obligation {
	b, _ := json.Marshal(fixtureArgs{Generation: g.UUID().String()})
	return obligation.Obligation{Kind: "fixture.transition", SemanticKey: "fixture/settle", DueAt: due.UTC(), Args: b, Queue: "fixture", Profile: "v1"}
}

func TestFixtureOwnerDuplicateStaleLateDeliveryConvergesExactlyOnce(t *testing.T) {
	due := time.Unix(1000, 0).UTC()
	state := &fixtureOwnerState{generation: generationID(1), dueAt: due, wakeup: true}
	h := fixtureOwnerHandler{state: state, decisionAt: due.Add(time.Hour)}
	reg, err := NewDispatchRegistry(DispatchRegistration{Kind: "fixture.transition", Profile: "v1", Handler: h})
	if err != nil {
		t.Fatal(err)
	}
	current := fixtureObligation(state.generation, due)
	if err := reg.Dispatch(context.Background(), current); err != nil {
		t.Fatal(err)
	}
	if err := reg.Dispatch(context.Background(), current); err != nil {
		t.Fatal(err)
	}
	if state.settleCount != 1 {
		t.Fatalf("duplicate deliveries settled %d times", state.settleCount)
	}

	// Slot/generation reuse: an old late job cannot settle the newer generation.
	state.mu.Lock()
	state.generation = generationID(2)
	state.settled = false
	state.dueAt = due.Add(2 * time.Hour)
	state.mu.Unlock()
	if err := reg.Dispatch(context.Background(), current); err != nil {
		t.Fatal(err)
	}
	if state.settleCount != 1 || state.settled {
		t.Fatalf("stale job affected newer generation: count=%d settled=%v", state.settleCount, state.settled)
	}
}

func TestFixtureOwnerEarlyDeliveryFailsInsteadOfForcingTransition(t *testing.T) {
	due := time.Unix(2000, 0).UTC()
	state := &fixtureOwnerState{generation: generationID(1), dueAt: due}
	h := fixtureOwnerHandler{state: state, decisionAt: due.Add(-time.Second)}
	reg, _ := NewDispatchRegistry(DispatchRegistration{Kind: "fixture.transition", Profile: "v1", Handler: h})
	if err := reg.Dispatch(context.Background(), fixtureObligation(state.generation, due)); !errors.Is(err, errFixtureNotDue) {
		t.Fatalf("got %v", err)
	}
	if state.settleCount != 0 || state.settled {
		t.Fatal("early delivery forced semantic transition")
	}
}

func TestFixtureReconcilerRecoversMissingWakeupAcrossRestartWithoutTickReplay(t *testing.T) {
	due := time.Unix(3000, 0).UTC()
	state := &fixtureOwnerState{generation: generationID(1), dueAt: due}
	a := &fakeTimeAuthority{at: due.Add(72 * time.Hour)} // very late still yields one wakeup, not 72h of ticks
	reg, _ := NewReconcileRegistry(&fixtureReconciler{state: state})
	kernel := ReconcileKernel{Binder: Binder{Time: a}, Providers: reg}
	out, err := kernel.Run(context.Background(), opFixture(), 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(out) != 1 || out[0].Wakeups != 1 || state.wakeups != 1 || !state.wakeup {
		t.Fatalf("first reconcile out=%v state=%#v", out, state)
	}

	// New kernel/provider instance represents process restart over the same
	// durable owner truth. Existing wakeup is not duplicated.
	reg2, _ := NewReconcileRegistry(&fixtureReconciler{state: state})
	kernel2 := ReconcileKernel{Binder: Binder{Time: &fakeTimeAuthority{at: a.at}}, Providers: reg2}
	out, err = kernel2.Run(context.Background(), opFixture(), 10)
	if err != nil {
		t.Fatal(err)
	}
	if out[0].Wakeups != 0 || state.wakeups != 1 {
		t.Fatalf("restart duplicated wakeup: out=%v wakeups=%d", out, state.wakeups)
	}

	// Simulate discarded/lost River delivery: canonical owner is still due and
	// unsettled, so a later sweep recreates exactly one wakeup.
	state.mu.Lock()
	state.wakeup = false
	state.mu.Unlock()
	out, err = kernel2.Run(context.Background(), opFixture(), 10)
	if err != nil {
		t.Fatal(err)
	}
	if out[0].Wakeups != 1 || state.wakeups != 2 || !state.wakeup {
		t.Fatalf("missing wakeup not recovered: out=%v wakeups=%d", out, state.wakeups)
	}
}

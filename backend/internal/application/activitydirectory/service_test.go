package activitydirectory

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/activity"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

type providerFunc func(context.Context, ProjectionContext) (activity.Projection, bool, error)

func (f providerFunc) Project(ctx context.Context, pc ProjectionContext) (activity.Projection, bool, error) {
	return f(ctx, pc)
}

type staticTime struct{ at time.Time }

func (s staticTime) Now(context.Context) (time.Time, error) { return s.at, nil }

func actor(t *testing.T) identity.ActorContext {
	t.Helper()
	mk := func(b byte) ids.UUID { var u ids.UUID; u[15] = b; return u }
	aid, _ := identity.AccountIDFrom(mk(1))
	sid, _ := identity.SessionIDFrom(mk(2))
	cid, _ := identity.ContextIDFrom(mk(3))
	return identity.ActorContext{AccountID: aid, AccountUID: "uid", SessionID: sid, ContextID: cid, LogicalServerID: 7, PlayerID: 700001, ContextGeneration: 2, SessionLivenessVersion: 3, ContextLivenessVersion: 4}
}

func TestRegistryEmptyAndCollisions(t *testing.T) {
	if r, err := NewRegistry(nil, nil); err != nil || r.Len() != 0 {
		t.Fatalf("empty registry: len=%d err=%v", r.Len(), err)
	}
	p := providerFunc(func(context.Context, ProjectionContext) (activity.Projection, bool, error) {
		return activity.Projection{}, false, nil
	})
	base := Registration{Name: "a", TableID: 10, RuntimeCapability: "cap.a", Provider: p}
	for name, regs := range map[string][]Registration{
		"name":  {base, {Name: "a", TableID: 11, RuntimeCapability: "cap.b", Provider: p}},
		"table": {base, {Name: "b", TableID: 10, RuntimeCapability: "cap.b", Provider: p}},
		"cap":   {base, {Name: "b", TableID: 11, RuntimeCapability: "cap.a", Provider: p}},
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := NewRegistry(regs, nil); err == nil {
				t.Fatal("expected collision")
			}
		})
	}
}

func TestRegistryContentPrerequisiteSeparateFromRuntimeActivation(t *testing.T) {
	p := providerFunc(func(context.Context, ProjectionContext) (activity.Projection, bool, error) {
		return activity.Projection{}, false, nil
	})
	reg := Registration{Name: "a", TableID: 10, RuntimeCapability: "runtime.a", ContentCapability: "content.a", Provider: p}
	if _, err := NewRegistry([]Registration{reg}, nil); err == nil {
		t.Fatal("missing content prerequisite accepted")
	}
	caps, err := NewStaticContentCapabilities([]string{"content.a"})
	if err != nil {
		t.Fatal(err)
	}
	r, err := NewRegistry([]Registration{reg}, caps)
	if err != nil || r.Len() != 1 {
		t.Fatalf("qualified registration len=%d err=%v", r.Len(), err)
	}
	// Content support alone never activates an Activity owner.
	empty, err := NewRegistry(nil, caps)
	if err != nil || empty.Len() != 0 {
		t.Fatalf("content-only activation: len=%d err=%v", empty.Len(), err)
	}
}

func TestListSortsValidatesActorAndClonesDetails(t *testing.T) {
	seen := make([]identity.ActorContext, 0, 2)
	mkp := func(id int64) providerFunc {
		return func(_ context.Context, pc ProjectionContext) (activity.Projection, bool, error) {
			seen = append(seen, pc.Actor)
			return activity.Projection{TableID: id, IsOpen: 1, StartTime: 100, EndTime: 200, Days: 0, Details: map[string]any{"nested": []any{int64(1)}}}, true, nil
		}
	}
	r, err := NewRegistry([]Registration{
		{Name: "b", TableID: 20, RuntimeCapability: "b", Provider: mkp(20)},
		{Name: "a", TableID: 10, RuntimeCapability: "a", Provider: mkp(10)},
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	d := Directory{Registry: r}
	at := time.Unix(123, 0).UTC()
	a := actor(t)
	rows, err := d.ListAt(context.Background(), a, at)
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 || rows[0].TableID != 10 || rows[1].TableID != 20 {
		t.Fatalf("ordering %#v", rows)
	}
	if len(seen) != 2 || seen[0].PlayerID != a.PlayerID || seen[0].LogicalServerID != a.LogicalServerID || seen[0].AccountUID != a.AccountUID {
		t.Fatalf("actor not retained %#v", seen)
	}
	m := rows[0].Details.(map[string]any)
	m["nested"].([]any)[0] = int64(99)
	rows2, err := d.ListAt(context.Background(), a, at)
	if err != nil {
		t.Fatal(err)
	}
	if rows2[0].Details.(map[string]any)["nested"].([]any)[0].(int64) != 1 {
		t.Fatal("details alias escaped directory")
	}
}

func TestProviderMismatchMalformedAndAbsentFailClosed(t *testing.T) {
	bad := providerFunc(func(context.Context, ProjectionContext) (activity.Projection, bool, error) {
		return activity.Projection{TableID: 99, IsOpen: 1}, true, nil
	})
	r, _ := NewRegistry([]Registration{{Name: "bad", TableID: 10, RuntimeCapability: "bad", Provider: bad}}, nil)
	_, err := (Directory{Registry: r}).ListAt(context.Background(), actor(t), time.Unix(1, 0).UTC())
	if !errors.Is(err, ErrProviderMismatch) {
		t.Fatalf("want mismatch got %v", err)
	}
	abs := providerFunc(func(context.Context, ProjectionContext) (activity.Projection, bool, error) {
		return activity.Projection{}, false, nil
	})
	r, _ = NewRegistry([]Registration{{Name: "abs", TableID: 10, RuntimeCapability: "abs", Provider: abs}}, nil)
	_, ok, err := (Directory{Registry: r}).LookupAt(context.Background(), actor(t), time.Unix(1, 0).UTC(), 10)
	if err != nil || ok {
		t.Fatalf("absent ok=%t err=%v", ok, err)
	}
}

func TestRuntimeEmptyDoesNotRequireTimeAndUnknownLookupDoesNotSample(t *testing.T) {
	r, _ := NewRegistry(nil, nil)
	s := Runtime{Directory: Directory{Registry: r}}
	rows, err := s.List(context.Background(), actor(t))
	if err != nil || len(rows) != 0 {
		t.Fatalf("rows=%v err=%v", rows, err)
	}
	_, ok, err := s.Lookup(context.Background(), actor(t), 1032)
	if err != nil || ok {
		t.Fatalf("ok=%t err=%v", ok, err)
	}
}

func TestRuntimeUsesSingleAuthorityInstantForRegisteredProvider(t *testing.T) {
	want := time.Unix(500, 0).UTC()
	calls := 0
	p := providerFunc(func(_ context.Context, pc ProjectionContext) (activity.Projection, bool, error) {
		calls++
		if !pc.DecisionAt.Equal(want) {
			t.Fatalf("at=%v", pc.DecisionAt)
		}
		return activity.Projection{TableID: 10, IsOpen: 0, Days: -1, Details: map[string]any{}}, true, nil
	})
	r, _ := NewRegistry([]Registration{{Name: "p", TableID: 10, RuntimeCapability: "p", Provider: p}}, nil)
	s := Runtime{Directory: Directory{Registry: r}, Time: staticTime{at: want}}
	rows, err := s.List(context.Background(), actor(t))
	if err != nil || len(rows) != 1 || calls != 1 {
		t.Fatalf("rows=%v calls=%d err=%v", rows, calls, err)
	}
}

func TestMalformedProjectionAndUnsupportedDetailsFailClosed(t *testing.T) {
	for name, pj := range map[string]activity.Projection{
		"is_open": {TableID: 10, IsOpen: 2},
		"details": {TableID: 10, IsOpen: 1, Details: map[string]any{"bad": make(chan int)}},
	} {
		t.Run(name, func(t *testing.T) {
			p := providerFunc(func(context.Context, ProjectionContext) (activity.Projection, bool, error) { return pj, true, nil })
			r, err := NewRegistry([]Registration{{Name: name, TableID: 10, RuntimeCapability: "cap." + name, Provider: p}}, nil)
			if err != nil {
				t.Fatal(err)
			}
			_, err = (Directory{Registry: r}).ListAt(context.Background(), actor(t), time.Unix(1, 0).UTC())
			if err == nil {
				t.Fatal("malformed projection accepted")
			}
		})
	}
}

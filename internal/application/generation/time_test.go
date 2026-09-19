package generation

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

type fakeTimeAuthority struct {
	at    time.Time
	err   error
	calls int
}

func (f *fakeTimeAuthority) Now(context.Context) (time.Time, error) {
	f.calls++
	return f.at, f.err
}

func opFixture() operation.Context {
	refs, _ := policy.NewSet(policy.Ref{Name: "content", Version: "rev"})
	var id ids.UUID
	id[15] = 9
	var seed [32]byte
	seed[0] = 3
	return operation.Context{ID: id, StartedAt: time.Unix(100, 123).UTC(), EntropySeed: seed, Policies: refs}
}

func TestTimedOperationPreservesOperationAndNormalizesDecisionUTC(t *testing.T) {
	op := opFixture()
	zone := time.FixedZone("other", 6*60*60)
	decision := time.Date(2026, 9, 9, 12, 34, 56, 7, zone)
	got, err := NewTimedOperation(op, decision)
	if err != nil {
		t.Fatal(err)
	}
	if got.Operation().ID != op.ID || got.Operation().StartedAt != op.StartedAt || got.Operation().EntropySeed != op.EntropySeed || !got.Operation().Policies.Equal(op.Policies) {
		t.Fatal("semantic operation changed during timed binding")
	}
	if got.DecisionAt().Location() != time.UTC || !got.DecisionAt().Equal(decision) {
		t.Fatalf("decision=%v location=%v", got.DecisionAt(), got.DecisionAt().Location())
	}
}

func TestBinderSamplesExactlyOnceAndFailsClosed(t *testing.T) {
	op := opFixture()
	a := &fakeTimeAuthority{at: time.Unix(200, 0).UTC()}
	got, err := (Binder{Time: a}).Bind(context.Background(), op)
	if err != nil {
		t.Fatal(err)
	}
	for attempt := 0; attempt < 4; attempt++ {
		if got.DecisionAt() != time.Unix(200, 0).UTC() || got.Operation().ID != op.ID {
			t.Fatal("retry-stable binding changed")
		}
	}
	if a.calls != 1 {
		t.Fatalf("authority sampled %d times", a.calls)
	}

	boom := errors.New("db time unavailable")
	a = &fakeTimeAuthority{err: boom}
	if _, err := (Binder{Time: a}).Bind(context.Background(), op); !errors.Is(err, boom) {
		t.Fatalf("got %v", err)
	}
	if a.calls != 1 {
		t.Fatalf("failure sampled %d times", a.calls)
	}
}

func TestTimedOperationRejectsInvalidState(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	bad := []struct {
		name string
		op   operation.Context
		at   time.Time
	}{
		{"zero operation", operation.Context{}, now},
		{"zero decision", opFixture(), time.Time{}},
	}
	for _, tc := range bad {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := NewTimedOperation(tc.op, tc.at); !errors.Is(err, ErrInvalidTimedOperation) {
				t.Fatalf("got %v", err)
			}
		})
	}
	if _, err := (Binder{}).Bind(context.Background(), opFixture()); err == nil {
		t.Fatal("nil time authority succeeded")
	}
}

func TestTimedOperationDoesNotInventMonotonicClampForBackwardDatabaseClock(t *testing.T) {
	op := opFixture()
	decision := op.StartedAt.Add(-6 * time.Hour)
	got, err := NewTimedOperation(op, decision)
	if err != nil {
		t.Fatal(err)
	}
	if got.DecisionAt() != decision.UTC() {
		t.Fatalf("database decision was silently clamped/recomputed: got=%v want=%v", got.DecisionAt(), decision.UTC())
	}
	if !got.DecisionAt().Before(got.Operation().StartedAt) {
		t.Fatalf("fixture no longer exercises backward-clock discontinuity: decision=%v started=%v", got.DecisionAt(), got.Operation().StartedAt)
	}
}

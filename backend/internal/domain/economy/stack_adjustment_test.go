package economy

import (
	"errors"
	"math"
	"testing"
	"time"
)

func TestR5StackAdjustment(t *testing.T) {
	now := time.Unix(100, 0)
	def := StackDefinition{ItemID: 42, StackCap: 10, OverflowToMail: true}
	for _, c := range []struct{ qty, delta, want int64 }{{15, -1, 14}, {15, -15, 0}, {10, -9, 1}, {0, 0, 0}, {math.MaxInt64, -math.MaxInt64, 0}} {
		s := StackState{PlayerID: 100001, ItemID: 42, Quantity: c.qty, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
		got, err := s.PlanAdjustment(c.delta, def, now)
		if err != nil || got.State.Quantity != c.want || got.Overflow != 0 {
			t.Fatalf("%+v: %+v %v", c, got, err)
		}
		if c.delta == 0 && got.State != s {
			t.Fatal("zero mutation")
		}
	}
	s := StackState{PlayerID: 100001, ItemID: 42, Quantity: 9, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	for _, d := range []int64{-10, math.MinInt64} {
		if _, err := s.PlanAdjustment(d, def, now); !errors.Is(err, ErrInsufficientBalance) {
			t.Fatal(d, err)
		}
	}
	got, err := s.PlanAdjustment(5, def, now)
	if err != nil || got.Fit != 1 || got.Overflow != 4 {
		t.Fatal(got, err)
	}
	s.Quantity = 15
	if _, err := s.PlanAdjustment(1, def, now); err == nil {
		t.Fatal("overcap credit")
	}
}

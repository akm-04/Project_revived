package economy

import (
	"math"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
)

func floorBalance(at time.Time, amount int64) ScalarBalance {
	return ScalarBalance{PlayerID: identity.PlayerID(100001), ResourceKey: "glue", Amount: amount, StateVersion: 1, UpdatedAt: at}
}

func TestDailyFloorCreditsOnceAndPreservesAboveFloor(t *testing.T) {
	at := time.Date(2026, 11, 4, 12, 0, 0, 0, time.UTC)
	day := modes.Day(at)
	balance := floorBalance(at, 20)
	first, err := balance.PlanDailyFloor(nil, day, 100, at)
	if err != nil || first.Balance.Amount != 100 || first.Credit != 80 || !first.Changed || first.Anchor.StateVersion != 1 {
		t.Fatalf("first refill: %+v, %v", first, err)
	}
	if balance.Amount != 20 || balance.StateVersion != 1 {
		t.Fatal("planner mutated its input balance")
	}
	spent, err := first.Balance.Debit(40, at.Add(time.Minute))
	if err != nil {
		t.Fatal(err)
	}
	anchor := first.Anchor
	sameDay, err := spent.PlanDailyFloor(&anchor, day, 200, at.Add(2*time.Minute))
	if err != nil || sameDay.Balance != spent || sameDay.Anchor != anchor || sameDay.Credit != 0 || sameDay.Changed {
		t.Fatalf("same-day spend or policy change refilled: %+v, %v", sameDay, err)
	}
	next, err := spent.PlanDailyFloor(&anchor, day+1, 100, at.Add(24*time.Hour))
	if err != nil || next.Balance.Amount != 100 || next.Credit != 40 || next.Anchor.StateVersion != 2 {
		t.Fatalf("next day: %+v, %v", next, err)
	}
	if anchor != first.Anchor {
		t.Fatal("planner mutated its input anchor")
	}
	above := floorBalance(at, 150)
	preserved, err := above.PlanDailyFloor(nil, day, 100, at)
	if err != nil || preserved.Balance != above || preserved.Credit != 0 || !preserved.Changed {
		t.Fatalf("above-floor amount was capped: %+v, %v", preserved, err)
	}
	zero, err := floorBalance(at, 0).PlanDailyFloor(nil, day, 0, at)
	if err != nil || zero.Credit != 0 || !zero.Changed || zero.Anchor.GameDay != day {
		t.Fatalf("zero floor must still record the day: %+v, %v", zero, err)
	}
}

func TestDailyFloorUsesCapturedFiveAMGameDay(t *testing.T) {
	before := time.Date(2026, 11, 4, 20, 59, 59, 0, time.UTC)
	initial, err := floorBalance(before, 0).PlanDailyFloor(nil, modes.Day(before), 100, before)
	if err != nil {
		t.Fatal(err)
	}
	spent, err := initial.Balance.Debit(100, before)
	if err != nil {
		t.Fatal(err)
	}
	after := before.Add(time.Second)
	result, err := spent.PlanDailyFloor(&initial.Anchor, modes.Day(after), 100, after)
	if err != nil || result.Credit != 100 || result.Anchor.GameDay != initial.Anchor.GameDay+1 {
		t.Fatalf("05:00 GMT+8 boundary: %+v, %v", result, err)
	}
}

func TestDailyFloorRejectsInvalidStateAndOverflow(t *testing.T) {
	at := time.Date(2026, 11, 4, 12, 0, 0, 0, time.UTC)
	day := modes.Day(at)
	anchor := ScalarDailyFloor{PlayerID: identity.PlayerID(100001), ResourceKey: "glue", GameDay: day, StateVersion: 1, UpdatedAt: at}
	tests := []struct {
		name   string
		mutate func(*ScalarBalance, *ScalarDailyFloor, *int64, *int64, *time.Time)
	}{
		{"invalid player", func(balance *ScalarBalance, _ *ScalarDailyFloor, _, _ *int64, _ *time.Time) { balance.PlayerID = 0 }},
		{"wrong anchor player", func(_ *ScalarBalance, anchor *ScalarDailyFloor, _, _ *int64, _ *time.Time) { anchor.PlayerID++ }},
		{"wrong resource", func(_ *ScalarBalance, anchor *ScalarDailyFloor, _, _ *int64, _ *time.Time) {
			anchor.ResourceKey = "crystal"
		}},
		{"invalid balance version", func(balance *ScalarBalance, _ *ScalarDailyFloor, _, _ *int64, _ *time.Time) { balance.StateVersion = 0 }},
		{"invalid anchor version", func(_ *ScalarBalance, anchor *ScalarDailyFloor, _, _ *int64, _ *time.Time) { anchor.StateVersion = 0 }},
		{"negative floor", func(_ *ScalarBalance, _ *ScalarDailyFloor, _ *int64, minimum *int64, _ *time.Time) { *minimum = -1 }},
		{"missing time", func(_ *ScalarBalance, _ *ScalarDailyFloor, _, _ *int64, now *time.Time) { *now = time.Time{} }},
		{"stale day", func(_ *ScalarBalance, _ *ScalarDailyFloor, captured *int64, _ *int64, _ *time.Time) {
			*captured = *captured - 1
		}},
		{"future anchor", func(_ *ScalarBalance, anchor *ScalarDailyFloor, _, _ *int64, _ *time.Time) {
			anchor.UpdatedAt = at.Add(time.Second)
		}},
		{"future balance", func(balance *ScalarBalance, _ *ScalarDailyFloor, _, _ *int64, _ *time.Time) {
			balance.UpdatedAt = at.Add(time.Second)
		}},
		{"anchor overflow", func(_ *ScalarBalance, anchor *ScalarDailyFloor, captured *int64, _ *int64, now *time.Time) {
			anchor.StateVersion = math.MaxInt64
			*captured = *captured + 1
			*now = at.Add(24 * time.Hour)
		}},
		{"balance overflow", func(balance *ScalarBalance, anchor *ScalarDailyFloor, captured *int64, _ *int64, now *time.Time) {
			balance.StateVersion = math.MaxInt64
			*captured = *captured + 1
			*now = at.Add(24 * time.Hour)
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			balance, previous, captured, minimum, now := floorBalance(at, 1), anchor, day, int64(100), at
			test.mutate(&balance, &previous, &captured, &minimum, &now)
			if _, err := balance.PlanDailyFloor(&previous, captured, minimum, now); err == nil {
				t.Fatal("invalid daily-floor plan accepted")
			}
		})
	}
	maximum := floorBalance(at, math.MaxInt64)
	maximum.StateVersion = math.MaxInt64
	result, err := maximum.PlanDailyFloor(nil, day, math.MaxInt64, at)
	if err != nil || result.Balance != maximum || result.Credit != 0 {
		t.Fatalf("unchanged maximum balance rejected: %+v, %v", result, err)
	}
}

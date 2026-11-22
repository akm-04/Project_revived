package events

import (
	"errors"
	"testing"
	"time"
)

const testCycleJSON = `{"revision":1,"anchor":"2026-01-01T05:00:00+08:00","entries":[` +
	`{"activity_id":1008,"duration":"3d"},{"activity_id":1009,"duration":"3d"},` +
	`{"activity_id":1007,"duration":"3d"},{"activity_id":1010,"duration":"3d"},` +
	`{"activity_id":1016,"duration":"3d"}]}`

func testCycle(t *testing.T) Cycle {
	t.Helper()
	cycle, err := ParseCycle([]byte(testCycleJSON))
	if err != nil {
		t.Fatal(err)
	}
	return cycle
}

func TestParseCycle(t *testing.T) {
	cycle := testCycle(t)
	anchor := time.Date(2025, 12, 31, 21, 0, 0, 0, time.UTC)
	if !cycle.Anchor.Equal(anchor) || cycle.Revision != 1 || len(cycle.Entries) != 5 {
		t.Fatalf("cycle = %+v", cycle)
	}
	body, err := cycle.Body()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := ParseCycle(body); err != nil {
		t.Fatalf("canonical body must parse: %v", err)
	}
	for _, raw := range []string{
		`{"revision":1,"anchor":"2026-01-01T05:00:00+08:00","entries":[]}`,
		`{"revision":0,"anchor":"2026-01-01T05:00:00+08:00","entries":[{"activity_id":1008,"duration":"3d"}]}`,
		`{"revision":1,"anchor":"","entries":[{"activity_id":1008,"duration":"3d"}]}`,
		`{"revision":1,"anchor":"2026-01-01T05:00:00+08:00","entries":[{"activity_id":0,"duration":"3d"}]}`,
		`{"revision":1,"anchor":"2026-01-01T05:00:00+08:00","entries":[{"activity_id":1008,"duration":"2d"}]}`,
		`{"revision":1,"anchor":"2026-01-01T05:00:00+08:00","entries":[{"activity_id":1008,"duration":"permanent"}]}`,
		`{"revision":1,"anchor":"2026-01-01T05:00:00+08:00","entries":[{"activity_id":1008,"duration":"3d","extra":1}]}`,
		`{"revision":1,"anchor":"2026-01-01T05:00:00+08:00","entries":[{"activity_id":1008,"duration":"3d"}]} trailing`,
	} {
		if _, err := ParseCycle([]byte(raw)); !errors.Is(err, ErrInvalidCycle) {
			t.Fatalf("%s must be refused, got %v", raw, err)
		}
	}
}

func TestNextSlots(t *testing.T) {
	cycle := testCycle(t)
	anchor := cycle.Anchor
	now := anchor.Add(30 * 24 * time.Hour).Add(-time.Hour)
	slots := cycle.NextSlots(now, 2, 24*time.Hour)
	if len(slots) != 2 {
		t.Fatalf("slots = %+v", slots)
	}
	if slots[0].ActivityID != 1008 || !slots[0].StartsAt.Equal(anchor.Add(30*24*time.Hour)) {
		t.Fatalf("first slot = %+v", slots[0])
	}
	if slots[1].ActivityID != 1009 || !slots[1].StartsAt.Equal(anchor.Add(33*24*time.Hour)) {
		t.Fatalf("second slot = %+v", slots[1])
	}
	if !slots[1].EndsAt.Equal(slots[1].StartsAt.Add(72 * time.Hour)) {
		t.Fatalf("duration = %s", slots[1].EndsAt.Sub(slots[1].StartsAt))
	}
	if !slots[1].ClaimUntil.Equal(slots[1].EndsAt.Add(24 * time.Hour)) {
		t.Fatalf("claim window = %s", slots[1].ClaimUntil.Sub(slots[1].EndsAt))
	}
	atBoundary := cycle.NextSlots(slots[0].StartsAt, 1, 0)
	if len(atBoundary) != 1 || atBoundary[0].ActivityID != 1008 {
		t.Fatalf("a slot starting exactly now must be included: %+v", atBoundary)
	}
	inside := cycle.NextSlots(slots[0].StartsAt.Add(time.Second), 1, 0)
	if len(inside) != 1 || inside[0].ActivityID != 1009 {
		t.Fatalf("a started slot must be skipped: %+v", inside)
	}
	if cycle.NextSlots(now, 0, 0) != nil {
		t.Fatal("zero look-ahead must return nothing")
	}
	far := cycle.NextSlots(anchor.Add(-time.Hour), 6, 0)
	if len(far) != 6 || far[5].ActivityID != 1008 || !far[5].StartsAt.Equal(anchor.Add(15*24*time.Hour)) {
		t.Fatalf("a future anchor must wrap the loop: %+v", far)
	}
}

package eventscontent

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/events"
)

// TestShippedDefaultCycle proves the ruling 8 shape: the 2026-01-01 05:00
// GMT+8 anchor and five 3d entries forming a 15-day loop.
func TestShippedDefaultCycle(t *testing.T) {
	cycle, err := events.ParseCycle(DefaultCycle())
	if err != nil {
		t.Fatal(err)
	}
	anchor := time.Date(2025, 12, 31, 21, 0, 0, 0, time.UTC)
	if !cycle.Anchor.Equal(anchor) {
		t.Fatalf("anchor = %s", cycle.Anchor)
	}
	want := []int64{1008, 1009, 1007, 1010, 1016}
	if len(cycle.Entries) != len(want) {
		t.Fatalf("entries = %+v", cycle.Entries)
	}
	for index, entry := range cycle.Entries {
		if entry.ActivityID != want[index] || entry.Duration != "3d" {
			t.Fatalf("entry %d = %+v", index, entry)
		}
	}
	slots := cycle.NextSlots(anchor.Add(-time.Second), 6, 24*time.Hour)
	if len(slots) != 6 || !slots[5].StartsAt.Equal(anchor.Add(15*24*time.Hour)) {
		t.Fatalf("the loop must repeat after 15 days: %+v", slots)
	}
}

package objective

import (
	"errors"
	"testing"
	"time"
)

func TestMissionRootRolloverPreservesWeekAndRefusesOlderDecision(t *testing.T) {
	zone := time.FixedZone("GMT+8", 8*3600)
	at := time.Date(2026, 10, 25, 4, 59, 59, 0, zone)
	root, err := NewMissionRoot(100001, at)
	if err != nil {
		t.Fatal(err)
	}
	root.DayHuoyue, root.WeekHuoyue = 30, 500
	root.DayAward, root.WeekAward = []int64{1}, []int64{1}
	next, changed, err := root.Rollover(at.Add(time.Second))
	if err != nil || !changed || next.DayHuoyue != 0 || len(next.DayAward) != 0 || next.WeekHuoyue != 500 || len(next.WeekAward) != 1 {
		t.Fatalf("daily rollover = %+v, %v, %v", next, changed, err)
	}
	if _, _, err := next.Rollover(at); !errors.Is(err, ErrStaleMissionDay) {
		t.Fatalf("older operation rewound mission state: %v", err)
	}
	monday, changed, err := next.Rollover(time.Date(2026, 10, 26, 5, 0, 0, 0, zone))
	if err != nil || !changed || monday.WeekHuoyue != 0 || len(monday.WeekAward) != 0 {
		t.Fatalf("weekly rollover = %+v, %v, %v", monday, changed, err)
	}
}

package petcampaign

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestEliteCountsAreFloorOrderedArrays(t *testing.T) {
	s := New(10, 100)
	s.EliteBuys[1] = 2
	s.EliteUsed[1] = 1
	elite := s.Elite(Catalog{Raids: 3})
	buys, ok := elite["buy_info"].([]int64)
	if !ok || len(buys) != 20 {
		t.Fatalf("buy_info is not a 20-element array: %#v", elite["buy_info"])
	}
	if buys[0] != 2 || buys[1] != 0 || buys[19] != 0 {
		t.Fatalf("buy_info floor order: %v", buys)
	}
	remaining, ok := elite["sweep_info"].([]int64)
	if !ok || len(remaining) != 20 {
		t.Fatalf("sweep_info is not a 20-element array: %#v", elite["sweep_info"])
	}
	if remaining[0] != 3*(1+2)-1 {
		t.Fatalf("sweep_info floor 1 remaining: %v", remaining)
	}
	raw, e := json.Marshal(elite)
	if e != nil {
		t.Fatal(e)
	}
	if !strings.Contains(string(raw), `"buy_info":[`) || !strings.Contains(string(raw), `"sweep_info":[`) {
		t.Fatalf("JSON is not an array: %s", raw)
	}
}
func TestSweepStopsAtPersonalBestAndSurvivesDay(t *testing.T) {
	s := New(10, 100)
	s.Max = 77
	s.Current = 0
	from, to, e := s.SweepInterval()
	if e != nil || from != 1 || to != 77 {
		t.Fatal(from, to, e)
	}
	s.Sweep = &Sweep{From: from, To: to, Start: 100, Due: 100 + 77*60}
	s.SweepLeft = 0
	s.Normalize(11, 200)
	if s.Sweep.To != 77 || s.Current != 0 || s.SweepLeft != 0 {
		t.Fatal(s)
	}
	if s.Sweep.Cost(Catalog{LayerSeconds: 60, LayerCost: 10}, s.Sweep.Due) != 0 || s.Sweep.Cost(Catalog{LayerSeconds: 60, LayerCost: 10}, s.Sweep.Due-1) != 10 {
		t.Fatal("deadline")
	}
	s.Current = s.Sweep.To
	s.Sweep = nil
	if e = s.Win(1, 78, 5000); e != nil || s.Max != 78 {
		t.Fatal(s, e)
	}
}
func TestClearIsStarlessAndEliteSelectionIsNotProgress(t *testing.T) {
	s := New(5, 100)
	if e := s.Win(1, 2, 100); e == nil {
		t.Fatal("skip")
	}
	if e := s.Win(1, 1, 100); e != nil {
		t.Fatal(e)
	}
	s.Selected = 19
	if s.EliteMax != 0 {
		t.Fatal(s)
	}
	if e := s.Win(2, 1, 100); e == nil {
		t.Fatal("locked elite")
	}
	s.Max = 100
	if e := s.Win(2, 1, 100); e != nil {
		t.Fatal(e)
	}
	s.EliteUsed[1] = 3
	s.Normalize(4, 90)
	if s.EliteUsed[1] != 3 || s.Day != 5 || s.LastObserved != 100 {
		t.Fatal("backwards reset", s)
	}
	s.Normalize(6, 200)
	if s.EliteUsed[1] != 0 || s.EliteMax != 1 {
		t.Fatal(s)
	}
}
func TestManualResetPreservesBestAndPendingSweep(t *testing.T) {
	s := New(1, 10)
	s.Max = 77
	s.Current = 77
	if e := s.Reset(); e != nil || s.Max != 77 || s.Current != 0 || s.ResetLeft != 0 {
		t.Fatal(s, e)
	}
	if e := s.Reset(); e == nil {
		t.Fatal("double reset")
	}
	s.Normalize(2, 20)
	s.Current = 1
	s.Sweep = &Sweep{}
	if e := s.Reset(); e == nil {
		t.Fatal("pending work reset")
	}
}

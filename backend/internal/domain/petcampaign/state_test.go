package petcampaign

import "testing"

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

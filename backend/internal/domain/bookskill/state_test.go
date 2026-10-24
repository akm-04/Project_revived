package bookskill

import (
	"math"
	"testing"
	"time"
)

func TestFiniteJobBoundariesAndAcknowledgment(t *testing.T) {
	s := Seed()
	at := time.Unix(1000, 0).UTC()
	s.Research = &Job{Occurrence: "op", Revision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StartedAt: at, Duration: 60, Target: 1, Subject: 123, Cost: EmptyCost()}
	before, e := s.Settle(at.Add(59 * time.Second))
	if e != nil || before || s.Skills[123] != 0 {
		t.Fatal("early applied", before, e)
	}
	due, e := s.Settle(at.Add(60 * time.Second))
	if e != nil || !due || s.Skills[123] != 1 || s.Research != nil || s.RecentSkill != 123 {
		t.Fatal("due", s, e)
	}
	again, e := s.Settle(at.Add(600 * time.Second))
	if e != nil || again || s.Skills[123] != 1 {
		t.Fatal("double completion")
	}
	s.RecentSkill = 0
	if s.Skills[123] != 1 {
		t.Fatal("confirmation erased applied fact")
	}
}
func TestSpeedSourcePiecewiseAndZeroChargeAtExpiry(t *testing.T) {
	for _, x := range [][2]int64{{0, 0}, {1, 1}, {72, 1}, {73, 2}, {14399, 200}, {14400, 200}, {14401, 201}, {43199, 400}, {43200, 400}, {43201, 401}} {
		if got := SpeedCost(x[0]); got != x[1] {
			t.Fatalf("%d:%d want%d", x[0], got, x[1])
		}
	}
}
func TestSnapshotRefundLargeValuesAndPages(t *testing.T) {
	j := &Job{Duration: 3, Cost: Cost{map[string]int64{"mana": math.MaxInt64}, map[int64]int64{240001001: 10}}}
	r, e := Refund(j, 2)
	if e != nil || r.Scalars["mana"] != 6148914691236517204 || r.Stacks[240001001] != 10 {
		t.Fatal(r, e)
	}
	if _, e = Refund(j, 0); e == nil {
		t.Fatal("due refund")
	}
}
func TestBackwardJobObservationRejected(t *testing.T) {
	s := Seed()
	s.Buildings[1] = Building{Level: 1, Job: &Job{StartedAt: time.Unix(100, 0), Duration: 60, Target: 2, Subject: 1}}
	if _, e := s.Settle(time.Unix(99, 0)); e != ErrStaleTime {
		t.Fatal(e)
	}
}
func FuzzSpeedCostMonotonic(f *testing.F) {
	for _, x := range []int64{0, 1, 14399, 14400, 43199, 43200, 1000000} {
		f.Add(x)
	}
	f.Fuzz(func(t *testing.T, x int64) {
		if x < 0 || x > 1000000000 {
			return
		}
		got := SpeedCost(x)
		if got < 0 || SpeedCost(x+1) < got {
			t.Fatal(x, got)
		}
	})
}

package achievement

import (
	"strings"
	"testing"
	"time"
)

func catalog() Catalog {
	c := Catalog{SchemaVersion: 1, PolicyID: Policy, SelectedID: SelectedID}
	for id := int64(100001); id <= 100033; id++ {
		c.Rows = append(c.Rows, Definition{ID: id, Thresholds: [3]int64{1, 2, 3}, Points: [3]int64{500, 1000, 1500}})
	}
	c.Rows[13].Thresholds = [3]int64{1, 10, 20}
	return c
}
func TestEarnedTierBoundariesAndStableFirstCompletion(t *testing.T) {
	at := time.Unix(100, 0)
	r, e := NewRoot(7, strings.Repeat("a", 64), at)
	if e != nil {
		t.Fatal(e)
	}
	for _, n := range []int64{1, 9, 10, 19, 20, 25} {
		prev := r.CompleteTimes
		r, _, e = r.ObservePopulation(catalog(), n, at.Add(time.Duration(n)*time.Second))
		if e != nil {
			t.Fatal(n, e)
		}
		for i, target := range [3]int64{1, 10, 20} {
			if (r.CompleteTimes[i] != nil) != (n >= target) {
				t.Fatal(n, i, r)
			}
			if prev[i] != nil && !prev[i].Equal(*r.CompleteTimes[i]) {
				t.Fatal("rewrote first completion")
			}
		}
	}
	old := r
	v, changed, e := r.ObservePopulation(catalog(), 1, at.Add(time.Hour))
	if e != nil || changed || v.StateVersion != old.StateVersion || v.Progress != 25 {
		t.Fatal("population fall revoked earned facts", v, e)
	}
	if _, _, e = r.ObservePopulation(catalog(), 26, at); e == nil {
		t.Fatal("stale time")
	}
	if _, _, e = r.ObservePopulation(catalog(), 9007199254740992, at.Add(time.Hour)); e == nil {
		t.Fatal("unsafe population")
	}
}
func TestUnknownAndCorruptHistoryNotUnearned(t *testing.T) {
	if (Root{}).Validate() == nil {
		t.Fatal("missinghistory qualified")
	}
	r, _ := NewRoot(7, strings.Repeat("a", 64), time.Unix(100, 0))
	r.Progress = 10
	if r.Validate() == nil {
		t.Fatal("missing completion timestamps")
	}
	c := catalog()
	c.Rows[13].Thresholds = [3]int64{1, 5, 10}
	if c.Validate() == nil {
		t.Fatal("selected source thresholds drift")
	}
}
func FuzzTierMonotonicity(f *testing.F) {
	f.Add(uint8(1), uint8(20))
	f.Add(uint8(10), uint8(5))
	f.Fuzz(func(t *testing.T, a, b uint8) {
		r, _ := NewRoot(1, strings.Repeat("a", 64), time.Unix(100, 0))
		for i, n := range []uint8{a, b} {
			old := r
			r, _, _ = r.ObservePopulation(catalog(), int64(n)+1, time.Unix(101+int64(i), 0))
			if r.Validate() != nil || r.Progress < old.Progress {
				t.Fatal(r)
			}
			for j, v := range old.CompleteTimes {
				if v != nil && (r.CompleteTimes[j] == nil || !r.CompleteTimes[j].Equal(*v)) {
					t.Fatal("tier revoked/retimed")
				}
			}
		}
	})
}

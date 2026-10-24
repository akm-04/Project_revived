package dormhouse

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"math"
	"testing"
	"time"
)

func TestLoungeFractionsCapAndStale(t *testing.T) {
	start := time.Date(2026, 10, 13, 1, 0, 0, 0, time.UTC)
	a, e := SettleLounge(start, start.Add(time.Second), 0, 0)
	if e != nil || a.WholeEXP != 0 || a.Fraction != 60*int64(time.Second) {
		t.Fatal(a, e)
	}
	b, e := SettleLounge(a.Anchor, start.Add(time.Minute), a.Fraction, 0)
	if e != nil || b.WholeEXP != 1 || b.Fraction != 0 {
		t.Fatal(b, e)
	}
	long, e := SettleLounge(start, start.Add(24*time.Hour), 0, 5)
	if e != nil || long.WholeEXP != 1600 || !long.DiscardedElapsed || !long.Anchor.Equal(start.Add(24*time.Hour)) {
		t.Fatal(long, e)
	}
	again, e := SettleLounge(long.Anchor, long.Anchor, long.Fraction, 5)
	if e != nil || again.WholeEXP != 0 {
		t.Fatal(again, e)
	}
	if _, e = SettleLounge(start, start.Add(-time.Second), 0, 0); e != ErrStaleTime {
		t.Fatal(e)
	}
	if _, e = SettleLounge(start, start.Add(10*time.Hour), 0, math.MaxInt64); e != ErrInvalidFacts {
		t.Fatal("overflow accepted", e)
	}
}
func TestLoungeSplitSettlementAndOldComfort(t *testing.T) {
	s := time.Unix(100, 0).UTC()
	single, e := SettleLounge(s, s.Add(1357*time.Millisecond), 0, 7)
	if e != nil {
		t.Fatal(e)
	}
	first, _ := SettleLounge(s, s.Add(500*time.Millisecond), 0, 7)
	second, _ := SettleLounge(first.Anchor, s.Add(1357*time.Millisecond), first.Fraction, 7)
	if first.WholeEXP+second.WholeEXP != single.WholeEXP || second.Fraction != single.Fraction {
		t.Fatal("fraction lost", single, first, second)
	}
	old, _ := SettleLounge(s, s.Add(time.Hour), 0, 0)
	next, _ := SettleLounge(old.Anchor, s.Add(2*time.Hour), old.Fraction, 10)
	if old.WholeEXP != 60 || next.WholeEXP != 260 {
		t.Fatal(old, next)
	}
}
func TestExpansionPriceBoundary(t *testing.T) {
	s := time.Unix(100, 0).UTC()
	x := Expansion{Occurrence: "retained", ContentRevision: "pinned", NextLevel: 1, DurationSeconds: 3600, StartedAt: s}
	for _, tc := range []struct {
		elapsed  time.Duration
		price    int64
		complete bool
	}{{0, 500, false}, {2700 * time.Second, 125, false}, {2699 * time.Second, 250, false}, {3600 * time.Second, 0, true}, {24 * time.Hour, 0, true}} {
		p, c, e := x.FinishPrice(s.Add(tc.elapsed))
		if e != nil || p != tc.price || c != tc.complete {
			t.Fatal(tc, p, c, e)
		}
	}
	if _, _, e := x.FinishPrice(s.Add(-time.Second)); e != ErrStaleTime {
		t.Fatal(e)
	}
}
func TestGrowthAppliedThresholdsOnly(t *testing.T) {
	c := Catalog{Rooms: map[int64]RoomRule{1: {MainType: 4, AttributeType: 2, Growth: []GrowthTier{{0, AttributesBP{100, 200, 300}}, {60, AttributesBP{1200, 480, 720}}}}}, Types: map[int64]TypeRule{4: {MaxExpansion: 3}}, Expansions: map[int64]ExpansionRule{1: {Comfort: 260, Attributes: [3]AttributesBP{{1, 2, 3}, {3080, 3360, 2800}, {4, 5, 6}}}, 2: {Comfort: 310, Attributes: [3]AttributesBP{{1, 2, 3}, {3520, 3840, 3200}, {4, 5, 6}}}}}
	for _, tc := range []struct {
		comfort, level int64
		want           AttributesBP
	}{{259, 1, AttributesBP{1200, 480, 720}}, {260, 1, AttributesBP{3080, 3360, 2800}}, {310, 1, AttributesBP{3080, 3360, 2800}}, {310, 2, AttributesBP{3520, 3840, 3200}}, {1000, 0, AttributesBP{1200, 480, 720}}} {
		v, e := c.GrowthBP(1, tc.comfort, tc.level)
		if e != nil || v != tc.want {
			t.Fatal(tc, v, e)
		}
	}
}
func TestKeySelectionStableSupportAndSeparateKeys(t *testing.T) {
	id, err := ids.ParseUUID("00000000-0000-4000-8000-000000000001")
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{ID: id, StartedAt: time.Unix(100, 0)}
	c := Catalog{Rooms: map[int64]RoomRule{1: {MainType: 2}, 2: {MainType: 2}, 3: {MainType: 4}}, Keys: map[int64]KeyRule{10: {MainType: 2, Templates: []int64{1, 2}}, 11: {MainType: 4, Templates: []int64{3}}}}
	v, e := c.SelectRoom(10, op)
	again, e2 := c.SelectRoom(10, op)
	if e != nil || e2 != nil || v != again || (v != 1 && v != 2) {
		t.Fatal(v, again, e, e2)
	}
	v, e = c.SelectRoom(11, op)
	if e != nil || v != 3 {
		t.Fatal(v, e)
	}
	if _, e = c.SelectRoom(12, op); e != ErrUnqualified {
		t.Fatal(e)
	}
}

func FuzzLoungeElapsedBound(f *testing.F) {
	f.Add(uint64(3600000000000), uint32(7), uint64(0))
	f.Fuzz(func(t *testing.T, elapsed uint64, comfort uint32, fraction uint64) {
		elapsed %= uint64(48 * time.Hour)
		comfort %= 100000
		fraction %= uint64(HourNumerator)
		start := time.Unix(100000, 0).UTC()
		out, e := SettleLounge(start, start.Add(time.Duration(elapsed)), int64(fraction), int64(comfort))
		if e != nil {
			t.Fatal(e)
		}
		bounded := elapsed
		if bounded > uint64(MaxLoungeElapsed) {
			bounded = uint64(MaxLoungeElapsed)
		}
		numerator := int64(bounded)*(60+20*int64(comfort)) + int64(fraction)
		if out.WholeEXP != numerator/HourNumerator || out.Fraction != numerator%HourNumerator || !out.Anchor.Equal(start.Add(time.Duration(elapsed))) {
			t.Fatal(out, numerator)
		}
	})
}

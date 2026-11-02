package worldboss

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/modes"
	d "gxb.local/backend/v2/internal/domain/worldboss"
)

func TestCourageUpdateDay(t *testing.T) {
	zone := time.FixedZone("GMT+8", 8*3600)
	evening := time.Date(2026, 10, 31, 22, 0, 0, 0, zone)
	day := modes.Day(evening)
	if got := d.CourageDayFor(evening); got != day {
		t.Fatalf("22:00 got=%d want=%d", got, day)
	}
	tomorrow := evening.Add(24 * time.Hour)
	if got := d.CourageDayFor(tomorrow); got != modes.Day(tomorrow) {
		t.Fatalf("next day got=%d want=%d", got, modes.Day(tomorrow))
	}
	justBefore := time.Date(2026, 10, 31, 21, 59, 59, 0, zone)
	if got := d.CourageDayFor(justBefore); got != day-1 {
		t.Fatalf("21:59 maps to got=%d want=%d", got, day-1)
	}
	morning := time.Date(2026, 11, 1, 4, 0, 0, 0, zone)
	if got := d.CourageDayFor(morning); got != day {
		t.Fatalf("04:00 maps to got=%d want=%d", got, day)
	}
}

func TestRewardLines(t *testing.T) {
	boss := d.Boss{DefeatStone: 40001047}
	lines := rewardLines(d.RankReward{Range: 1, Diamond: 480, Mana: 40000, Stone: 24}, boss)
	if len(lines) != 3 || lines[2].ItemID != boss.DefeatStone || lines[0].Amount != 480 {
		t.Fatal(lines)
	}
	if lines = rewardLines(d.RankReward{Range: 100000, Diamond: 10, Mana: 3600}, boss); len(lines) != 2 {
		t.Fatal(lines)
	}
	if lines = rewardLines(d.RankReward{Range: 100000}, boss); len(lines) != 0 {
		t.Fatal(lines)
	}
}

func TestValidateFormation(t *testing.T) {
	for _, bad := range [][]int64{nil, {}, {0}, {1, 1}, {1, 2, 3, 4, 5, 6}} {
		if validateFormation(bad) == nil {
			t.Fatalf("accepted %#v", bad)
		}
	}
	if validateFormation([]int64{5, 4, 3}) != nil {
		t.Fatal("valid formation refused")
	}
}

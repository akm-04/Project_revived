package modes_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/modes"
)

var gmt8 = time.FixedZone("GMT+8", 8*3600)

func TestDayTurnsAtFiveGMT8(t *testing.T) {
	before := time.Date(2026, 10, 24, 4, 59, 59, 0, gmt8)
	after := time.Date(2026, 10, 24, 5, 0, 0, 0, gmt8)
	if modes.Day(after) != modes.Day(before)+1 {
		t.Fatalf("day did not turn at 05:00: %d %d", modes.Day(before), modes.Day(after))
	}
	if !modes.DayBegins(modes.Day(after)).Equal(after) {
		t.Fatalf("modes.DayBegins %v", modes.DayBegins(modes.Day(after)))
	}
	if modes.Day(after) != arena.Day(after) || modes.Day(before) != arena.Day(before) {
		t.Fatal("modes modes.Day differs from the arena day")
	}
}

func TestWeekTurnsMondayFiveGMT8(t *testing.T) {
	sunday := time.Date(2026, 10, 26, 4, 59, 59, 0, gmt8) // Monday 04:59 still belongs to the previous week
	monday := time.Date(2026, 10, 26, 5, 0, 0, 0, gmt8)
	if monday.Weekday() != time.Monday {
		t.Fatal("fixture is not a Monday")
	}
	if modes.WeekStart(monday) != modes.Day(monday) || modes.WeekStart(sunday) != modes.Day(monday)-7 {
		t.Fatalf("week start %d %d day %d", modes.WeekStart(sunday), modes.WeekStart(monday), modes.Day(monday))
	}
	if modes.DayBegins(modes.WeekStart(time.Date(2026, 10, 29, 12, 0, 0, 0, gmt8))).In(gmt8).Weekday() != time.Monday {
		t.Fatal("week does not begin on Monday")
	}
}

func TestCounterResetsInLaterPeriod(t *testing.T) {
	c, err := modes.Counter{}.Use(10, 2, 3)
	if err != nil || c.Used != 2 {
		t.Fatal(c, err)
	}
	if _, err := c.Use(10, 2, 3); err != modes.ErrCounterExhausted {
		t.Fatal("over limit accepted")
	}
	next, err := c.Use(11, 3, 3)
	if err != nil || next != (modes.Counter{Period: 11, Used: 3}) {
		t.Fatal(next, err)
	}
	if _, err := c.Use(10, 0, 3); err != modes.ErrCounterExhausted {
		t.Fatal("zero use accepted")
	}
}

func TestLadderBeyondLastRow(t *testing.T) {
	prices := []int64{10, 20, 50}
	if p, ok := (modes.Ladder{Prices: prices}).Price(3); !ok || p != 50 {
		t.Fatal(p, ok)
	}
	if _, ok := (modes.Ladder{Prices: prices}).Price(4); ok {
		t.Fatal("refusing ladder sold past its last row")
	}
	if p, ok := (modes.Ladder{Prices: prices, Beyond: modes.ClampLast}).Price(9); !ok || p != 50 {
		t.Fatal(p, ok)
	}
	if _, ok := (modes.Ladder{Prices: prices}).Price(0); ok {
		t.Fatal("zeroth buy priced")
	}
}

func TestSweepAdmission(t *testing.T) {
	if modes.AdmitSweep(3, 10, 10) != nil || modes.AdmitSweep(2, 1, 10) == nil || modes.AdmitSweep(3, 11, 10) == nil || modes.AdmitSweep(3, 0, 10) == nil {
		t.Fatal("sweep law")
	}
}

package mentor

import (
	"testing"
	"time"
)

// R3 switch: a stored UTC ApplyDay written between 21:00 and 24:00 UTC already belongs to the next GMT+8 game day,
// so it must not grant another day of applications; one written before 21:00 UTC resets at the next 05:00 GMT+8.
func TestMentorCalendarSwitchAtTheUtcEvening(t *testing.T) {
	evening := time.Date(2026, 11, 10, 22, 0, 0, 0, time.UTC)
	nextMorning := time.Date(2026, 11, 11, 10, 0, 0, 0, time.UTC)
	if start := gameDayStart(evening); start != time.Date(2026, 11, 11, 0, 0, 0, 0, time.UTC) {
		t.Fatalf("evening write stores %v, want the next game-day date", start)
	}
	if !sameDay(evening, nextMorning) {
		t.Fatal("an evening write was reset inside the game day it already belongs to")
	}
	if sameDay(evening, nextMorning.Add(11*time.Hour)) {
		t.Fatal("the evening write did not reset at the next 05:00 GMT+8")
	}
	before := time.Date(2026, 11, 10, 20, 59, 59, 0, time.UTC)
	boundary := time.Date(2026, 11, 10, 21, 0, 0, 0, time.UTC)
	if sameDay(before, boundary) {
		t.Fatal("a write before 21:00 UTC did not reset at the next 05:00 GMT+8")
	}
}

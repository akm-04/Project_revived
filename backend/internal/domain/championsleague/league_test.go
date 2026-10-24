package championsleague

import (
	"encoding/json"
	"os"
	"testing"
	"time"
)

func catalog(t *testing.T) Catalog {
	t.Helper()
	b, e := os.ReadFile("../../content/builtin/generated/league_catalog.json")
	if e != nil {
		t.Fatal(e)
	}
	var c Catalog
	if e = json.Unmarshal(b, &c); e != nil {
		t.Fatal(e)
	}
	if e = c.Validate(); e != nil {
		t.Fatal(e)
	}
	return c
}
func TestLeagueSourceCalendarAndRest(t *testing.T) {
	c := catalog(t)
	open := time.Date(2024, 7, 18, 16, 0, 0, 0, time.UTC)
	s := c.SeasonAt(open)
	if s.Number != 51 || !s.OpensAt.Equal(open) || !s.ClosesAt.Equal(time.Date(2024, 8, 14, 16, 0, 0, 0, time.UTC)) {
		t.Fatalf("season %+v", s)
	}
	if !s.Open(s.ClosesAt.Add(-time.Nanosecond)) || s.Open(s.ClosesAt) || s.Open(s.NextAt) {
		t.Fatal("close/rest half-open boundary")
	}
	if c.SeasonAt(s.NextAt).Number != s.Number+1 {
		t.Fatal("roll boundary")
	}
	cut := time.Date(2026, 10, 20, 14, 0, 0, 0, time.UTC)
	if c.Day(cut.Add(-time.Nanosecond)) != c.Day(cut)-1 || !c.DayAt(c.Day(cut)).Equal(cut) {
		t.Fatal("22:00GMT+8 boundary")
	}
}
func TestLeaguePrivateScoreFairnessConservation(t *testing.T) {
	c := catalog(t)
	for _, x := range [][3]int64{{2000, 2000, 18}, {2400, 2000, 3}, {2000, 2400, 33}, {2000, 1, 1}, {0, 0, 0}} {
		if n := c.Transfer(x[0], x[1]); n != x[2] {
			t.Fatalf("%v ->%d", x, n)
		}
	}
	for a := int64(0); a <= 6000; a += 25 {
		prev := int64(-1)
		for b := int64(0); b <= 6000; b += 25 {
			n := c.Transfer(a, b)
			if n < 0 || n > b || n > 36 || a+n+b-n != a+b || n < prev {
				t.Fatal(a, b, n)
			}
			prev = n
		}
	}
}
func TestLeagueProtectionFrenzyBoundaries(t *testing.T) {
	c := catalog(t)
	at := time.Date(2026, 10, 20, 12, 50, 0, 0, time.UTC)
	if !c.Protection(at, at).Equal(at.Add(30 * time.Minute)) {
		t.Fatal("normal")
	}
	crazy := at.Add(12 * time.Minute)
	want := time.Date(2026, 10, 20, 13, 3, 0, 0, time.UTC)
	if !c.Protection(at, crazy).Equal(want) {
		t.Fatal("clip at21:00")
	}
	last := time.Date(2026, 10, 20, 13, 59, 0, 0, time.UTC)
	if !c.Protection(last, last.Add(2*time.Minute)).Equal(last.Add(3 * time.Minute)) {
		t.Fatal("short protection must not resurrect at22:00")
	}
}
func TestLeaguePromotionRecomputesPriorRank(t *testing.T) {
	c := catalog(t)
	at := time.Date(2026, 10, 20, 0, 0, 0, 0, time.UTC)
	a := c.NewPlayer(100001, 1, 70, at)
	b := c.NewPlayer(100002, 1, 70, at)
	d := c.NewPlayer(100003, 1, 70, at)
	a.Points, a.Participated = 2300, true
	b.Points = 2200
	d.Points = 2100
	a = c.Promote(a, 2, 1, at.Add(time.Second))
	b.Points, d.Points = 2500, 2400
	place := FinalPlacement([]Player{a, b, d}, a)
	if place.Group != 1 || place.Rank != 3 || !place.Participated || a.Participated {
		t.Fatalf("promotion %+v %+v", a, place)
	}
	a.Points, a.Participated = 2250, true
	a = c.Promote(a, 3, 1, at.Add(2*time.Second))
	if a.Prior.Group != 2 || a.Prior.Points != 2250 {
		t.Fatal("second promotion banked an arbitrary older group")
	}
}
func TestLeagueResetAndGenuineResult(t *testing.T) {
	c := catalog(t)
	at := time.Date(2026, 10, 20, 0, 0, 0, 0, time.UTC)
	a := c.NewPlayer(100001, 1, 100, at)
	b := c.NewPlayer(200001, 2, 100, at)
	a, b, n := c.Attack(a, b, true, at.Add(time.Second))
	if n != 18 || a.Points != 2018 || b.Points != 1982 || !a.Participated || !b.Participated || a.Wins != 1 || b.Wins != 0 {
		t.Fatal("terminal rules")
	}
	a.TopSeasons, a.QualifyingDays = 3, 7
	a.Defense = Lineup{Heroes: []int64{123}}
	next := c.Rolled(a, c.SeasonNumbered(a.Season).NextAt)
	if next.Points != 2000 || next.Participated || next.Fights != 0 || next.TopSeasons != 3 || next.QualifyingDays != 7 || len(next.Defense.Heroes) != 1 {
		t.Fatal("season reset lost lifetime facts or defense")
	}
}

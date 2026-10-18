package ranking

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func girlsFixture() (GirlsRoot, time.Time, string, ids.UUID) {
	at := time.Date(2026, 10, 18, 12, 0, 0, 0, time.UTC)
	r, _ := NewGirlsRoot(1, at)
	op, _ := ids.NewUUID()
	return r, at, strings.Repeat("a", 64), op
}
func girlsInput(pid, score int64, at time.Time, rev string) GirlsInput {
	return GirlsInput{Metric: GirlsMetric{Player: identity.PlayerID(pid), Owner: "CharacterHero", Policy: GirlsSourcePolicy, Semantics: GirlsSourceSemantics, Revision: rev, PopulationDigest: strings.Repeat("b", 64), FieldID: 1001, Value: score, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at}, Display: GirlsPresentation{Player: identity.PlayerID(pid), Name: "Player", Level: 1}}
}
func TestGirlsObservedRunsDoNotInventFirstReachOrResetForEquipment(t *testing.T) {
	r, at, rev, op := girlsFixture()
	n, s, e := BuildGirlsSnapshot(r, at, rev, op, []GirlsInput{girlsInput(9, 2, at, rev), girlsInput(3, 2, at, rev)})
	if e != nil || s.Entries[0].Metric.Player != 3 || !s.Entries[0].ScoreSince.Equal(at) {
		t.Fatal(s, e)
	}
	// A source version/digest change without a count change preserves the observed
	// score-run time. Canonical equipment changes must not move an equal count.
	later := at.Add(time.Hour)
	in := girlsInput(9, 2, later, rev)
	in.Metric.SourceVersion = 2
	in.Metric.PopulationVersion = 2
	in.Metric.PopulationDigest = strings.Repeat("c", 64)
	n2, s2, e := BuildGirlsSnapshot(n, later, rev, op, []GirlsInput{in, girlsInput(3, 1, later, rev)})
	if e != nil || s2.Entries[0].Metric.Player != 9 || !n2.Runs[9].Since.Equal(at) || !n2.Runs[3].Since.Equal(later) {
		t.Fatal(n2, s2, e)
	}
	// Returning to a previous value starts a new current-value run; it is not a
	// lifetime highwater or the first-ever historical time for that value.
	later2 := later.Add(time.Hour)
	_, s3, e := BuildGirlsSnapshot(n2, later2, rev, op, []GirlsInput{girlsInput(3, 2, later2, rev), girlsInput(9, 2, later2, rev)})
	if e != nil || s3.Entries[0].Metric.Player != 9 || !s3.Entries[1].ScoreSince.Equal(later2) {
		t.Fatal(s3, e)
	}
	if len(r.Runs) != 0 || len(n.Runs) != 2 || n.Runs[3].Score != 2 {
		t.Fatal("build mutated earlier root")
	}
	newRev := strings.Repeat("d", 64)
	_, changed, e := BuildGirlsSnapshot(n2, later2, newRev, op, []GirlsInput{girlsInput(9, 2, later2, newRev)})
	if e != nil || !changed.Entries[0].ScoreSince.Equal(later2) {
		t.Fatal(changed, e)
	}
}
func TestGirlsSnapshotRejectsIncompleteConflictingOrTamperedInputs(t *testing.T) {
	r, at, rev, op := girlsFixture()
	one := girlsInput(1, 1, at, rev)
	cases := []GirlsInput{one, one, one, one, one, one}
	cases[0].Metric.Owner = "client"
	cases[1].Metric.ObservedAt = at.Add(time.Second)
	cases[2].Metric.Policy = "future"
	cases[3].Metric.PopulationDigest = ""
	cases[4].Display.Player = 2
	cases[5].Metric.Value = -1
	for _, v := range cases {
		if _, _, e := BuildGirlsSnapshot(r, at, rev, op, []GirlsInput{v}); e == nil {
			t.Fatal("accepted unqualified source", v)
		}
	}
	if _, _, e := BuildGirlsSnapshot(r, at, rev, op, []GirlsInput{one, one}); e == nil {
		t.Fatal("duplicate subject")
	}
	if _, _, e := BuildGirlsSnapshot(r, at.Add(-time.Second), rev, op, []GirlsInput{one}); e != ErrStale {
		t.Fatal(e)
	}
	_, s, e := BuildGirlsSnapshot(r, at, rev, op, []GirlsInput{one})
	if e != nil {
		t.Fatal(e)
	}
	s.Entries[0].Metric.Value++
	if s.Validate() == nil {
		t.Fatal("mutated immutable snapshot")
	}
}
func TestGirlsTitlesUseSourceTiersPositivePopulationAndFixedSnapshotTime(t *testing.T) {
	r, at, rev, op := girlsFixture()
	in := []GirlsInput{}
	for p := int64(1); p <= 22; p++ {
		score := int64(1)
		if p == 22 {
			score = 0
		}
		in = append(in, girlsInput(p, score, at, rev))
	}
	_, s, e := BuildGirlsSnapshot(r, at, rev, op, in)
	if e != nil {
		t.Fatal(e)
	}
	awards, e := s.Awards()
	if e != nil || len(awards) != 20 {
		t.Fatal(awards, e)
	}
	for i, a := range awards {
		want := int64(100062)
		if i < 3 {
			want = int64(100059 + i)
		}
		if a.TitleID != want || a.Rank != int64(i+1) || a.EndTime != at.Unix()+604800 || !a.StartsAt.Equal(at) {
			t.Fatal(a)
		}
	}
	week, e := GirlsWeek(at)
	if e != nil || week.Format(time.RFC3339) != "2026-10-12T00:00:00Z" {
		t.Fatal(week, e)
	}
	next, e := GirlsWeek(at.Add(12 * time.Hour))
	if e != nil || next.Format(time.RFC3339) != "2026-10-19T00:00:00Z" {
		t.Fatal(next, e)
	}
	// A time zone on an input instant cannot change the policy's UTC week.
	zone, e := GirlsWeek(at.In(time.FixedZone("offset", 8*3600)))
	if e != nil || !zone.Equal(week) {
		t.Fatal(zone, e)
	}
	_, empty, e := BuildGirlsSnapshot(r, at, rev, op, []GirlsInput{girlsInput(1, 0, at, rev)})
	if e != nil {
		t.Fatal(e)
	}
	none, e := empty.Awards()
	if e != nil || len(none) != 0 {
		t.Fatal(none, e)
	}
}

package ranking

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func girlsFixture() (BoardRoot, time.Time, string, ids.UUID) {
	at := time.Date(2026, 10, 18, 12, 0, 0, 0, time.UTC)
	r, _ := NewBoardRoot(GirlsBoard, 1, at)
	op, _ := ids.NewUUID()
	return r, at, strings.Repeat("a", 64), op
}
func girlsInput(pid, score int64, at time.Time, rev string) BoardInput {
	return BoardInput{Metric: BoardMetric{Player: identity.PlayerID(pid), Owner: "CharacterHero", Policy: GirlsBoard.SourcePolicy, Semantics: GirlsBoard.SourceSemantics, Revision: rev, PopulationDigest: strings.Repeat("b", 64), FieldID: 1001, Value: score, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at}, Display: BoardPresentation{Player: identity.PlayerID(pid), Name: "Player", Level: 1}}
}
func TestGirlsObservedRunsDoNotInventFirstReachOrResetForEquipment(t *testing.T) {
	r, at, rev, op := girlsFixture()
	n, s, e := BuildBoardSnapshot(r, at, rev, op, []BoardInput{girlsInput(9, 2, at, rev), girlsInput(3, 2, at, rev)})
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
	n2, s2, e := BuildBoardSnapshot(n, later, rev, op, []BoardInput{in, girlsInput(3, 1, later, rev)})
	if e != nil || s2.Entries[0].Metric.Player != 9 || !n2.Runs[9].Since.Equal(at) || !n2.Runs[3].Since.Equal(later) {
		t.Fatal(n2, s2, e)
	}
	// Returning to a previous value starts a new current-value run; it is not a
	// lifetime highwater or the first-ever historical time for that value.
	later2 := later.Add(time.Hour)
	_, s3, e := BuildBoardSnapshot(n2, later2, rev, op, []BoardInput{girlsInput(3, 2, later2, rev), girlsInput(9, 2, later2, rev)})
	if e != nil || s3.Entries[0].Metric.Player != 9 || !s3.Entries[1].ScoreSince.Equal(later2) {
		t.Fatal(s3, e)
	}
	if len(r.Runs) != 0 || len(n.Runs) != 2 || n.Runs[3].Score != 2 {
		t.Fatal("build mutated earlier root")
	}
	newRev := strings.Repeat("d", 64)
	_, changed, e := BuildBoardSnapshot(n2, later2, newRev, op, []BoardInput{girlsInput(9, 2, later2, newRev)})
	if e != nil || !changed.Entries[0].ScoreSince.Equal(later2) {
		t.Fatal(changed, e)
	}
}
func TestGirlsSnapshotRejectsIncompleteConflictingOrTamperedInputs(t *testing.T) {
	r, at, rev, op := girlsFixture()
	one := girlsInput(1, 1, at, rev)
	cases := []BoardInput{one, one, one, one, one, one}
	cases[0].Metric.Owner = "client"
	cases[1].Metric.ObservedAt = at.Add(time.Second)
	cases[2].Metric.Policy = "future"
	cases[3].Metric.PopulationDigest = ""
	cases[4].Display.Player = 2
	cases[5].Metric.Value = -1
	for _, v := range cases {
		if _, _, e := BuildBoardSnapshot(r, at, rev, op, []BoardInput{v}); e == nil {
			t.Fatal("accepted unqualified source", v)
		}
	}
	if _, _, e := BuildBoardSnapshot(r, at, rev, op, []BoardInput{one, one}); e == nil {
		t.Fatal("duplicate subject")
	}
	if _, _, e := BuildBoardSnapshot(r, at.Add(-time.Second), rev, op, []BoardInput{one}); e != ErrStale {
		t.Fatal(e)
	}
	_, s, e := BuildBoardSnapshot(r, at, rev, op, []BoardInput{one})
	if e != nil {
		t.Fatal(e)
	}
	s.Entries[0].Metric.Value++
	if s.Validate() == nil {
		t.Fatal("mutated immutable snapshot")
	}
}
func TestDormComfortBoardPublishesTopHundredWithoutTitles(t *testing.T) {
	b, ok := BoardOfSubType(34)
	if !ok || b.Policy != DormComfortPolicy || b.RowValue != "comfort" || b.Limit != 100 || b.TitledRanks != 0 || len(b.Titles) != 0 {
		t.Fatal(b, ok)
	}
	at := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)
	rev := strings.Repeat("a", 64)
	op, _ := ids.NewUUID()
	root, e := NewBoardRoot(b, 1, at)
	if e != nil {
		t.Fatal(e)
	}
	in := []BoardInput{}
	for p := int64(1); p <= 101; p++ {
		in = append(in, BoardInput{
			Metric:  BoardMetric{Player: identity.PlayerID(p), Owner: b.SourceOwner, Policy: b.SourcePolicy, Semantics: b.SourceSemantics, Revision: rev, PopulationDigest: strings.Repeat("b", 64), FieldID: b.FieldID, Value: 102 - p, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at},
			Display: BoardPresentation{Player: identity.PlayerID(p), Name: "Player", Level: 1},
		})
	}
	_, snapshot, e := BuildBoardSnapshot(root, at, rev, op, in)
	if e != nil {
		t.Fatal(e)
	}
	if len(snapshot.Entries) != 100 || snapshot.Entries[0].Metric.Player != 1 || snapshot.Entries[99].Metric.Player != 100 {
		t.Fatalf("top limit %d first=%d last=%d", len(snapshot.Entries), snapshot.Entries[0].Metric.Player, snapshot.Entries[len(snapshot.Entries)-1].Metric.Player)
	}
	if awards, e := snapshot.Awards(); e != nil || len(awards) != 0 {
		t.Fatal("dorm comfort granted titles", awards, e)
	}
}

func TestGirlsTitlesUseSourceTiersPositivePopulationAndFixedSnapshotTime(t *testing.T) {
	r, at, rev, op := girlsFixture()
	in := []BoardInput{}
	for p := int64(1); p <= 22; p++ {
		score := int64(1)
		if p == 22 {
			score = 0
		}
		in = append(in, girlsInput(p, score, at, rev))
	}
	_, s, e := BuildBoardSnapshot(r, at, rev, op, in)
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
	week, e := BoardWeek(at)
	if e != nil || week.Format(time.RFC3339) != "2026-10-12T00:00:00Z" {
		t.Fatal(week, e)
	}
	next, e := BoardWeek(at.Add(12 * time.Hour))
	if e != nil || next.Format(time.RFC3339) != "2026-10-19T00:00:00Z" {
		t.Fatal(next, e)
	}
	// A time zone on an input instant cannot change the policy's UTC week.
	zone, e := BoardWeek(at.In(time.FixedZone("offset", 8*3600)))
	if e != nil || !zone.Equal(week) {
		t.Fatal(zone, e)
	}
	_, empty, e := BuildBoardSnapshot(r, at, rev, op, []BoardInput{girlsInput(1, 0, at, rev)})
	if e != nil {
		t.Fatal(e)
	}
	none, e := empty.Awards()
	if e != nil || len(none) != 0 {
		t.Fatal(none, e)
	}
}

func TestI9_10DStarsAndAwakenBoardsUseExistingRosterMetrics(t *testing.T) {
	for _, want := range []struct {
		subtype, fieldID int64
		policy           string
	}{
		{10, 1008, StarCountPolicy},
		{12, 1009, AwakenCountPolicy},
	} {
		board, ok := BoardOfSubType(want.subtype)
		if !ok || board.Policy != want.policy || board.FieldID != want.fieldID || board.SourceOwner != "CharacterHero" || board.SourcePolicy != RosterMetricSourcePolicy || board.SourceSemantics != RosterMetricSourceSemantics || board.RowValue != "info_val" {
			t.Fatal(want, board)
		}
		if len(board.Titles) != 0 {
			t.Fatal("invented titles", board)
		}
	}
	if _, ok := BoardOfSubType(23); ok {
		t.Fatal("Sky Tower elite stays on the PetCampaign owner path")
	}
}

func TestI9_10ETopFiveForceBoardUsesCharacterHeroMetric(t *testing.T) {
	board, ok := BoardOfSubType(9)
	if !ok || board.Policy != TopForcePolicy || board.FieldID != 1012 || board.SourceOwner != "CharacterHero" || board.SourcePolicy != TopForceSourcePolicy || board.SourceSemantics != TopForceSemantics || board.RowValue != "info_val" {
		t.Fatal(board)
	}
	if len(board.Titles) != 0 {
		t.Fatal("invented titles", board)
	}
	for _, subtype := range []int64{13, 14, 28, 29, 35, 36, 40, 41} {
		if _, ok := BoardOfSubType(subtype); ok {
			t.Fatal("owner not delivered, board must stay unserved:", subtype)
		}
	}
}

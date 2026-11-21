package ranking

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

func girlsFixture() (BoardRoot, time.Time, string, ids.UUID) {
	at := time.Date(2026, 10, 18, 12, 0, 0, 0, time.UTC)
	r, _ := NewBoardRoot(GirlsBoard, 1, at)
	op, _ := ids.NewUUID()
	return r, at, strings.Repeat("a", 64), op
}

func TestGirlsSnapshotRejectsIncompleteConflictingOrTamperedInputs(t *testing.T) {
	r, at, rev, op := girlsFixture()
	one := boardEntry(GirlsBoard, 1, 1, at, at, rev)
	badOwner := one
	badOwner.Metric.Owner = "client"
	badObservation := one
	badObservation.Metric.ObservedAt = at.Add(time.Second)
	badPolicy := one
	badPolicy.Metric.Policy = "future"
	badDigest := one
	badDigest.Metric.PopulationDigest = ""
	badDisplay := one
	badDisplay.Display.Player = 2
	negative := one
	negative.Metric.Value = -1
	for _, v := range []BoardEntry{badOwner, badObservation, badPolicy, badDigest, badDisplay, negative} {
		if _, _, e := FreezeBoardSnapshot(r, at, rev, op, []BoardEntry{v}); e == nil {
			t.Fatal("accepted unqualified source", v)
		}
	}
	if _, _, e := FreezeBoardSnapshot(r, at, rev, op, []BoardEntry{one, one}); e == nil {
		t.Fatal("duplicate subject")
	}
	// K2: a backwards observation is taken at the stored board fact.
	if _, backwards, e := FreezeBoardSnapshot(r, at.Add(-time.Second), rev, op, []BoardEntry{one}); e != nil || !backwards.ObservedAt.Equal(r.UpdatedAt) {
		t.Fatal("backwards observation", backwards, e)
	}
	_, s, e := FreezeBoardSnapshot(r, at, rev, op, []BoardEntry{one})
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
	entries := make([]BoardEntry, 0, 101)
	for p := int64(1); p <= 101; p++ {
		entries = append(entries, boardEntry(b, p, 102-p, at, at, rev))
	}
	_, snapshot, e := FreezeBoardSnapshot(root, at, rev, op, entries)
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

func TestBoardWeekSwitchKeepsAnUnsettledLegacyPeriod(t *testing.T) {
	before := time.Date(2026, 11, 1, 20, 59, 59, 0, time.UTC) // Monday 04:59:59 GMT+8
	if got, e := BoardWeek(before); e != nil || !got.Equal(time.Date(2026, 10, 25, 21, 0, 0, 0, time.UTC)) {
		t.Fatal(got, e)
	}
	after := time.Date(2026, 11, 1, 21, 0, 0, 0, time.UTC) // Monday 05:00 GMT+8
	if got, e := BoardWeek(after); e != nil || !got.Equal(after) {
		t.Fatal(got, e)
	}
	at := time.Date(2026, 11, 2, 1, 0, 0, 0, time.UTC) // Monday 09:00 GMT+8, before the old week rolls at 08:00 UTC
	legacy, e := LegacyBoardWeek(at)
	if e != nil {
		t.Fatal(e)
	}
	if kept, e := BindWeek(at, true); e != nil || !kept.Equal(legacy) {
		t.Fatalf("unsettled legacy period %v %v", kept, e)
	}
	if fresh, e := BindWeek(at, false); e != nil || !fresh.Equal(time.Date(2026, 11, 1, 21, 0, 0, 0, time.UTC)) {
		t.Fatalf("new game week %v %v", fresh, e)
	}
}

// Settlement validates a period against the snapshot it settles. A period
// written under the old UTC week still validates across the switch, so the
// settled period is neither skipped nor settled twice.
func TestLegacyBoardPeriodSettlesTheSwitchSnapshotOnce(t *testing.T) {
	r, at, rev, op := girlsFixture()
	_, snapshot, e := FreezeBoardSnapshot(r, at, rev, op, []BoardEntry{boardEntry(GirlsBoard, 1, 1, at, at, rev)})
	if e != nil {
		t.Fatal(e)
	}
	legacy, e := LegacyBoardWeek(at)
	if e != nil {
		t.Fatal(e)
	}
	period := BoardPeriod{Server: int64(snapshot.Server), Policy: snapshot.Policy, Week: legacy, Generation: snapshot.Generation}
	if e = period.Validate(snapshot); e != nil {
		t.Fatalf("legacy period rejected: %v", e)
	}
	settled := at.Add(time.Hour)
	period.SettledAt = &settled
	if e = period.Validate(snapshot); e != nil {
		t.Fatalf("settled legacy period rejected: %v", e)
	}
}

func TestGirlsTitlesUseSourceTiersPositivePopulationAndFixedSnapshotTime(t *testing.T) {
	r, at, rev, op := girlsFixture()
	entries := []BoardEntry{}
	for p := int64(1); p <= 22; p++ {
		score := int64(1)
		if p == 22 {
			score = 0
		}
		entries = append(entries, boardEntry(GirlsBoard, p, score, at, at, rev))
	}
	_, s, e := FreezeBoardSnapshot(r, at, rev, op, entries)
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
	if e != nil || week.Format(time.RFC3339) != "2026-10-11T21:00:00Z" {
		t.Fatal(week, e)
	}
	next, e := BoardWeek(at.Add(12 * time.Hour))
	if e != nil || next.Format(time.RFC3339) != "2026-10-18T21:00:00Z" {
		t.Fatal(next, e)
	}
	// A time zone on an input instant cannot change the policy's game week.
	zone, e := BoardWeek(at.In(time.FixedZone("offset", 8*3600)))
	if e != nil || !zone.Equal(week) {
		t.Fatal(zone, e)
	}
	_, empty, e := FreezeBoardSnapshot(r, at, rev, op, []BoardEntry{boardEntry(GirlsBoard, 1, 0, at, at, rev)})
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
	for _, subtype := range []int64{13} {
		if _, ok := BoardOfSubType(subtype); ok {
			t.Fatal("owner not delivered, board must stay unserved:", subtype)
		}
	}
}

func TestI912BloodAwakenAndOccultChapterBoards(t *testing.T) {
	blood, ok := BoardOfSubType(14)
	if !ok || blood.Policy != BloodAwakenPolicy || blood.FieldID != 1013 || blood.SourceOwner != "CharacterHero" || blood.SourcePolicy != BloodAwakenSourcePolicy || blood.SourceSemantics != BloodAwakenSemantics || blood.RowValue != "info_val" || blood.ChapterID != 0 || len(blood.Titles) != 0 {
		t.Fatal(blood, ok)
	}
	want := map[int64]int64{28: 1, 29: 2, 35: 3, 36: 4, 40: 5, 41: 6}
	for subtype, chapter := range want {
		board, ok := BoardOfSubType(subtype)
		if !ok || board.ChapterID != chapter || board.SourceOwner != "Occult" || board.SourcePolicy != OccultChapterSourcePolicy || board.SourceSemantics != OccultChapterSemantics || board.RowValue != "point" || board.FieldID != 3000+chapter || len(board.Titles) != 0 || board.TitledRanks != 0 {
			t.Fatal(subtype, board, ok)
		}
		if _, dup := BoardOf(board.Policy); !dup {
			t.Fatal("chapter board missing from Boards:", subtype)
		}
	}
	if !IsServedEmptySubType(13) || IsServedEmptySubType(14) || IsServedEmptySubType(28) {
		t.Fatal("served-empty set must keep only the unbuilt tabs")
	}
}

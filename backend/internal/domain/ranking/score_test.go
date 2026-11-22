package ranking

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func boardEntry(b Board, pid, score int64, at, since time.Time, rev string) BoardEntry {
	return BoardEntry{
		Metric:     BoardMetric{Player: identity.PlayerID(pid), Owner: b.SourceOwner, Policy: b.SourcePolicy, Semantics: b.SourceSemantics, Revision: rev, PopulationDigest: strings.Repeat("b", 64), FieldID: b.FieldID, Value: score, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at},
		Display:    BoardPresentation{Player: identity.PlayerID(pid), Name: "Player", Level: 1},
		ScoreSince: since,
	}
}

func TestNextScoreRowKeepsSinceOnlyWhileScoreAndRevisionHold(t *testing.T) {
	_, at, rev, _ := girlsFixture()
	later := at.Add(time.Hour)
	prev := ScoreRow{Policy: GirlsBoard.Policy, Server: 1, Player: 9, Score: 5, ScoreSince: at, Revision: rev, Metric: boardEntry(GirlsBoard, 9, 5, at, at, rev).Metric, UpdatedAt: at}
	if e := prev.Validate(); e != nil {
		t.Fatal(e)
	}
	kept, e := NextScoreRow(&prev, boardEntry(GirlsBoard, 9, 5, later, later, rev).Metric, later)
	if e != nil || !kept.ScoreSince.Equal(at) || kept.Server != 1 || kept.Player != 9 || kept.Score != 5 || !kept.UpdatedAt.Equal(later) {
		t.Fatal(kept, e)
	}
	raised, e := NextScoreRow(&prev, boardEntry(GirlsBoard, 9, 6, later, later, rev).Metric, later)
	if e != nil || !raised.ScoreSince.Equal(later) {
		t.Fatal(raised, e)
	}
	revisionChanged, e := NextScoreRow(&prev, boardEntry(GirlsBoard, 9, 5, later, later, strings.Repeat("d", 64)).Metric, later)
	if e != nil || !revisionChanged.ScoreSince.Equal(later) {
		t.Fatal(revisionChanged, e)
	}
	fresh, e := NextScoreRow(nil, boardEntry(GirlsBoard, 9, 5, later, later, rev).Metric, later)
	if e != nil || !fresh.ScoreSince.Equal(later) || fresh.Server != 0 {
		t.Fatal(fresh, e)
	}
	bad := boardEntry(GirlsBoard, 9, 5, later, later, rev).Metric
	bad.Owner = "client"
	if _, e = NextScoreRow(&prev, bad, later); e == nil {
		t.Fatal("accepted unqualified owner")
	}
	skewed := boardEntry(GirlsBoard, 9, 5, later, later, rev).Metric
	skewed.ObservedAt = later.Add(time.Second)
	if _, e = NextScoreRow(&prev, skewed, later); e == nil {
		t.Fatal("accepted a metric observed after the decision instant")
	}
}

func TestFreezeBoardSnapshotOrdersStoredSinceAndStableID(t *testing.T) {
	root, at, rev, op := girlsFixture()
	entries := []BoardEntry{
		boardEntry(GirlsBoard, 7, 5, at, at.Add(-2*time.Hour), rev),
		boardEntry(GirlsBoard, 1, 5, at, at.Add(-time.Hour), rev),
		boardEntry(GirlsBoard, 9, 5, at, at.Add(-3*time.Hour), rev),
		boardEntry(GirlsBoard, 3, 5, at, at.Add(-2*time.Hour), rev),
	}
	next, snapshot, e := FreezeBoardSnapshot(root, at, rev, op, entries)
	if e != nil || snapshot.Generation != root.NextGeneration || next.NextGeneration != root.NextGeneration+1 {
		t.Fatal(next, snapshot, e)
	}
	profile := Profile{ID: CurrentObserved, PolicyVersion: GirlsBoard.Policy, Generation: "1", TieBreak: StableID, Scope: Scope{Kind: "SERVER", ServerID: 1, Cohort: ServerCohort}, ObservedAt: at}
	in := make([]Entry, 0, len(entries))
	for _, v := range entries {
		in = append(in, Entry{SubjectID: int64(v.Metric.Player), Score: v.Metric.Value, ScoreSince: v.ScoreSince, Basis: CurrentObserved, PolicyVersion: GirlsBoard.Policy, Generation: "1", Scope: profile.Scope})
	}
	ordered, e := Order(profile, in)
	if e != nil || len(snapshot.Entries) != len(ordered) {
		t.Fatal(ordered, snapshot, e)
	}
	for i, want := range ordered {
		if int64(snapshot.Entries[i].Metric.Player) != want.SubjectID || !snapshot.Entries[i].ScoreSince.Equal(want.ScoreSince) {
			t.Fatalf("entry %d = %d@%s, want %d@%s", i, snapshot.Entries[i].Metric.Player, snapshot.Entries[i].ScoreSince, want.SubjectID, want.ScoreSince)
		}
	}
}

func TestFreezeBoardSnapshotRejectsInvalidEntries(t *testing.T) {
	root, at, rev, op := girlsFixture()
	good := boardEntry(GirlsBoard, 9, 5, at, at, rev)
	future := good
	future.ScoreSince = at.Add(time.Second)
	badOwner := good
	badOwner.Metric.Owner = "client"
	badTime := good
	badTime.Metric.ObservedAt = at.Add(time.Second)
	negative := good
	negative.Metric.Value = -1
	for _, entries := range [][]BoardEntry{{future}, {good, good}, {badOwner}, {badTime}, {negative}} {
		if _, _, e := FreezeBoardSnapshot(root, at, rev, op, entries); e == nil {
			t.Fatal("accepted invalid frozen entry", entries)
		}
	}
	// K2: a backwards observation is taken at the stored board fact.
	if _, backwards, e := FreezeBoardSnapshot(root, at.Add(-time.Second), rev, op, []BoardEntry{good}); e != nil || !backwards.ObservedAt.Equal(root.UpdatedAt) {
		t.Fatal("backwards observation", backwards, e)
	}
}

func TestFreezeBoardSnapshotKeepsBoardLimit(t *testing.T) {
	at := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)
	rev := strings.Repeat("a", 64)
	op, _ := ids.NewUUID()
	root, e := NewBoardRoot(DormComfortBoard, 1, at)
	if e != nil {
		t.Fatal(e)
	}
	entries := make([]BoardEntry, 0, 101)
	for p := int64(1); p <= 101; p++ {
		entries = append(entries, boardEntry(DormComfortBoard, p, 102-p, at, at, rev))
	}
	_, snapshot, e := FreezeBoardSnapshot(root, at, rev, op, entries)
	if e != nil || len(snapshot.Entries) != 100 || snapshot.Entries[0].Metric.Player != 1 || snapshot.Entries[99].Metric.Player != 100 {
		t.Fatal(len(snapshot.Entries), e)
	}
}

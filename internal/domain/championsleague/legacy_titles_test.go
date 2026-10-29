package championsleague

import (
	"strings"
	"testing"
	"time"
)

func TestLegacyTitleRootKeepsUnknownOldMarkerAndRejectsFutureMarker(t *testing.T) {
	at := time.Date(2026, 10, 29, 0, 0, 0, 0, time.UTC)
	root := Root{Revision: strings.Repeat("a", 64), Season: 1, Version: 1, CreatedAt: at, UpdatedAt: at}
	if root.Validate() != nil {
		t.Fatal("legacy root rejected")
	}
	root.LegacyTitlesSince = at
	if root.Validate() != nil {
		t.Fatal("explicit rollout marker rejected")
	}
	root.LegacyTitlesSince = at.Add(time.Second)
	if root.Validate() == nil {
		t.Fatal("future rollout marker accepted")
	}
	for _, identifier := range []int64{100077, 100081} {
		if IsLegacyTitle(identifier) {
			t.Fatal("unsupported legacy title")
		}
	}
}

func TestLegacyTitlePlacementRefusesBackfillAndUnqualifiedRanks(t *testing.T) {
	at := time.Date(2026, 10, 29, 0, 0, 0, 0, time.UTC)
	for _, check := range []struct {
		group, rank  int64
		participated bool
		offset       int
		known        bool
		expected     bool
	}{{3, 1, true, 0, true, true}, {3, 10, true, 1, true, true}, {3, 11, true, 0, true, false}, {2, 1, true, 0, true, false}, {3, 1, false, 0, true, false}, {3, 1, true, -1, true, false}, {3, 1, true, 0, false, false}, {3, 0, true, 0, true, false}} {
		since := at
		if !check.known {
			since = time.Time{}
		}
		actual := LegacyTitlePlacementEligible(Placement{Group: check.group, Rank: check.rank, Participated: check.participated}, at.Add(time.Duration(check.offset)*time.Second), since)
		if actual != check.expected {
			t.Fatal(check, actual)
		}
	}
}

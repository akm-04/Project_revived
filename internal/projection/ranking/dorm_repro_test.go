package ranking

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// Lead reproduction (contract recovery, I9_DORM_SOCIAL_GLUE_RANKING_V1 limit 100):
// a viewer ranked 101st must still get the published list.
func TestLeadReproDormViewerBelowLimitStillReadsBoard(t *testing.T) {
	at := time.Date(2026, 10, 18, 12, 0, 0, 0, time.UTC)
	rev := strings.Repeat("a", 64)
	root, err := d.NewBoardRoot(d.DormComfortBoard, 1, at)
	if err != nil {
		t.Fatal(err)
	}
	op, _ := ids.NewUUID()
	in := []d.BoardInput{}
	for pid := int64(1); pid <= 101; pid++ {
		in = append(in, d.BoardInput{Metric: d.BoardMetric{Player: identity.PlayerID(pid), Owner: d.DormComfortBoard.SourceOwner, Policy: d.DormComfortBoard.SourcePolicy, Semantics: d.DormComfortBoard.SourceSemantics, Revision: rev, PopulationDigest: strings.Repeat("b", 64), FieldID: d.DormComfortBoard.FieldID, Value: 1000 - pid, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at}, Display: d.BoardPresentation{Player: identity.PlayerID(pid), Name: "P", Level: 1}})
	}
	_, snapshot, err := d.BuildBoardSnapshot(root, at, rev, op, in)
	if err != nil || len(snapshot.Entries) != 100 {
		t.Fatalf("snapshot %d entries, %v", len(snapshot.Entries), err)
	}
	if _, err := BoardList(snapshot, 1); err != nil {
		t.Fatalf("rank 1 viewer: %v", err)
	}
	if _, err := BoardList(snapshot, 101); err != nil {
		t.Fatalf("rank 101 viewer cannot read the board: %v", err)
	}
}

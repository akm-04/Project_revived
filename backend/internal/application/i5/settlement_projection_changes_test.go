package i5

import (
	"context"
	"slices"
	"testing"

	"gxb.local/backend/v2/internal/foundation/changes"
)

func TestSettlementProjectionReportsItsWireState(t *testing.T) {
	ctx, set := changes.Track(context.Background())
	SettlementProjection{Economy: map[string]int64{"crystal": 950, "spirit_energy": 160}, NewFunctionIDs: []int64{12, 7}}.RecordChanges(ctx)
	balances := set.Balances()
	if balances["crystal"] != 950 || balances["spirit_energy"] != 160 || len(balances) != 2 {
		t.Fatalf("recorded balances %#v", balances)
	}
	if opened := set.Functions(); !slices.Equal(opened, []int64{7, 12}) {
		t.Fatalf("recorded functions %v", opened)
	}
}

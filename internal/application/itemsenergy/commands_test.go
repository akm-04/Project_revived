package itemsenergy

import (
	"errors"
	"testing"

	d "gxb.local/backend/v2/internal/domain/itemsenergy"
)

func TestAggregateItemsMergesAndBounds(t *testing.T) {
	merged, err := aggregateItems([]ItemAmount{{ItemID: 1, Num: 2}, {ItemID: 2, Num: 1}, {ItemID: 1, Num: 3}})
	if err != nil || len(merged) != 2 || merged[0].ItemID != 1 || merged[0].Num != 5 {
		t.Fatalf("merge = %+v %v", merged, err)
	}
	items := make([]ItemAmount, 0, 201)
	for id := int64(1); id <= 201; id++ {
		items = append(items, ItemAmount{ItemID: id, Num: 1})
	}
	if _, err := aggregateItems(items); !errors.Is(err, d.ErrInvalid) {
		t.Fatalf("201 distinct items accepted: %v", err)
	}
	if _, err := aggregateItems(items[:200]); err != nil {
		t.Fatal(err)
	}
	for _, invalid := range [][]ItemAmount{{}, {{ItemID: 0, Num: 1}}, {{ItemID: 1, Num: 0}}} {
		if _, err := aggregateItems(invalid); !errors.Is(err, d.ErrInvalid) {
			t.Fatalf("invalid list accepted: %+v", invalid)
		}
	}
}

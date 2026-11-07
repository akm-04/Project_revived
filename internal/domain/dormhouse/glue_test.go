package dormhouse

import "testing"

func TestGlueRulesQualifiedLookup(t *testing.T) {
	glue := GlueRules{
		DailyFloor:         100,
		PurchaseAmount:     50,
		PurchaseStartLimit: 300,
		VIPDailyCaps:       map[int64]int64{0: 1, 15: 16},
		PurchaseCosts:      map[int64]int64{1: 50, 16: 400},
	}
	if cap, ok := glue.VIPDailyCap(15); !ok || cap != 16 {
		t.Fatalf("VIPDailyCap(15) = %d,%v", cap, ok)
	}
	if _, ok := glue.VIPDailyCap(16); ok {
		t.Fatal("unknown VIP returned a guessed cap")
	}
	if cost, ok := glue.PurchaseCost(16); !ok || cost != 400 {
		t.Fatalf("PurchaseCost(16) = %d,%v", cost, ok)
	}
	if _, ok := glue.PurchaseCost(17); ok {
		t.Fatal("unknown purchase ordinal returned a guessed cost")
	}
}

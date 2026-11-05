package socialexchange

import (
	"errors"
	"math"
	"slices"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func testOperation(t *testing.T) operation.Context {
	t.Helper()
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	var seed [32]byte
	for index := range seed {
		seed[index] = byte(index + 1)
	}
	return operation.Context{ID: identifier, StartedAt: time.Unix(1_700_000_000, 0).UTC(), EntropySeed: seed}
}

func testCatalog() Catalog {
	return Catalog{
		ExchangeLimit: 10,
		Products: []Product{
			{ID: 1, GiftID: 9001, SellPrice: 100},
			{ID: 2, GiftID: 9002, SellPrice: 500},
			{ID: 3, GiftID: 9003, SellPrice: 700},
		},
		Gifts: []ExchangeGift{
			{ID: 9001, DropboxID: 510001},
			{ID: 9002, DropboxID: 510002},
			{ID: 9003, DropboxID: 510003},
		},
		Dropboxes: []Dropbox{
			{ID: 510001, Rolls: []Drop{
				{ID: 1, ItemID: 40001001, ItemNum: 1, Rate: 200},
				{ID: 2, ItemID: 40001002, ItemNum: 1, Rate: 9800},
			}},
			{ID: 510002, Rolls: []Drop{{ID: 3, ItemID: 50001046, ItemNum: 1, Rate: 10000}}},
			{ID: 510003, Rolls: []Drop{{ID: 4, ItemID: 50001024, ItemNum: 1, Rate: 10000}}},
		},
	}
}

func TestPlanAllProductsCostAndCompositeReward(t *testing.T) {
	op := testOperation(t)
	catalog := testCatalog()

	third, err := BuildPlan(catalog, 3, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if third.ProductID != 3 || third.DropboxID != 510003 || third.Count != 1 || third.UnitPrice != 700 || third.TotalCost != 700 || third.PriceCurrency != "friendship_coin" {
		t.Fatalf("product 3 plan wrong: %+v", third)
	}
	if len(third.Items) != 1 || third.Items[0] != (ItemQuantity{ItemID: 50001024, ItemNum: 1}) {
		t.Fatalf("product 3 reward wrong: %+v", third.Items)
	}

	second, err := BuildPlan(catalog, 2, 2, op)
	if err != nil {
		t.Fatal(err)
	}
	if second.TotalCost != 1000 || len(second.Items) != 1 || second.Items[0] != (ItemQuantity{ItemID: 50001046, ItemNum: 2}) {
		t.Fatalf("product 2 multiple draws wrong: %+v", second)
	}

	first, err := BuildPlan(catalog, 1, 10, op)
	if err != nil {
		t.Fatal(err)
	}
	if first.TotalCost != 1000 || first.Count != 10 || len(first.Items) == 0 {
		t.Fatalf("product 1 plan wrong: %+v", first)
	}
	total := int64(0)
	for _, item := range first.Items {
		total += item.ItemNum
		if item.ItemID != 40001001 && item.ItemID != 40001002 {
			t.Fatalf("product 1 emitted item outside its dropbox: %d", item.ItemID)
		}
	}
	if total != 10 {
		t.Fatalf("product 1 draw count wrong: %d", total)
	}
}

func TestPlanRetryStableAndOrdered(t *testing.T) {
	op := testOperation(t)
	catalog := testCatalog()
	first, err := BuildPlan(catalog, 1, 10, op)
	if err != nil {
		t.Fatal(err)
	}
	retry, err := BuildPlan(catalog, 1, 10, op)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(first.Items, retry.Items) || first.TotalCost != retry.TotalCost {
		t.Fatalf("retry changed the plan: %+v %+v", first, retry)
	}
	if !slices.IsSortedFunc(first.Items, func(left, right ItemQuantity) int {
		if left.ItemID < right.ItemID {
			return -1
		}
		if left.ItemID > right.ItemID {
			return 1
		}
		return 0
	}) {
		t.Fatalf("items are not deterministically ordered: %+v", first.Items)
	}
}

func TestPlanRejectsBadCountAndUnknownProduct(t *testing.T) {
	op := testOperation(t)
	catalog := testCatalog()
	for _, count := range []int64{0, -1, 11} {
		if _, err := BuildPlan(catalog, 1, count, op); !errors.Is(err, ErrCount) {
			t.Fatalf("count %d accepted: %v", count, err)
		}
	}
	if _, err := BuildPlan(catalog, 999, 1, op); !errors.Is(err, ErrUnknownProduct) {
		t.Fatalf("unknown product accepted: %v", err)
	}
	if _, err := BuildPlan(catalog, 1, 1, operation.Context{}); !errors.Is(err, ErrUnqualified) {
		t.Fatalf("zero operation accepted: %v", err)
	}
}

func TestPlanCheckedCostAndQuantityOverflow(t *testing.T) {
	op := testOperation(t)
	catalog := testCatalog()
	catalog.Products[0].SellPrice = math.MaxInt64
	if _, err := BuildPlan(catalog, 1, 2, op); !errors.Is(err, ErrOverflow) {
		t.Fatalf("cost overflow accepted: %v", err)
	}

	catalog = testCatalog()
	catalog.Dropboxes[2].Rolls[0].ItemNum = math.MaxInt64
	if _, err := BuildPlan(catalog, 3, 2, op); !errors.Is(err, ErrOverflow) {
		t.Fatalf("quantity overflow accepted: %v", err)
	}
}

func TestCatalogQualification(t *testing.T) {
	badWeight := testCatalog()
	badWeight.Dropboxes[0].Rolls[0].Rate = 199
	missingGift := testCatalog()
	missingGift.Gifts = missingGift.Gifts[:1]
	duplicateItem := testCatalog()
	duplicateItem.Dropboxes[0].Rolls[1].ItemID = duplicateItem.Dropboxes[0].Rolls[0].ItemID
	for name, catalog := range map[string]Catalog{
		"bad weight":     badWeight,
		"missing gift":   missingGift,
		"duplicate item": duplicateItem,
	} {
		t.Run(name, func(t *testing.T) {
			if err := catalog.Validate(); !errors.Is(err, ErrUnqualified) {
				t.Fatalf("unqualified catalog accepted: %v", err)
			}
			if _, err := BuildPlan(catalog, 1, 1, testOperation(t)); err == nil {
				t.Fatal("plan built from unqualified catalog")
			}
		})
	}
}

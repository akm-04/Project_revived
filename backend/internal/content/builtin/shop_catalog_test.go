package builtin

import (
	"strconv"
	"testing"
)

// C2/C9: the compiled drop rolls carry the source stone for every sell_type
// 7/15 row and none for the other currencies.
func TestCompiledShopCatalogCarriesSourceStones(t *testing.T) {
	loaded, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	var catalog ShopCatalog
	if err = decodeAndVerify("shop_catalog.json", loaded.Manifest.ArtifactSHA256s, &catalog); err != nil {
		t.Fatal(err)
	}
	if err = QualifyShopCatalog(catalog); err != nil {
		t.Fatal(err)
	}
	stoneRolls, otherRolls := 0, 0
	for key, rolls := range catalog.Groups {
		for _, roll := range rolls {
			switch roll.SellType {
			case 7, 15:
				if roll.StoneID <= 0 {
					t.Fatalf("group %s item %d has no stone_id", key, roll.ItemID)
				}
				stoneRolls++
			default:
				if roll.StoneID != 0 {
					t.Fatalf("group %s item %d carries stone_id %d", key, roll.ItemID, roll.StoneID)
				}
				otherRolls++
			}
		}
	}
	if stoneRolls == 0 || otherRolls == 0 {
		t.Fatalf("compiled rolls: %d stone, %d other", stoneRolls, otherRolls)
	}
}

// R9: shop type 29 serves the recovered object_book_shop stock, six slots of
// one single-roll crystal dropbox each.
func TestCompiledShopCatalogServesCourseBooks(t *testing.T) {
	loaded, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	var catalog ShopCatalog
	if err = decodeAndVerify("shop_catalog.json", loaded.Manifest.ArtifactSHA256s, &catalog); err != nil {
		t.Fatal(err)
	}
	if err = QualifyShopCatalog(catalog); err != nil {
		t.Fatal(err)
	}
	var courseBooks *ShopConfig
	for position := range catalog.Shops {
		if catalog.Shops[position].Type == 29 {
			courseBooks = &catalog.Shops[position]
		}
	}
	if courseBooks == nil {
		t.Fatal("shop type 29 is not compiled")
	}
	if courseBooks.FunctionID != 51 || courseBooks.SlotNum != 6 || courseBooks.ShopTable != "object_book_shop" ||
		courseBooks.RefreshType != 0 || courseBooks.RefreshKey != "0" || len(courseBooks.RefreshTimes) != 0 || courseBooks.IsUnlimit != 1 {
		t.Fatalf("type 29 config drift: %#v", courseBooks)
	}
	table := catalog.StockTables["object_book_shop"]
	if len(table.Rows) != 100 {
		t.Fatalf("object_book_shop rows = %d, want 100", len(table.Rows))
	}
	want := []struct {
		itemID int64
		price  int64
	}{
		{50001423, 2500}, {50001420, 20}, {50001418, 300},
		{50001421, 100}, {50001419, 1500}, {50001422, 500},
	}
	for _, row := range table.Rows {
		if len(row.Slots) != len(want) {
			t.Fatalf("row %d slot count = %d, want %d", row.ID, len(row.Slots), len(want))
		}
		for position, slot := range row.Slots {
			if len(slot.Groups) != 1 {
				t.Fatalf("row %d slot %d group count = %d, want 1", row.ID, position+1, len(slot.Groups))
			}
			rolls := catalog.Groups[strconv.FormatInt(slot.Groups[0].DropboxID, 10)]
			if len(rolls) != 1 {
				t.Fatalf("row %d slot %d roll count = %d, want 1", row.ID, position+1, len(rolls))
			}
			roll := rolls[0]
			if roll.ItemID != want[position].itemID || roll.SellPrice != want[position].price ||
				roll.ItemNum != 1 || roll.SellType != 2 || roll.Discount != 0 || roll.Rate != 10000 {
				t.Fatalf("row %d slot %d roll drift: %#v", row.ID, position+1, roll)
			}
		}
	}
}

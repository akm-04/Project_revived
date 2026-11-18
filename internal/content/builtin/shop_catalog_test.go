package builtin

import "testing"

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

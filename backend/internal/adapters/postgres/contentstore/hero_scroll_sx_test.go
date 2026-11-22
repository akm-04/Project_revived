package contentstore

import (
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/summon"
)

// TestHeroScrollSXClassification guards the source-qualified SX flag: the
// compiled Vending catalog carries partner.is_sx, which is not hero_kind. All
// 73 SX scrolls belong to NORMAL-kind partner rows, so a SuperHero predicate
// can never select them.
func TestHeroScrollSXClassification(t *testing.T) {
	summonRaw, err := builtin.GeneratedFile("summon_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog summon.Catalog
	if err = json.Unmarshal(summonRaw, &catalog); err != nil {
		t.Fatal(err)
	}
	heroRaw, err := builtin.GeneratedFile("hero_core_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var heroes struct {
		AcquisitionItems []struct {
			ItemID        int64 `json:"item_id"`
			OriginTableID int64 `json:"origin_table_id"`
		} `json:"acquisition_items"`
		Templates []struct {
			TableID  int64  `json:"table_id"`
			HeroKind string `json:"hero_kind"`
		} `json:"templates"`
	}
	if err = json.Unmarshal(heroRaw, &heroes); err != nil {
		t.Fatal(err)
	}
	kinds := make(map[int64]string, len(heroes.Templates))
	for _, template := range heroes.Templates {
		kinds[template.TableID] = template.HeroKind
	}

	sxCount, normalKindSX := 0, 0
	for _, item := range heroes.AcquisitionItems {
		sx, found := heroScrollSX(catalog, item.ItemID)
		if !found {
			t.Fatalf("acquisition item %d resolves no source partner", item.ItemID)
		}
		if !sx {
			continue
		}
		sxCount++
		if kinds[item.OriginTableID] == "NORMAL" {
			normalKindSX++
		}
	}
	if len(heroes.AcquisitionItems) != 291 || sxCount != 73 || normalKindSX != 73 {
		t.Fatalf("scroll classification items=%d sx=%d normal_kind_sx=%d", len(heroes.AcquisitionItems), sxCount, normalKindSX)
	}
	if sx, found := heroScrollSX(catalog, 40001032); !found || !sx {
		t.Fatalf("Guan Yin scroll 40001032 sx=%v found=%v", sx, found)
	}
	if sx, found := heroScrollSX(catalog, 40001001); !found || sx {
		t.Fatalf("normal scroll 40001001 sx=%v found=%v", sx, found)
	}
	if _, found := heroScrollSX(catalog, 1); found {
		t.Fatal("unknown item resolved a source partner")
	}
}

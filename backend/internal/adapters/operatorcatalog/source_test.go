package operatorcatalog

import (
	"testing"
	"time"

	appcatalog "gxb.local/backend/v2/internal/application/operatorcatalog"
)

// The generated catalogue already carries the client item type and the stack
// cap; Load must hand both to the picker, so equipment and girl scrolls are
// findable and the horcrux type stays fail closed.
func TestLoadCarriesClientItemTypesCategoriesAndStackCaps(t *testing.T) {
	document, err := Load(time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	equipment, found := document.Lookup("stack_item:20001001")
	if !found || equipment.Grantable != "ENABLED" {
		t.Fatalf("equipment = %+v found=%v", equipment, found)
	}
	if equipment.ItemType == nil || *equipment.ItemType != 1 || equipment.Category != "Equipment" {
		t.Fatalf("equipment type/category = %+v", equipment)
	}
	if equipment.StackCap == nil || *equipment.StackCap != 999 {
		t.Fatalf("equipment stack cap = %v", equipment.StackCap)
	}
	scroll, found := document.Lookup("stack_item:41001")
	if !found || scroll.Grantable != "ENABLED" {
		t.Fatalf("scroll = %+v found=%v", scroll, found)
	}
	if scroll.ItemType == nil || *scroll.ItemType != 3 || scroll.Category != "Soul stone" {
		t.Fatalf("scroll type/category = %+v", scroll)
	}
	horcrux, found := document.Lookup("specialized:item:250000111")
	if !found || horcrux.Grantable != "FAIL_CLOSED" {
		t.Fatalf("horcrux = %+v found=%v", horcrux, found)
	}
	if horcrux.ItemType == nil || *horcrux.ItemType != 24 || horcrux.Category != "Horcrux" {
		t.Fatalf("horcrux type/category = %+v", horcrux)
	}
}

// The compiled client item rows carry item.lua's consumable subtype, and the
// compiled appearance catalogue names the girl a skin item unlocks, so skins
// are a category, a readable name and a search target instead of a hidden
// consumable.
func TestLoadCarriesSkinSubtypeAndGirlName(t *testing.T) {
	document, err := Load(time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	skin, found := document.Lookup("stack_item:50001040")
	if !found || skin.Grantable != "ENABLED" {
		t.Fatalf("skin = %+v found=%v", skin, found)
	}
	if skin.Category != "Skin" || skin.Name != "Stadium Star (Tennese skin)" {
		t.Fatalf("skin category/name = %+v", skin)
	}
	if skin.SubType == nil || *skin.SubType != 8 {
		t.Fatalf("skin subtype = %v", skin.SubType)
	}
	timed, found := document.Lookup("stack_item:50001807")
	if !found || timed.Category != "Skin" || timed.Name != "造型體驗卡 (Iron Fist skin)" {
		t.Fatalf("timed skin = %+v found=%v", timed, found)
	}
	byGirl, err := document.Search(appcatalog.SearchFilter{Query: "TENNESE"})
	if err != nil || !containsEntry(byGirl.Entries, "stack_item:50001040") {
		t.Fatalf("girl name search = %+v err=%v", byGirl, err)
	}
	byWord, err := document.Search(appcatalog.SearchFilter{Query: "Skin"})
	if err != nil || !containsEntry(byWord.Entries, "stack_item:50001040") {
		t.Fatalf("skin word search = %+v err=%v", byWord, err)
	}
	category, subType := int64(4), int64(8)
	page, err := document.Search(appcatalog.SearchFilter{Category: &category, SubType: &subType, Limit: appcatalog.MaxSearchLimit})
	if err != nil || len(page.Entries) != appcatalog.MaxSearchLimit {
		t.Fatalf("skin category page = %d err=%v", len(page.Entries), err)
	}
	skinBucket := false
	for _, bucket := range page.Categories {
		if bucket.ItemType != category || bucket.SubType == nil || *bucket.SubType != subType {
			continue
		}
		skinBucket = bucket.Label == "Skin" && bucket.Count == 266
	}
	if !skinBucket {
		t.Fatalf("skin bucket = %+v", page.Categories)
	}
}

func containsEntry(entries []appcatalog.Entry, id string) bool {
	for _, entry := range entries {
		if entry.ID == id {
			return true
		}
	}
	return false
}

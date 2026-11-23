package operatorcatalog

import (
	"testing"
	"time"
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

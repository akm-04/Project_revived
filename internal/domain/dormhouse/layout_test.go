package dormhouse

import (
	"errors"
	"testing"
)

func layoutCatalog() Catalog {
	return Catalog{Rooms: map[int64]RoomRule{1: {MainType: 2, Length: 8, Width: 8, Height: 7, Dresser: 10}}, Types: map[int64]TypeRule{2: {Residents: 1}}, Furniture: map[int64]FurnitureRule{
		10: {ItemID: 10, Floor: 2, Length: 3, Width: 2, Height: 4, Panels: []int64{1}, CanRotate: true},
		11: {ItemID: 11, Comfort: 4, Floor: 2, Length: 3, Width: 3, Height: 2, Panels: []int64{1}, CanBePile: true, PileLimit: true, PileStart: []int64{1, 1}, PileEnd: []int64{3, 3}},
		12: {ItemID: 12, Comfort: 2, Floor: 3, Length: 1, Width: 1, Panels: []int64{1}, CanPile: true},
		13: {ItemID: 13, Comfort: 1, Floor: 1, Length: 8, Width: 8, Panels: []int64{1}},
		14: {ItemID: 14, Comfort: 1, Floor: 0, Length: 1, Width: 1, Panels: []int64{2, 3}, SpecialType: 2},
	}}
}
func TestLayoutGraphSupportAndInventory(t *testing.T) {
	c := layoutCatalog()
	child := "11#5#5#0|12#2#2#0"
	record := map[string]string{"10#1#1#0": "", "11#5#5#0": child, child: "", "13#1#1#0": "", "14#1#1#1": ""}
	v, e := c.ValidateLayout(1, 0, record)
	if e != nil || v.Comfort != 8 || v.InventoryMinimum[10] != 0 || v.Used[10] != 1 || v.FreeResidentCells != 49 {
		t.Fatal(v, e)
	}
	p := v.Placements[len(v.Placements)-1]
	if p.Key != child || p.AbsoluteX != 7 || p.AbsoluteY != 7 || p.Layer != 3 {
		t.Fatal(p)
	}
	broken := map[string]string{}
	for k, s := range record {
		broken[k] = s
	}
	broken["11#5#5#0"] = ""
	if _, e = c.ValidateLayout(1, 0, broken); !errors.Is(e, ErrInvalidLayout) {
		t.Fatal("lostchild accepted", e)
	}
	delete(broken, child)
	delete(broken, "11#5#5#0")
	invalidChild := "11#5#5#0|12#1#1#0"
	broken["11#5#5#0"] = invalidChild
	broken[invalidChild] = ""
	if _, e = c.ValidateLayout(1, 0, broken); !errors.Is(e, ErrInvalidLayout) {
		t.Fatal("outside support accepted", e)
	}
}
func TestLayoutCollisionBuiltInAndPanelBounds(t *testing.T) {
	c := layoutCatalog()
	for _, record := range []map[string]string{
		{}, {"10#1#1#0": "", "11#1#1#0": ""},
		{"10#1#1#0": "", "14#1#1#1": "", "14#1#1#0": "", "14#2#1#0": ""},
		{"10#8#8#0": ""},
		{"10#01#1#0": ""},
		{"10#1#1#0": "missing"},
	} {
		if _, e := c.ValidateLayout(1, 0, record); !errors.Is(e, ErrInvalidLayout) {
			t.Fatal(record, e)
		}
	}
	if _, e := c.ValidateLayout(1, 0, map[string]string{"10#1#1#1": ""}); e != nil {
		t.Fatal("valid rotation rejected", e)
	}
}

func TestLayoutFailureNamesActualPackedKey(t *testing.T) {
	_, e := layoutCatalog().ValidateLayout(1, 0, map[string]string{"10#8#8#0": ""})
	var bad *PlacementError
	if !errors.As(e, &bad) || bad.Key != "10#8#8#0" {
		t.Fatal(e)
	}
}

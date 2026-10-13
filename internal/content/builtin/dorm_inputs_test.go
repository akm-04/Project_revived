package builtin

import "testing"

func TestDormQualifiedPayloadAndEquipmentReuse(t *testing.T) {
	c, e := Load()
	if e != nil {
		t.Fatal(e)
	}
	d := c.DormInputs
	if e = d.Validate(); e != nil {
		t.Fatal(e)
	}
	if len(d.Rooms) != 16 || len(d.Furniture) != 267 || d.OriginalServerPolicyRecovered {
		t.Fatal("wrong profile")
	}
	primitives := map[int64]int64{}
	for _, r := range c.EquipmentPrimitives.Items {
		primitives[r.ItemID] = r.RequiredLevel
	}
	for _, r := range d.EquipmentItems {
		if primitives[r.ItemID] != r.RequiredLevel {
			t.Fatalf("Dorm item %d contradicts accepted equipment primitive", r.ItemID)
		}
	}
	for _, r := range d.HeroEquipment {
		if r.TemplateID == 11001 && r.Items[0] != 20001299 {
			t.Fatal("Super zero-before-awaken lost source", r)
		}
	}
	d.Keys = append([]DormKeyRule(nil), d.Keys...)
	d.Keys[0].Templates = []int64{999999}
	if d.Validate() == nil {
		t.Fatal("unknown room template qualified")
	}
}

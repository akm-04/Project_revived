package dormhouse

import (
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"testing"
)

func TestStockHouseRecordGroupsPlacementsByPanel(t *testing.T) {
	child := "50031013#1#1#0|90031001#1#1#0"
	layout := map[string]string{
		"50031013#1#1#0": child,
		child:            "",
		"50031002#1#1#0": "",
	}
	validated := dorm.LayoutResult{Placements: []dorm.Placement{
		{Key: "50031013#1#1#0", Panel: 1},
		{Key: child, Panel: 1},
		{Key: "50031002#1#1#0", Panel: 2},
	}}
	record := stockHouseRecord(layout, validated)
	if len(record) != dormPanelKinds {
		t.Fatalf("panel count %d", len(record))
	}
	if record[0]["50031013#1#1#0"] != child || record[0][child] != "" {
		t.Fatalf("floor panel %v", record[0])
	}
	if record[1]["50031002#1#1#0"] != "" || len(record[2]) != 0 {
		t.Fatalf("wall panels %v %v", record[1], record[2])
	}
}

func TestRoomWireTwiceAwakeStageKnownAndUnknown(t *testing.T) {
	room := dorm.Room{ID: 1, TableID: 7, Residents: []int64{10, 11, 12}}
	heroes := map[int64]character.Hero{
		10: {PartnerID: 10, TableID: 100},
		11: {PartnerID: 11, TableID: 101},
		12: {PartnerID: 12, TableID: 102},
	}
	wire := roomWire(room, heroes, map[int64]dorm.HeroFacts{}, socialRoomWire{}, map[int64]int64{10: 3, 11: 0})
	rows := wire["partner_infos"].([]any)
	if len(rows) != 3 {
		t.Fatalf("residents %d", len(rows))
	}
	row := func(index int) map[string]any { return rows[index].(map[string]any) }
	if got := row(0)["twice_awake_stage"]; got != int64(3) {
		t.Fatalf("stage 3 hero %v", got)
	}
	stage, present := row(1)["twice_awake_stage"]
	if !present || stage != int64(0) {
		t.Fatalf("stage 0 hero %v %v", stage, present)
	}
	if _, present := row(2)["twice_awake_stage"]; present {
		t.Fatal("unknown stage was invented")
	}
}

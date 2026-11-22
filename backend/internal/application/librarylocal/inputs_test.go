package librarylocal

import (
	"testing"

	lib "gxb.local/backend/v2/internal/domain/librarylocal"
)

func actCatalog() lib.Catalog {
	return lib.Catalog{Stages: []lib.StageRule{
		{ID: 1, Favor: 100, ActIDs: []int64{1}},
		{ID: 2, Favor: 300, ActIDs: []int64{1, 2}},
		{ID: 3, Favor: 800, ActIDs: []int64{1, 2, 3}},
		{ID: 4, Favor: 2000, ActIDs: []int64{1, 2, 3, 4}},
		{ID: 5, Favor: 2001, ActIDs: []int64{1, 2, 3, 4}},
	}}
}

// A-204 S30: 836 and 841 project the full unlocked set, a stored row as stored
// and a missing row as {process 0, mission_state 2}, ordered by mission_id.
func TestProjectPartnerMissionsProjectsUnlockedDefaults(t *testing.T) {
	catalog := lib.Catalog{Stages: []lib.StageRule{
		{ID: 1, Favor: 100, ActIDs: []int64{1}, MissionIDs: []int64{1001, 1002, 1003}},
		{ID: 2, Favor: 300, ActIDs: []int64{1, 2}, MissionIDs: []int64{1001, 1002, 1003, 1005}},
		{ID: 3, Favor: 800, ActIDs: []int64{1, 2, 3}, MissionIDs: []int64{1001, 1002, 1003, 1004, 1005}},
		{ID: 4, Favor: 2000, ActIDs: []int64{1, 2, 3, 4}, MissionIDs: []int64{1001, 1002, 1003, 1004, 1005, 1006}},
	}}
	stored := []lib.MissionFact{
		{PartnerID: 7, MissionID: 1001, Process: 1, MissionState: lib.MissionSuccess},
		{PartnerID: 8, MissionID: 1006, Process: 1, MissionState: lib.MissionAwarded},
	}
	rows := projectPartnerMissions(catalog, 0, 7, stored)
	wantIDs := []int64{1001, 1002, 1003}
	if len(rows) != len(wantIDs) {
		t.Fatalf("favor 0 rows %+v", rows)
	}
	for index, wantID := range wantIDs {
		row := rows[index].(map[string]any)
		if row["mission_id"] != wantID {
			t.Fatalf("row %d %+v", index, row)
		}
		wantProcess, wantState := int64(0), int64(lib.MissionProceed)
		if wantID == 1001 {
			wantProcess, wantState = 1, lib.MissionSuccess
		}
		if row["process"] != wantProcess || row["mission_state"] != wantState {
			t.Fatalf("row %d process/state %+v", index, row)
		}
	}
	top := projectPartnerMissions(catalog, 99999, 7, stored)
	if len(top) != 6 || top[5].(map[string]any)["mission_id"] != int64(1006) {
		t.Fatalf("above top rows %+v", top)
	}
	if top[5].(map[string]any)["mission_state"] != int64(lib.MissionProceed) {
		t.Fatalf("another partner's stored row leaked %+v", top[5])
	}
}

func TestProjectPartnerActsGatesByFavorBand(t *testing.T) {
	catalog := actCatalog()
	awards := []lib.ActAwardFact{{PartnerID: 1, ActID: 1}}
	for _, tc := range []struct {
		favor int64
		count int
	}{
		{0, 1}, {100, 1}, {101, 2}, {300, 2}, {301, 3}, {800, 3}, {801, 4}, {2000, 4},
	} {
		slots := projectPartnerActs(catalog, 1, tc.favor, awards)
		if len(slots) != tc.count {
			t.Fatalf("favor %d slots %d want %d", tc.favor, len(slots), tc.count)
		}
		if slots[0].IsAwarded != 1 {
			t.Fatalf("favor %d act 1 is_awarded %d", tc.favor, slots[0].IsAwarded)
		}
		for index := 1; index < len(slots); index++ {
			if slots[index].IsAwarded != 0 {
				t.Fatalf("favor %d act %d awarded", tc.favor, index+1)
			}
		}
	}
	other := projectPartnerActs(catalog, 2, 2000, []lib.ActAwardFact{{PartnerID: 1, ActID: 1}})
	if len(other) != 4 || other[0].IsAwarded != 0 {
		t.Fatalf("partner isolation %+v", other)
	}
}

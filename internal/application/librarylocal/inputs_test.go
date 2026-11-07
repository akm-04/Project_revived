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

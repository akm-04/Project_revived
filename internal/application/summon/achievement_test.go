package summon

import (
	"testing"

	d "gxb.local/backend/v2/internal/domain/summon"
)

func TestOnlyTheMediumTenPullButtonAdvancesTheAchievement(t *testing.T) {
	if !isMediumTenPull(d.Button{Type: 2, Index: 2, Family: d.MediumPaid, Pulls: 10}) {
		t.Fatal("the generated medium ten-pull button must advance 100012")
	}
	for _, button := range []d.Button{
		{Type: 2, Index: 1, Family: d.MediumPaid, Pulls: 1},
		{Type: 1, Index: 1, Family: d.Small, Pulls: 1},
		{Type: 3, Index: 2, Family: d.MediumFree, Pulls: 10},
		{Type: 4, Index: 1, Family: d.SX, Pulls: 1},
	} {
		if isMediumTenPull(button) {
			t.Fatalf("button %+v must not advance 100012", button)
		}
	}
}

func TestGirlResultCountCountsPartnersAndStonesNotItems(t *testing.T) {
	result := []any{
		map[string]any{"table_id": int64(20001001), "is_partner": true},
		map[string]any{"table_id": int64(50001001), "item_num": int64(3)},
		map[string]any{"table_id": int64(50001002), "to_stone": true},
		map[string]any{"table_id": int64(20001002)},
	}
	count, err := girlResultCount(result)
	if err != nil || count != 2 {
		t.Fatalf("girl rows = %d, err %v", count, err)
	}
	if _, err = girlResultCount(map[string]any{}); err == nil {
		t.Fatal("a non-array result must be refused")
	}
}

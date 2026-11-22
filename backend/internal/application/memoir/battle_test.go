package memoir

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/march"
	domain "gxb.local/backend/v2/internal/domain/memoir"
)

func TestEnemyInfoForPlayerProjectsStockTeamWindowFields(t *testing.T) {
	info, err := enemyInfoForPlayer(march.Enemy{Name: "Ada Moe", Level: 40, Pet: map[string]any{"table_id": int64(10010001)}}, domain.EnemyCarry{Round: 2})
	if err != nil {
		t.Fatal(err)
	}
	if info["player_name"] != "Ada Moe" || info["name"] != "Ada Moe" || info["level"] != float64(40) {
		t.Fatalf("name/level projection %#v", info)
	}
	if pet, present := info["pet"].(map[string]any); !present || pet["table_id"] != float64(10010001) {
		t.Fatalf("pet projection %#v", info["pet"])
	}
	if info["round"] != 2 {
		t.Fatalf("round projection %#v", info["round"])
	}
}

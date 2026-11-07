package adventure

import (
	"context"
	"testing"
	"time"

	cb "gxb.local/backend/v2/internal/application/combat"
)

func TestEnemyInfoRobotCarriesCatalogName(t *testing.T) {
	enemy := Opponent{
		Name:  "Ada Moe",
		Level: 40,
		Heroes: []cb.Participant{
			{TemplateParams: map[string]any{"partner_id": int64(10001001)}},
		},
	}
	info, err := (Mode{}).enemyInfo(context.Background(), enemy, time.Unix(100, 0).UTC())
	if err != nil {
		t.Fatal(err)
	}
	if info["player_name"] != "Ada Moe" || info["lev"] != int64(40) || info["is_robot"] != int64(1) {
		t.Fatalf("robot info=%v", info)
	}
	heroes, ok := info["heroes"].([]any)
	if !ok || len(heroes) != 1 {
		t.Fatalf("robot heroes=%v", info["heroes"])
	}
}

package topfloor

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

// TestEnemyCarriesPlayerTitleInfo proves the stock ArenaWindow enemy cell can
// read var_16_0.title_info and pass it to NewBattleLoadingWindow setPlayerTitle.
func TestEnemyCarriesPlayerTitleInfo(t *testing.T) {
	title := map[string]any{"title_id": int64(100001), "unique_id": int64(0), "end_time": int64(0)}
	view := d.Display{Occupant: d.Occupant{Player: identity.PlayerID(100001)}, Name: "defender", TitleInfo: title}
	row := Enemy(view)
	got, ok := row["title_info"].(map[string]any)
	if !ok || got["title_id"] != title["title_id"] || got["unique_id"] != title["unique_id"] || got["end_time"] != title["end_time"] {
		t.Fatalf("enemy title_info %#v", row["title_info"])
	}
	if empty := Enemy(d.Display{}); empty["title_info"] != nil {
		t.Fatalf("robot enemy carries title_info %#v", empty["title_info"])
	}
}

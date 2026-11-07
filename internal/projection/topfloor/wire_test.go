package topfloor

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

func TestFormationCarriesPetAndIdentity(t *testing.T) {
	pet := map[string]any{"pet_id": int64(7), "table_id": int64(20001001)}
	view := d.Display{Occupant: d.Occupant{Player: identity.PlayerID(100001)}, Rank: 4, Name: "defender", Level: 60, Wins: 2, Pet: pet}
	row := Formation(view)
	if row["rank"] != int64(4) || row["win"] != int64(2) || row["is_robot"] != false || row["table_id"] != int64(1) {
		t.Fatalf("formation identity %+v", row)
	}
	got, ok := row["pet"].(map[string]any)
	if !ok || got["pet_id"] != int64(7) || got["table_id"] != int64(20001001) {
		t.Fatalf("formation pet %#v", row["pet"])
	}
}

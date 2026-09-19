package characterstore

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestSavedPresetBootstrapProjectionClaimsOnlyThreeMID17Children(t *testing.T) {
	c := SavedPresetBootstrapProjection{}
	claims := c.Claims()
	if len(claims) != 3 || claims[0] != "17.save_team" || claims[1] != "17.save_team_name" || claims[2] != "17.save_pet" {
		t.Fatalf("claims=%v", claims)
	}
	for _, x := range claims {
		if x == "17.formation" {
			t.Fatal("formation claimed")
		}
	}
}

func TestSavedPresetBootstrapProjectionUsesCanonicalRows(t *testing.T) {
	q := &presetFakeTx{queryRows: map[string]presetRowFunc{characterqueries.ReadSavedPresetAggregate: aggregateReadRow()}}
	detail := map[string]any{"17": map[string]any{"formation": map[string]any{}, "save_team": "old", "save_team_name": "old", "save_pet": "old"}}
	if err := (SavedPresetBootstrapProjection{}).OverlayMID1(context.Background(), q, identity.ActorContext{PlayerID: 7}, false, time.Unix(200, 0).UTC(), detail); err != nil {
		t.Fatal(err)
	}
	m := detail["17"].(map[string]any)
	if m["save_team"] != "2|9:3" || m["save_team_name"] != "A|||" || m["save_pet"] != "4|0" {
		t.Fatalf("mid17=%v", m)
	}
	if _, ok := m["formation"]; !ok {
		t.Fatal("baseline formation mutated/removed")
	}
}

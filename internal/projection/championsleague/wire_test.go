package championsleague

import (
	"encoding/json"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestInfoSelfDefenseCarriesOwnedIdentities(t *testing.T) {
	body := Info(d.InfoView{
		Player:  d.Player{Points: 7},
		Defense: d.EnemyView{Face: d.Face{ID: identity.PlayerID(9)}, Heroes: []map[string]any{{"partner_id": int64(19), "star": int64(5)}, {"partner_id": int64(7)}}, Pet: map[string]any{"pet_id": int64(5), "star": int64(3)}, Lineup: d.Lineup{Heroes: []int64{19, 7}, Pet: 5}},
		Enemies: []d.EnemyView{{Face: d.Face{ID: 200007}, Heroes: []map[string]any{{"partner_id": int64(19), "star": int64(5)}}, Pet: map[string]any{"pet_id": int64(5), "star": int64(3)}}},
	})
	defense, ok := body["defense_info"].(map[string]any)
	if !ok {
		t.Fatalf("defense_info missing: %#v", body["defense_info"])
	}
	heroes, ok := defense["heros"].([]int64)
	if !ok || len(heroes) != 2 || heroes[0] != 19 || heroes[1] != 7 {
		t.Fatalf("defense_info.heros = %#v, want the owned ids in team order", defense["heros"])
	}
	if defense["pet"] != int64(5) {
		t.Fatalf("defense_info.pet = %#v, want the numeric owned pet id", defense["pet"])
	}
	enemies := body["enemy_info"].([]map[string]any)
	if _, ok := enemies[0]["heros"].([]map[string]any); !ok {
		t.Fatalf("enemy rows must keep the full hero maps: %#v", enemies[0]["heros"])
	}
	if _, ok := enemies[0]["pet"].(map[string]any); !ok {
		t.Fatalf("enemy rows must keep the full pet map: %#v", enemies[0]["pet"])
	}
}

func TestInfoSelfDefenseEmptyIsAnArrayAndZeroPet(t *testing.T) {
	body := Info(d.InfoView{Defense: d.EnemyView{Lineup: d.Lineup{}}})
	defense := body["defense_info"].(map[string]any)
	heroes, ok := defense["heros"].([]int64)
	if !ok || heroes == nil || len(heroes) != 0 {
		t.Fatalf("defense_info.heros = %#v, want a nonnull empty array", defense["heros"])
	}
	if defense["pet"] != int64(0) {
		t.Fatalf("defense_info.pet = %#v, want 0 without a saved pet", defense["pet"])
	}
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), `"heros":null`) || strings.Contains(string(raw), `"pet":null`) {
		t.Fatal(string(raw))
	}
}

package arena

import (
	"encoding/json"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/arena"
)

// ARENA_HERO_PICKS_V1: the client adds the award value to the roster value, so
// award rows never carry a count of their own.
func TestAwardRowsCarryZeroRegionArenaTimes(t *testing.T) {
	info := awards(d.Player{Awards: []d.Award{{TableID: 10001001, Picks: 7}}})
	if got := info[0]["region_arena_times"]; got != int64(0) {
		t.Fatalf("info award region_arena_times = %#v, want 0", got)
	}
	missions := Missions(d.MissionsView{Award: &d.Award{TableID: 10001002, Picks: 9}})
	row, ok := missions["award"].(map[string]any)
	if !ok {
		t.Fatalf("mission award row missing: %#v", missions["award"])
	}
	if got := row["region_arena_times"]; got != int64(0) {
		t.Fatalf("mission award region_arena_times = %#v, want 0", got)
	}
}

func TestEnemyCopiesPetStarForTheStockSelector(t *testing.T) {
	pet := map[string]any{"pet_id": int64(40001001), "table_id": int64(40001001), "star": int64(3)}
	info := Enemy(d.EnemyView{Pet: pet})["pet_info"].(map[string]any)
	if info["pet_star"] != int64(3) || info["star"] != int64(3) {
		t.Fatalf("pet_info = %#v", info)
	}
	if _, leaked := pet["pet_star"]; leaked {
		t.Fatal("Enemy mutated the shared pet projection")
	}
	if _, present := Enemy(d.EnemyView{})["pet_info"]; present {
		t.Fatal("no pet served a pet_info key")
	}
}

func TestPartnersCarriesTheSubjectStarAndOmitsAnUnownedGirl(t *testing.T) {
	three := int64(3)
	rows := Partners(d.PartnersView{Usage: []d.Usage{{TableID: 10001001, Star: &three}, {TableID: 10001002}}})["partner_info"].([]map[string]any)
	if rows[0]["star"] != int64(3) {
		t.Fatalf("owned girl row = %#v, want star 3", rows[0])
	}
	if _, present := rows[1]["star"]; present {
		t.Fatalf("unowned girl row = %#v, want no star key", rows[1])
	}
}

func TestInfoKeepsTheDefenceFormationAnArray(t *testing.T) {
	body := Info(d.InfoView{Player: d.Player{Defense: d.Lineup{Heroes: nil}}})
	defence, ok := body["defence_formation"].([]int64)
	if !ok || defence == nil {
		t.Fatalf("defence_formation is not an array: %#v", body["defence_formation"])
	}
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), `"defence_formation":null`) {
		t.Fatal(string(raw))
	}
	kept := Info(d.InfoView{Player: d.Player{Defense: d.Lineup{Heroes: []int64{10001001}}}})
	if heroes := kept["defence_formation"].([]int64); len(heroes) != 1 || heroes[0] != 10001001 {
		t.Fatalf("defence_formation lost its heroes: %#v", heroes)
	}
}

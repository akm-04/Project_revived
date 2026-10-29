package combatresolver

import (
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

func TestTournamentTransformUsesSourceAwakeningOnBattleCopies(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	snapshot := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 3, 20, 2)}, []combat.Actor{TemplateHero(t, 10001002, 3, 20, 2)})
	snapshot.Battle.CampaignType = 45
	snapshot.Battle.Context = &combat.BattleContext{Transform: "REGION_ARENA_PLAYOFFS_AWAKE_V1"}
	before, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	result, err := Resolve(corpus, snapshot, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	var report struct {
		Fighters map[string]struct {
			Hero struct {
				Level json.Number `json:"lev"`
				Color json.Number `json:"color"`
			} `json:"hero"`
			Summon int64 `json:"summon_type"`
		} `json:"fighter"`
	}
	if err := json.Unmarshal(result.Report, &report); err != nil {
		t.Fatal(err)
	}
	observed := 0
	for _, fighter := range report.Fighters {
		if fighter.Summon != 0 {
			continue
		}
		if fighter.Hero.Level != "100" || fighter.Hero.Color != "16" {
			t.Fatalf("source balancing missing: %+v", fighter)
		}
		observed++
	}
	if observed != 2 {
		t.Fatalf("observed %d normal fighters", observed)
	}
	after, _ := json.Marshal(snapshot)
	if string(before) != string(after) {
		t.Fatal("battle transform mutated canonical frozen input")
	}
}

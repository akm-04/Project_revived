package combatresolver

import (
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

func TestMemoirTransformCarriesAndCapturesServerHealth(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	snapshot := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 3, 20, 2)}, []combat.Actor{TemplateHero(t, 10001002, 3, 20, 2)})
	snapshot.Battle.CampaignType = 53
	parameters, err := combat.CanonicalJSON(map[string]any{"heroes_status": map[string]any{"10001001": map[string]any{"hp": 100.5, "mp": 500, "is_reborn": 0}}})
	if err != nil {
		t.Fatal(err)
	}
	snapshot.Battle.Context = &combat.BattleContext{Transform: "MEMOIR_CARRY_V1", Parameters: parameters}
	resolved, err := Resolve(corpus, snapshot, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	var report struct {
		Fighter map[string]struct {
			Summon  int            `json:"summon_type"`
			Initial map[string]any `json:"health_status"`
			Final   *struct {
				HP     float64 `json:"hp"`
				MP     float64 `json:"mp"`
				Reborn int64   `json:"is_reborn"`
			} `json:"memoir_final_status"`
		} `json:"fighter"`
	}
	if err = json.Unmarshal(resolved.Report, &report); err != nil {
		t.Fatal(err)
	}
	observed := 0
	for _, fighter := range report.Fighter {
		if fighter.Summon != 0 {
			continue
		}
		if fighter.Final == nil || fighter.Final.HP < 0 || fighter.Final.MP < 0 || fighter.Final.MP > 1000 || fighter.Final.Reborn < 0 || fighter.Final.Reborn > 1 {
			t.Fatal("missing or invalid server-owned end state", string(resolved.Report))
		}
		if fighter.Initial["hp"] == 100.5 {
			observed++
		}
	}
	if observed != 1 {
		t.Fatal("source carry not bound", observed, string(resolved.Report))
	}
	plain := snapshot
	plain.Battle.Context = nil
	untouched, err := Resolve(corpus, plain, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	var generic map[string]any
	if err = json.Unmarshal(untouched.Report, &generic); err != nil {
		t.Fatal(err)
	}
	for _, raw := range generic["fighter"].(map[string]any) {
		if _, exists := raw.(map[string]any)["memoir_final_status"]; exists {
			t.Fatal("Memoir report projection leaked into an ordinary battle")
		}
	}
}

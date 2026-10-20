package combatresolver

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	lua "github.com/yuin/gopher-lua"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

// TemplateHero is source-shaped NormalHero.populate_ input for a non-owned actor.
func TemplateHero(t testing.TB, tableID int64, star, level, color int) combat.Actor {
	t.Helper()
	params, err := combat.CanonicalJSON(map[string]any{
		"player_id": 0, "partner_id": tableID, "table_id": tableID, "star": star, "lev": level, "color": color,
		"skin_ids": map[string]any{}, "current_skin_id": 0, "illusion_skin_id": -1, "spirit_equip": []any{}, "spirit_item": []any{},
		"practice_attr": []any{0, 0, 0}, "equips": []any{0, 0, 0, 0, 0, 0}, "fumos": []any{0, 0, 0, 0, 0, 0}, "skills": []any{1, 1, 1, 1, 1, 1},
	})
	if err != nil {
		t.Fatal(err)
	}
	corpus, _ := combatcorpus.Load()
	class, _, _ := corpus.FighterClass("partner", tableID)
	return combat.Actor{Origin: combat.Template, Kind: combat.HeroActor, Identity: tableID, TableID: tableID, FighterClass: class, Params: params}
}

func templateSnapshot(t testing.TB, a, b []combat.Actor) combat.Snapshot {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	return combat.Snapshot{Schema: combat.SnapshotSchema, Contract: combat.ContractID, ContentRevision: strings.Repeat("a", 64), CorpusID: corpus.ID(), SourceArchiveSHA256: corpus.SourceArchiveSHA256(),
		TrustProfile: combat.TrustProfileID, EntropyPolicy: combat.EntropyPolicyVersion, AdapterPolicy: combat.AdapterPolicyVersion, CollectionPolicy: combat.CollectionPolicy,
		DecidedAt: time.Unix(1700000000, 0).UTC(), Battle: combat.Battle{CampaignType: 1, TeamA: a, WavesB: [][]combat.Actor{b}}, Players: []combat.PlayerContext{}}
}

func TestTemplateFightIsDeterministicAndRootSensitive(t *testing.T) {
	corpus, _ := combatcorpus.Load()
	s := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 3, 20, 2), TemplateHero(t, 10001040, 3, 20, 2)}, []combat.Actor{TemplateHero(t, 10001002, 3, 20, 2)})
	root := sha256.Sum256([]byte("resolver-test-root"))
	first, err := Resolve(corpus, s, root)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Resolve(corpus, s, root)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(first.Report, second.Report) || first.Outcome != second.Outcome || first.EntropyDraws != second.EntropyDraws {
		t.Fatal("same snapshot and root diverged")
	}
	var report map[string]any
	if err = json.Unmarshal(first.Report, &report); err != nil || report["fighter"] == nil || report["star"] == nil || report["hero_collect_attr"] == nil {
		t.Fatal("report shape", err)
	}
	if first.Outcome.Frames <= 0 || first.EntropyDraws == 0 {
		t.Fatal("battle did not run", first.Outcome, first.EntropyDraws)
	}
	t.Logf("outcome %+v draws %d reseeds %d report %d bytes %s", first.Outcome, first.EntropyDraws, first.EntropyReseeds, len(first.Report), combat.ReportHash(first.Report))
	other, err := Resolve(corpus, s, sha256.Sum256([]byte("another-root")))
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Equal(other.Report, first.Report) {
		t.Log("different entropy root produced an identical report; fight consumed no outcome-relevant randomness")
	}
}

func TestResolverFailsClosed(t *testing.T) {
	corpus, _ := combatcorpus.Load()
	good := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 1, 1, 1)}, []combat.Actor{TemplateHero(t, 10001002, 1, 1, 1)})
	wrongCorpus := good
	wrongCorpus.CorpusID = strings.Repeat("0", 64)
	if _, err := Resolve(corpus, wrongCorpus, [32]byte{1}); !errors.Is(err, ErrDeterministic) {
		t.Fatal("foreign corpus accepted")
	}
	missingClass := good
	missingClass.Battle.TeamA = []combat.Actor{TemplateHero(t, 11001042, 1, 1, 1)}
	missingClass.Battle.TeamA[0].FighterClass = "Change_Awaken"
	if _, err := Resolve(corpus, missingClass, [32]byte{1}); !errors.Is(err, ErrDeterministic) {
		t.Fatal("absent fighter class resolved")
	}
}

func TestEvaluateActorsReturnsSourceTotals(t *testing.T) {
	corpus, _ := combatcorpus.Load()
	s := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 3, 20, 2)}, []combat.Actor{TemplateHero(t, 10001002, 1, 1, 1)})
	totals, err := EvaluateActors(corpus, s)
	if err != nil {
		t.Fatal(err)
	}
	if len(totals) != 2 || totals[0][1] <= 0 || totals[0][1] <= totals[1][1] {
		t.Fatal("totals", totals)
	}
}

// A03: every present fighter class named by a Partner, Super, Pet, activity or
// monster row loads and constructs through the source requireFighter path in a
// configured CreateReport scene. Fenlier (monster rows 12030201/12030204 only)
// calls the client WindowManager from init and is not server-constructible.
var serverIncompatibleClasses = map[string]bool{"Fenlier": true}

func TestEveryReferencedFighterClassConstructs(t *testing.T) {
	corpus, _ := combatcorpus.Load()
	s := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 1, 1, 1)}, []combat.Actor{TemplateHero(t, 10001002, 1, 1, 1)})
	m, err := newMachine(corpus, s, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	defer m.state.Close()
	classes := m.state.NewTable()
	seen := map[string]bool{}
	present := map[string]bool{}
	for _, name := range corpus.Classes().Present {
		present[name] = true
	}
	for _, rows := range corpus.Classes().ByTable {
		for _, class := range rows {
			if present[class] && !seen[class] {
				seen[class] = true
				classes.Append(lua.LString(class))
			}
		}
	}
	m.state.SetGlobal("sweep_classes", classes)
	if err = m.run(`local scene = require("app.scenes.BattleCreateReport").new({ battleType = xyd.BattleType.CreateReport, campaignType = 1, battleID = 0, herosA = {}, herosB = { {} }, fighterInfo = {} })
scene:setupConfig()
sweep_failures = {}
for _, name in ipairs(sweep_classes) do
	local ok, err = pcall(function() assert(ngx.ctx.battle.requireFighter(name).new({ is_arena = false })) end)
	if not ok then sweep_failures[name] = tostring(err) end
end`, "class sweep"); err != nil {
		t.Fatal(err)
	}
	failed := map[string]bool{}
	m.state.GetGlobal("sweep_failures").(*lua.LTable).ForEach(func(k, v lua.LValue) {
		failed[k.String()] = true
		if !serverIncompatibleClasses[k.String()] {
			t.Errorf("%s: %s", k, v)
		}
	})
	for name := range serverIncompatibleClasses {
		if !failed[name] {
			t.Errorf("%s now constructs; revisit its server-incompatibility record", name)
		}
	}
	t.Logf("constructed %d of %d referenced fighter classes; server-incompatible %v", len(seen)-len(failed), len(seen), failed)
}

// C5C: 1 on 1 rounds run under engine CampaignType.SUPER_ARENA with battle 114001.
func TestSuperArenaRoundResolves(t *testing.T) {
	corpus, _ := combatcorpus.Load()
	s := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 3, 20, 2)}, []combat.Actor{TemplateHero(t, 10001002, 3, 20, 2)})
	s.Battle.CampaignType, s.Battle.BattleID = 65, 114001
	root := sha256.Sum256([]byte("super-arena-root"))
	first, err := Resolve(corpus, s, root)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Resolve(corpus, s, root)
	if err != nil || !bytes.Equal(first.Report, second.Report) {
		t.Fatal("super arena round is not deterministic", err)
	}
	if first.Outcome.Frames <= 0 || first.Outcome.Star < 0 || first.Outcome.Star > 3 {
		t.Fatal("super arena outcome", first.Outcome)
	}
}

func TestRegionArenaBalancesHeroes(t *testing.T) {
	corpus, _ := combatcorpus.Load()
	attacker := TemplateHero(t, 10001001, 3, 20, 2)
	raw, _ := combat.CanonicalJSON(map[string]any{"player_id": 0, "partner_id": 10001001, "table_id": 10001001, "star": 3, "lev": 20, "color": 2,
		"skin_ids": map[string]any{}, "current_skin_id": 0, "illusion_skin_id": -1, "spirit_equip": []any{}, "spirit_item": []any{},
		"practice_attr": []any{0, 0, 0}, "equips": []any{0, 0, 0, 0, 0, 0}, "fumos": []any{0, 0, 0, 0, 0, 0}, "skills": []any{1, 1, 1, 1, 1, 1}, "arena_add_star": 1})
	attacker.Params = raw
	s := templateSnapshot(t, []combat.Actor{attacker}, []combat.Actor{TemplateHero(t, 10001002, 3, 20, 2)})
	s.Battle.CampaignType, s.Battle.BattleID = 45, 111001
	root := sha256.Sum256([]byte("region-arena-root"))
	first, err := Resolve(corpus, s, root)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Resolve(corpus, s, root)
	if err != nil || !bytes.Equal(first.Report, second.Report) {
		t.Fatal("region arena battle is not deterministic", err)
	}
	var report struct {
		Fighter map[string]struct {
			Hero struct {
				Lev  json.Number `json:"lev"`
				Star json.Number `json:"star"`
			} `json:"hero"`
		} `json:"fighter"`
	}
	if err = json.Unmarshal(first.Report, &report); err != nil {
		t.Fatal(err)
	}
	seen := 0
	for key, f := range report.Fighter {
		if strings.HasPrefix(key, "A|") && f.Hero.Lev == "100" && f.Hero.Star == "4" {
			seen++
		}
		if strings.HasPrefix(key, "B|") && f.Hero.Lev == "100" && f.Hero.Star == "3" {
			seen++
		}
	}
	if seen != 2 {
		t.Fatal("balanced level 100 with the season star award", report.Fighter)
	}
}

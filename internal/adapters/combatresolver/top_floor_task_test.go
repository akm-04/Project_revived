package combatresolver

import (
	"bytes"
	"encoding/json"
	"fmt"
	lua "github.com/yuin/gopher-lua"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

func TestTopFloorTaskSourceBuffsAndPhantomProjection(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	for mode := int64(1); mode <= 6; mode++ {
		t.Run(fmt.Sprint(mode), func(t *testing.T) {
			snapshot := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 3, 20, 2)}, []combat.Actor{TemplateHero(t, 10001002, 3, 20, 2)})
			snapshot.Battle.CampaignType = 57
			parameters := map[string]any{"mode": mode, "buffs_a": []int64{}, "buffs_b": []int64{}}
			if mode == 1 {
				parameters["buffs_a"] = []int64{40010688, 40010689, 40010690, 40010707}
				parameters["buffs_b"] = parameters["buffs_a"]
			}
			if mode == 2 {
				parameters["buffs_a"] = []int64{40010691, 40010692, 40010693, 40010708}
				parameters["buffs_b"] = parameters["buffs_a"]
			}
			if mode == 3 {
				parameters["leader_a"] = int64(10001001)
				parameters["leader_b"] = int64(10001002)
				parameters["leader_buff_a"] = int64(40010694)
				parameters["leader_buff_b"] = int64(40010695)
			}
			if mode == 6 {
				parameters["buffs_a"] = []int64{40011644, 40011645}
				parameters["buffs_b"] = parameters["buffs_a"]
			}
			raw, err := combat.CanonicalJSON(parameters)
			if err != nil {
				t.Fatal(err)
			}
			snapshot.Battle.Context = &combat.BattleContext{Transform: "TOP_FLOOR_TASK_V1", Parameters: raw}
			resolved, err := Resolve(corpus, snapshot, [32]byte{1})
			if err != nil {
				t.Fatal(err)
			}
			if resolved.Outcome.ReportError {
				t.Fatal("source engine rejected its report")
			}
			var report struct {
				Fighter map[string]struct {
					Summon int             `json:"summon_type"`
					Buffs  json.RawMessage `json:"init_buff"`
				} `json:"fighter"`
			}
			if err = json.Unmarshal(resolved.Report, &report); err != nil {
				t.Fatal(err)
			}
			ordinary, withBuffs := 0, 0
			buffCounts := map[int64]int{}
			for _, fighter := range report.Fighter {
				if fighter.Summon == 0 {
					ordinary++
					var buffs []int64
					if len(fighter.Buffs) > 0 && !bytes.Equal(fighter.Buffs, []byte("{}")) {
						if err := json.Unmarshal(fighter.Buffs, &buffs); err != nil {
							t.Fatal(err)
						}
					}
					if len(buffs) > 0 {
						withBuffs++
					}
					for _, buff := range buffs {
						buffCounts[buff]++
					}
				}
			}
			expected := 2
			if mode == 5 {
				expected = 10
			}
			if ordinary != expected {
				t.Fatalf("frozen1v1 projected %d ordinary fighters, want%d", ordinary, expected)
			}
			if (mode == 1 || mode == 2 || mode == 3 || mode == 6) && withBuffs != expected {
				t.Fatalf("source buffs missing: %d/%d", withBuffs, expected)
			}
			for _, buff := range parameters["buffs_a"].([]int64) {
				if buffCounts[buff] != expected {
					t.Fatalf("source buff %d observed %d, want%d", buff, buffCounts[buff], expected)
				}
			}
			if mode == 3 && (buffCounts[40010694] != 1 || buffCounts[40010695] != 1) {
				t.Fatal("leader buffs were not bound to their respective frozen fighters")
			}
			if len(snapshot.Battle.TeamA) != 1 || len(snapshot.Battle.WavesB[0]) != 1 {
				t.Fatal("battle clone changed snapshot ownership")
			}
		})
	}
}

func TestTopFloorTaskTimeoutPolicyBranches(t *testing.T) {
	state := lua.NewState()
	defer state.Close()
	if err := state.DoString(transformsLua); err != nil {
		t.Fatal(err)
	}
	const exercise = `
 xyd = {summonMonsterType = {None = 0, Pet = 1}}
 local Report = {}
 package.preload["app.scenes.BattleCreateReport"] = function() return Report end
 local function fighter(harms, dead, reborn, summon)
  return {harms=harms, getSummonType=function() return summon or 0 end,
   isDeath=function() return dead or false end, canReborn=function() return reborn or false end}
 end
 local function decide(mode, teamA, teamB, timeout)
  ngx = {ctx={battle={teamA=teamA,teamB=teamB}}}
  Report.new = function() return {timeOut_=timeout, getBattleStar=function() return 3 end} end
  local hero = {buffs_={}}
  combat_transforms.TOP_FLOOR_TASK_V1({herosA={hero}, herosB={{hero}}},
   {team_a={{params={}}}, waves_b={{{params={}}}}, parameters={mode=mode,buffs_a={},buffs_b={}}})
  return Report.new():getBattleStar()
 end
 assert(decide(1,{fighter(2)},{fighter(1),fighter(1000,false,false,1)},true)==1, "PET_DAMAGE_INCLUDED")
 assert(decide(1,{fighter(1)},{fighter(1)},true)==0, "EXACT_TIE_NOT_DEFENDER")
 assert(decide(2,{fighter(100,true)},{fighter(1)},true)==0, "SURVIVORS_NOT_FIRST")
 assert(decide(2,{fighter(2,true,true)},{fighter(1)},true)==1, "PENDING_REBIRTH_NOT_COUNTED")
 assert(decide(2,{fighter(1)},{fighter(1),fighter(999,false,false,1)},true)==0, "PET_SURVIVAL_INCLUDED")
 assert(decide(1,{fighter(0)},{fighter(100)},false)==3, "NONTIMEOUT_NOT_DELEGATED")
 `
	if err := state.DoString(exercise); err != nil {
		t.Fatal(err)
	}
}

func TestTopFloorTaskLeaderDeathSourceEngine(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	snapshot := templateSnapshot(t,
		[]combat.Actor{TemplateHero(t, 10001001, 3, 20, 2), TemplateHero(t, 10001040, 3, 20, 2)},
		[]combat.Actor{TemplateHero(t, 10001002, 3, 20, 2)})
	snapshot.Battle.CampaignType = 57
	parameters, err := combat.CanonicalJSON(map[string]any{"mode": 3, "buffs_a": []int64{}, "buffs_b": []int64{}, "leader_a": 10001001, "leader_b": 10001002, "leader_buff_a": 40010694, "leader_buff_b": 40010695})
	if err != nil {
		t.Fatal(err)
	}
	snapshot.Battle.Context = &combat.BattleContext{Transform: "TOP_FLOOR_TASK_V1", Parameters: parameters}
	machine, err := newMachine(corpus, snapshot, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	defer machine.state.Close()
	// Controlled death exercises the pinned fighter's actual leader cascade.
	const trigger = `
 local leader
 for _, fighter in ipairs(ngx.ctx.battle.teamA) do
  for _, buff in ipairs(fighter.buffs_) do if buff:isLeadBuff() then leader = fighter end end
 end
 assert(leader, "SOURCE_LEADER_BUFF_MISSING")
 assert(#ngx.ctx.battle.teamA == 2, "SOURCE_FOLLOWER_MISSING")
 leader:die()
 for _, fighter in ipairs(ngx.ctx.battle.teamA) do assert(fighter:isDeath(), "SOURCE_LEADER_CASCADE_FAILED") end
 `
	driver := strings.Replace(driverLua, "battle:run()\n", "battle:run()\n"+trigger, 1)
	if driver == driverLua {
		t.Fatal("test trigger was not installed")
	}
	if err = machine.run(driver, "controlled source leader death"); err != nil {
		t.Fatal(err)
	}
	if err = machine.run(`assert(combat_output.star == 0, "DEAD_LEADER_TEAM_WON")`, "source leader verdict"); err != nil {
		t.Fatal(err)
	}
}

func TestTopFloorTaskNaturalTimeoutSourceEngine(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	snapshot := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 3, 20, 2)}, []combat.Actor{TemplateHero(t, 10001002, 3, 20, 2)})
	snapshot.Battle.CampaignType = 57
	parameters, err := combat.CanonicalJSON(map[string]any{"mode": 1, "buffs_a": []int64{40010688, 40010689, 40010690, 40010707}, "buffs_b": []int64{40010688, 40010689, 40010690, 40010707}})
	if err != nil {
		t.Fatal(err)
	}
	snapshot.Battle.Context = &combat.BattleContext{Transform: "TOP_FLOOR_TASK_V1", Parameters: parameters}
	machine, err := newMachine(corpus, snapshot, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	defer machine.state.Close()
	// A controlled HP fixture lets the original clock reach timeout without replacing its end checks.
	const preserveFighters = `
 for _, team in ipairs({ngx.ctx.battle.teamA,ngx.ctx.battle.teamB}) do
  for _, fighter in ipairs(team) do fighter:resetHpLimit(1000000000000) fighter:setHp(1000000000000) end
 end
 `
	driver := strings.Replace(driverLua, "battle:run()\n", "battle:run()\n"+preserveFighters, 1)
	if driver == driverLua {
		t.Fatal("controlled HP fixture was not installed")
	}
	driver += `assert(combat_output.timed_out, "NATURAL_TIMEOUT_NOT_REACHED")
 local function damage(team) local total=0 for _, fighter in ipairs(team) do if fighter:getSummonType()==xyd.summonMonsterType.None then total=total+fighter.harms end end return total end
 assert(combat_output.star==(damage(ngx.ctx.battle.teamA)>damage(ngx.ctx.battle.teamB) and 1 or 0), "NATURAL_TIMEOUT_DAMAGE_VERDICT")`
	if err = machine.run(driver, "natural timeout with controlled HP fixture"); err != nil {
		t.Fatal(err)
	}
}

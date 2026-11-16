package combat

import (
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// startChoiceConformance names the test that STARTs each registered mode twice
// for the same stage with different choices and asserts its registered rule
// (START_REPLAY_GUARD_V1 ruling 2). A new mode cannot register without a proof.
var startChoiceConformance = map[ModeKey]struct {
	rule ChoiceChangeRule
	test string
}{
	ModeAdventureDefense:    {ChoiceSupersedes, "TestStartChoiceConformanceAdventureDefense"},
	ModeAdventureIllusion:   {ChoiceSupersedes, "TestStartChoiceConformanceAdventureIllusion"},
	ModeAdventurePVP:        {ChoiceReplaysFrozen, "TestClosureE6AdventurePvpOpenStartReplaysFrozenFormationNative"},
	ModeAdventureCoop:       {ChoiceReplaysFrozen, "TestClosureE6AdventureCoopOpenStartReplaysFrozenPicksNative"},
	ModeArena:               {ChoiceReplaysFrozen, "TestI7C5DArenaChangedFormationReplaysOpenFightNative"},
	ModeArenaPlayoffs:       {ChoiceReplaysFrozen, "TestClosureE8ArenaPlayoffsStartChoiceConformance"},
	ModeArenaFriendFight:    {ChoiceReplaysFrozen, "TestClosureE8ArenaFriendFightStartChoiceConformance"},
	ModeAwakeningBlood:      {ChoiceSupersedes, "TestClosureE8AwakeningStartChoiceConformance"},
	ModeCampaign:            {ChoiceSupersedes, "TestI9_3ACampaignNormalAndSuperNative"},
	ModeChampionsLeague:     {ChoiceReplaysFrozen, "TestI7C5FLeagueChangedLineupReplaysOpenFightNative"},
	ModeConquerSchool:       {ChoiceSupersedes, "TestI8_5DConquerStartBindsCombatAttemptNative"},
	ModeDodgeball:           {ChoiceRefusedWhileOpen, "TestI9_6BDodgeballNativeLifecycle"},
	ModeEventCentreBoard:    {ChoiceReplaysFrozen, "TestClosureE8EventCentreBoardStartChoiceConformance"},
	ModeGodsTrial:           {ChoiceSupersedes, "TestStartChoiceConformanceGodsTrial"},
	ModeGuildCampaign:       {ChoiceSupersedes, "TestStartChoiceConformanceGuildCampaign"},
	ModeIllusionSolo:        {ChoiceSupersedes, "TestStartChoiceConformanceIllusionSolo"},
	ModeIllusionTeam:        {ChoiceReplaysFrozen, "TestStartChoiceConformanceIllusionTeam"},
	ModeMarch:               {ChoiceRefusedWhileOpen, "TestStartChoiceConformanceMarch"},
	ModeMemoirBattle:        {ChoiceReplaysFrozen, "TestStartChoiceConformanceMemoirBattle"},
	ModeMemoirPlayer:        {ChoiceReplaysFrozen, "TestClosureE4MemoirPlayerStartReplayIdentityNative"},
	ModeOccultSolo:          {ChoiceSupersedes, "TestStartChoiceConformanceOccultSolo"},
	ModeOccultTeam:          {ChoiceReplaysFrozen, "TestStartChoiceConformanceOccultTeam"},
	ModeOneOnOne:            {ChoiceReplaysFrozen, "TestClosureE4OneOnOneStartReplayIdentityNative"},
	ModePetCampaign:         {ChoiceSupersedes, "TestStartChoiceConformancePetCampaign"},
	ModePetCampaignPractice: {ChoiceSupersedes, "TestStartChoiceConformancePetCampaignPractice"},
	ModeTopFloor:            {ChoiceReplaysFrozen, "TestClosureE2TopFloorReplayIgnoresPetNative"},
	ModeTopFloorTask:        {ChoiceReplaysFrozen, "TestClosureE2TopFloorTaskReplayIgnoresLeaderNative"},
	ModeWorkplace:           {ChoiceReplaysFrozen, "TestI9_5BWorkplaceNativeLifecycle"},
	ModeWorldBoss:           {ChoiceSupersedes, "TestStartChoiceConformanceWorldBoss"},
}

func TestEveryModeHasAStartChoiceProof(t *testing.T) {
	registered := make(map[ModeKey]bool, len(modeRegistrations))
	for _, registration := range modeRegistrations {
		registered[registration.Key] = true
		proof, ok := startChoiceConformance[registration.Key]
		if !ok {
			t.Fatalf("mode %s registers no START choice proof", registration.Key)
		}
		if proof.rule != registration.OnChoiceChange {
			t.Fatalf("mode %s registers rule %q but its proof asserts %q", registration.Key, registration.OnChoiceChange, proof.rule)
		}
		switch proof.rule {
		case ChoiceReplaysFrozen, ChoiceSupersedes, ChoiceRefusedWhileOpen:
		default:
			t.Fatalf("mode %s proves an unknown rule %q", registration.Key, proof.rule)
		}
	}
	for key := range startChoiceConformance {
		if !registered[key] {
			t.Fatalf("conformance table names unregistered mode %s", key)
		}
	}
	tests := testFunctions(t)
	for key, proof := range startChoiceConformance {
		if !tests[proof.test] {
			t.Fatalf("mode %s names missing test %s", key, proof.test)
		}
	}
}

// testFunctions returns every top-level Go test function declared under the
// module's internal tree.
func testFunctions(t *testing.T) map[string]bool {
	t.Helper()
	root := moduleInternalRoot(t)
	found := map[string]bool{}
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if entry.Name() == "testdata" {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(entry.Name(), "_test.go") {
			return nil
		}
		parsed, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
		if err != nil {
			return err
		}
		for _, declaration := range parsed.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Recv != nil || !strings.HasPrefix(function.Name.Name, "Test") {
				continue
			}
			found[function.Name.Name] = true
		}
		return nil
	})
	if err != nil {
		t.Fatalf("scan test sources: %v", err)
	}
	return found
}

func moduleInternalRoot(t *testing.T) string {
	t.Helper()
	root := "."
	for depth := 0; depth < 8; depth++ {
		if _, err := os.Stat(filepath.Join(root, "go.mod")); err == nil {
			return filepath.Join(root, "internal")
		}
		root = filepath.Join(root, "..")
	}
	t.Fatal("go.mod not found above the combat package")
	return ""
}

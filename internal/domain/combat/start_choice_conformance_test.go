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
// reason cites the source that fixes a mode whose choice is not
// player-changeable (START_REPLAY_GUARD_V1 ruling 9a).
var startChoiceConformance = map[ModeKey]struct {
	rule   ChoiceChangeRule
	test   string
	reason string
}{
	ModeAdventureDefense:    {rule: ChoiceSupersedes, test: "TestStartChoiceConformanceAdventureDefense"},
	ModeAdventureIllusion:   {rule: ChoiceSupersedes, test: "TestStartChoiceConformanceAdventureIllusion"},
	ModeAdventurePVP:        {rule: ChoiceReplaysFrozen, test: "TestClosureE6AdventurePvpOpenStartReplaysFrozenFormationNative"},
	ModeAdventureCoop:       {rule: ChoiceReplaysFrozen, test: "TestClosureE6AdventureCoopOpenStartReplaysFrozenPicksNative"},
	ModeArena:               {rule: ChoiceReplaysFrozen, test: "TestI7C5DArenaChangedFormationReplaysOpenFightNative"},
	ModeArenaPlayoffs:       {rule: ChoiceReplaysFrozen, test: "TestStartChoiceConformanceArenaTournament", reason: "the team is the room selection, frozen before START (arena/selection.go:66,83-85; arena/tournament_combat.go:78)"},
	ModeArenaFriendFight:    {rule: ChoiceReplaysFrozen, test: "TestStartChoiceConformanceArenaTournament", reason: "the team is the room selection, frozen before START (arena/selection.go:66,83-85; arena/tournament_combat.go:78)"},
	ModeAwakeningBlood:      {rule: ChoiceSupersedes, test: "TestAwakeningWireRoutesAndTrustBoundary", reason: "MID 866 carries no team; the team is the frozen occurrence owner (awakeningbattle/mode.go:83,98; stockruntime/awakening_blood_dispatcher.go:41-44)"},
	ModeCampaign:            {rule: ChoiceSupersedes, test: "TestStartChoiceConformanceCampaign"},
	ModeChampionsLeague:     {rule: ChoiceReplaysFrozen, test: "TestI7C5FLeagueChangedLineupReplaysOpenFightNative"},
	ModeConquerSchool:       {rule: ChoiceSupersedes, test: "TestI8_5DConquerStartBindsCombatAttemptNative"},
	ModeDodgeball:           {rule: ChoiceRefusedWhileOpen, test: "TestI9_6BDodgeballNativeLifecycle"},
	ModeEventCentreBoard:    {rule: ChoiceReplaysFrozen, test: "TestStartChoiceConformanceEventCentreBoard", reason: "the leader and partners are frozen at receive (eventcentre/board.go:205) and START reads the stored mission (eventcentre/board.go:455-457)"},
	ModeGodsTrial:           {rule: ChoiceSupersedes, test: "TestStartChoiceConformanceGodsTrial"},
	ModeGuildCampaign:       {rule: ChoiceSupersedes, test: "TestStartChoiceConformanceGuildCampaign"},
	ModeIllusionSolo:        {rule: ChoiceSupersedes, test: "TestStartChoiceConformanceIllusionSolo"},
	ModeIllusionTeam:        {rule: ChoiceReplaysFrozen, test: "TestStartChoiceConformanceIllusionTeam"},
	ModeMarch:               {rule: ChoiceRefusedWhileOpen, test: "TestStartChoiceConformanceMarch"},
	ModeMemoirBattle:        {rule: ChoiceReplaysFrozen, test: "TestStartChoiceConformanceMemoirBattle"},
	ModeMemoirPlayer:        {rule: ChoiceReplaysFrozen, test: "TestClosureE4MemoirPlayerStartReplayIdentityNative"},
	ModeOccultSolo:          {rule: ChoiceSupersedes, test: "TestStartChoiceConformanceOccultSolo"},
	ModeOccultTeam:          {rule: ChoiceReplaysFrozen, test: "TestStartChoiceConformanceOccultTeam"},
	ModeOneOnOne:            {rule: ChoiceReplaysFrozen, test: "TestClosureE4OneOnOneStartReplayIdentityNative"},
	ModePetCampaign:         {rule: ChoiceSupersedes, test: "TestStartChoiceConformancePetCampaign"},
	ModePetCampaignPractice: {rule: ChoiceSupersedes, test: "TestStartChoiceConformancePetCampaignPractice"},
	ModeTopFloor:            {rule: ChoiceReplaysFrozen, test: "TestClosureE2TopFloorReplayIgnoresPetNative"},
	ModeTopFloorTask:        {rule: ChoiceReplaysFrozen, test: "TestClosureE2TopFloorTaskReplayIgnoresLeaderNative"},
	ModeWorkplace:           {rule: ChoiceReplaysFrozen, test: "TestStartChoiceConformanceWorkplace"},
	ModeWorldBoss:           {rule: ChoiceSupersedes, test: "TestStartChoiceConformanceWorldBoss"},
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
		path, ok := tests[proof.test]
		if !ok {
			t.Fatalf("mode %s names missing test %s", key, proof.test)
		}
		if forbiddenProofPath(path) {
			t.Fatalf("mode %s names proof %s in %s, where no mode builder lives", key, proof.test, filepath.ToSlash(filepath.Dir(path)))
		}
	}
}

// forbiddenProofPath is START_REPLAY_GUARD_V1 Amendment 2 ruling 7: a proof in
// the shared combat packages drives no mode builder.
func forbiddenProofPath(path string) bool {
	directory := filepath.ToSlash(filepath.Dir(path))
	return strings.HasSuffix(directory, "internal/application/combat") || strings.HasSuffix(directory, "internal/domain/combat")
}

// testFunctions maps every top-level Go test function declared under the
// module's internal tree to its source file.
func testFunctions(t *testing.T) map[string]string {
	t.Helper()
	root := moduleInternalRoot(t)
	found := map[string]string{}
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
			found[function.Name.Name] = path
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

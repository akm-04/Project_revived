package dodgeball

import (
	"gxb.local/backend/v2/internal/domain/combat"
	"testing"
)

func testBoardAndDraws() (Board, combat.DrawPackage) {
	board := Board{Monsters: make([]int64, 25), Marked: []int64{1, 2, 3}, Buffs: []PositionedBuff{{ID: 1}, {ID: 1}, {ID: 1}, {ID: 1}, {ID: 1}, {ID: 1}}}
	for index := range board.Monsters {
		board.Monsters[index] = 1
	}
	draws := combat.DrawPackage{Policy: DrawPolicyID, Version: 1, Streams: map[string][]int64{"self": make([]int64, 650), "friend": make([]int64, 650)}}
	for index := range draws.Streams["self"] {
		draws.Streams["self"][index] = 1
		draws.Streams["friend"][index] = 1000
	}
	return board, draws
}

func TestSuccessfulTargetsUseOccurrenceIdentityAndFrozenDraws(t *testing.T) {
	catalog := testCatalog()
	board, draws := testBoardAndDraws()
	records := []HitRecord{{Throw: 1, Occurrence: 1, Hits: 5}, {Throw: 1, Occurrence: 2, Hits: 5}}
	evaluated, err := catalog.Evaluate(board, 1, records, draws, false)
	if err != nil || len(evaluated.ActorAwards) != 2 || len(evaluated.FriendAwards) != 0 {
		t.Fatal(evaluated, err)
	}
	for _, award := range evaluated.ActorAwards {
		if award.Amount != 2 || award.ItemID != 40001001 {
			t.Fatal(award)
		}
	}
	snapshot := combat.Snapshot{Challenge: &combat.Challenge{Targets: board.Monsters}}
	if verdict, reason := draws.Judge(snapshot, evaluated.Derivation); verdict != combat.VerdictAccepted {
		t.Fatal(verdict, reason)
	}
	draws.Streams["self"][0] = 1000
	evaluated, err = catalog.Evaluate(board, 1, []HitRecord{{Throw: 1, Occurrence: 1, Hits: 1}}, draws, false)
	if err != nil {
		t.Fatal(err)
	}
	if verdict, _ := draws.Judge(snapshot, evaluated.Derivation); verdict != combat.VerdictRejected {
		t.Fatal("unearned success passed frozen draw")
	}
}

func TestFriendGateIsOncePerThrowAndRewardsBothPlayers(t *testing.T) {
	catalog := testCatalog()
	board, draws := testBoardAndDraws()
	draws.Streams["friend"][0] = 1
	evaluated, err := catalog.Evaluate(board, 1, []HitRecord{{Throw: 1, Occurrence: 1, Hits: 5}, {Throw: 1, Occurrence: 2, Hits: 5}}, draws, true)
	if err != nil || len(evaluated.ActorAwards) != 2 || len(evaluated.FriendAwards) != 2 || len(evaluated.Derivation.Claims) != 3 {
		t.Fatal(evaluated, err)
	}
	if verdict, reason := draws.Judge(combat.Snapshot{Challenge: &combat.Challenge{Targets: board.Monsters}}, evaluated.Derivation); verdict != combat.VerdictAccepted {
		t.Fatal(verdict, reason)
	}
}

func TestResultRefusesUnknownTargetsBuffsAndImpossibleHitBudgets(t *testing.T) {
	catalog := testCatalog()
	board, draws := testBoardAndDraws()
	cases := [][]HitRecord{
		{{Throw: 1, Occurrence: 26, Hits: 1}},
		{{Throw: 1, Occurrence: 1, Hits: 1}, {Throw: 2, Occurrence: 1, Hits: 1}},
		{{Throw: 651, Occurrence: 1, Hits: 1}},
		{{Throw: 1, Occurrence: 1, Hits: 1, ProbabilityBuff: true}},
		{{Throw: 1, Occurrence: 1, Hits: 1, FriendProbabilityBuff: true}},
		{{Throw: 1, Occurrence: 1, Hits: 11}},
		{{Throw: 1, Occurrence: 1, Hits: 6}, {Throw: 1, Occurrence: 2, Hits: 5}},
		{{Throw: 201, Occurrence: 1, Hits: 1}},
	}
	for index, records := range cases {
		if _, err := catalog.Evaluate(board, 1, records, draws, false); err == nil {
			t.Fatal("invalid evidence accepted", index)
		}
	}
	if _, err := catalog.Evaluate(board, 999, nil, draws, false); err == nil {
		t.Fatal("unoffered marked target accepted")
	}
	if evaluated, err := catalog.Evaluate(board, 1, nil, draws, false); err != nil || len(evaluated.ActorAwards) != 0 {
		t.Fatal("empty result", evaluated, err)
	}
}

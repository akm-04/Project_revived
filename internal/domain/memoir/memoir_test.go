package memoir

import (
	"crypto/sha256"
	"encoding/json"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

func sourceCatalog(t *testing.T) Catalog {
	t.Helper()
	raw, err := builtin.GeneratedFile("memoir_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog Catalog
	if err = json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	if err = catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	return catalog
}
func TestMemoirSourceJoinsUseCanonicalI8Lineups(t *testing.T) {
	catalog := sourceCatalog(t)
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	for identifier, expected := range catalog.Fights {
		actual, _, err := corpus.BattleLineup(identifier)
		if err != nil || !reflect.DeepEqual(actual, expected) {
			t.Fatalf("fight %d: source/corpus divergence %v", identifier, err)
		}
	}
	if catalog.Girls[0].Scroll != 40001104 || catalog.ReviveCosts[0] != 100 || catalog.ReviveCosts[329] != 1000 {
		t.Fatal("identity/cost joins drifted")
	}
}
func TestMemoirBoardReachabilityAndGuardianEntitlement(t *testing.T) {
	catalog := sourceCatalog(t)
	for seed := 0; seed < 100; seed++ {
		root := sha256.Sum256([]byte{byte(seed)})
		board, err := catalog.NewBoard(catalog.Selected[seed%len(catalog.Selected)], seed%3+1, []int64{7, 8}, combat.NewStream(root))
		if err != nil {
			t.Fatal(seed, err)
		}
		if len(board.Open) != BoardCells {
			t.Fatal("stock fog array would have holes")
		}
		if board.CanExit(FinalPosition) {
			t.Fatal("exit before guardian")
		}
		kinds := map[int64]int{}
		for index, kind := range board.Cells {
			kinds[kind]++
			if kind != Road && !board.CanInteract(index+1) {
				t.Fatal("inaccessible encounter", seed, index+1, kind)
			}
		}
		if kinds[Wall] != 0 || kinds[Guardian] != 1 || kinds[BigBox] != 1 || kinds[Monster] < 3 || kinds[Monster] > 4 || kinds[Player] < 1 || kinds[Player] > 2 || kinds[SmallBox] < 3 || kinds[SmallBox] > 5 {
			t.Fatal(kinds)
		}
		if err = board.ClearEnemy(GuardianPosition); err != nil || !board.CanExit(FinalPosition) || board.Validate() != nil {
			t.Fatal(err)
		}
		if err = board.ClearEnemy(GuardianPosition); err == nil {
			t.Fatal("guardian reward can repeat")
		}
	}
}
func TestMemoirMapRejectsTeleportAndRepeatedBoxes(t *testing.T) {
	catalog := sourceCatalog(t)
	board, err := catalog.NewBoard(catalog.Selected[0], 1, []int64{7}, combat.NewStream([32]byte{1}))
	if err != nil {
		t.Fatal(err)
	}
	before, _ := json.Marshal(board)
	if err = board.SaveMap(FinalPosition, []int{FinalPosition}); err == nil {
		t.Fatal("entered locked endpoint")
	}
	if err = board.SaveMap(InitialPosition, []int{BoardCells + 1}); err == nil {
		t.Fatal("out of bounds visibility accepted")
	}
	after, _ := json.Marshal(board)
	if string(before) != string(after) {
		t.Fatal("rejected movement mutated state")
	}
	for index, kind := range board.Cells {
		if kind != BigBox {
			continue
		}
		result, err := board.OpenBox(index + 1)
		if err != nil || result != 0 {
			t.Fatal(result, err)
		}
		if _, err = board.OpenBox(index + 1); err == nil {
			t.Fatal("box replay admitted")
		}
		if board.walkable(index + 1) {
			t.Fatal("opened box must preserve stock ROAD/FINAL path filter")
		}
	}
	if err = board.SaveMap(1+BoardColumns, []int{1, 2, 1 + BoardColumns}); err != nil {
		t.Fatal(err)
	}
}
func TestMemoirReviveAndAbandonKeepIndependentFacts(t *testing.T) {
	catalog := sourceCatalog(t)
	state := State{Occurrence: "run", Heroes: map[int64]combat.ActorStatus{8: {Identity: 8}}, MaxFloor: map[int64]int{catalog.Selected[0]: 2}, Sequence: 4}
	state.Initialize()
	if cost, err := state.Revive(8, catalog); err != nil || cost != 100 || state.ReviveTimes != 1 || !state.Alive(8) {
		t.Fatal(cost, err)
	}
	if _, err := state.Revive(8, catalog); err == nil {
		t.Fatal("living girl revived twice")
	}
	state.Heroes[8] = combat.ActorStatus{Identity: 8}
	state.ReviveTimes = len(catalog.ReviveCosts)
	if _, err := state.Revive(8, catalog); err == nil {
		t.Fatal("missing ladder price became free")
	}
	state.Abandon()
	if state.Active() || state.Sequence != 4 || state.MaxFloor[catalog.Selected[0]] != 2 || len(state.Heroes) != 0 {
		t.Fatal(state)
	}
}

func TestMemoirBoardRejectsCorruptedGuardian(t *testing.T) {
	catalog := sourceCatalog(t)
	board, err := catalog.NewBoard(catalog.Selected[0], 1, []int64{7}, combat.NewStream([32]byte{1}))
	if err != nil {
		t.Fatal(err)
	}
	board.Cells[GuardianPosition-1] = SmallBox
	if board.Validate() == nil {
		t.Fatal("missing guardian admitted")
	}
}

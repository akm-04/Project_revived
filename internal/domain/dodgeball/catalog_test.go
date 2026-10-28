package dodgeball

import (
	"reflect"
	"testing"
)

type zeroRandom struct{}

func (zeroRandom) Uniform(bound uint64) uint64 {
	if bound == 0 {
		panic("empty random range")
	}
	return 0
}

func testCatalog() Catalog {
	catalog := Catalog{Activities: []Activity{{ID: 1210, Kind: 1, Parameter: "0.02", Count: 2}, {ID: 1211, Kind: 2, Parameter: "5", Count: 2}}, Schema: 1, Contract: ContractID, TicketItem: 50001979, InitialBalls: 200, MinimumBuffs: 6, MaximumBuffs: 9, FriendProbability: 100, FriendBalls: 5, IncomingLimit: 3, MarkedMultiplier: 2,
		Groups: []Group{{ID: 1, Minimum: 10, Maximum: 12, Weight: 100}, {ID: 2, Minimum: 12, Maximum: 18, Weight: 50}, {ID: 3, Minimum: 2, Maximum: 6, Weight: 30}, {ID: 4, Minimum: 1, Maximum: 3, Weight: 10}, {ID: 5, Minimum: 2, Maximum: 3, Weight: 100, Activity: 1211}},
		Buffs:  []Buff{{ID: 1, Weight: 75, Effect: 50}, {ID: 2, Weight: 80, Effect: 20}, {ID: 3, Weight: 70, Effect: 100}, {ID: 4, Weight: 35, Effect: 50}, {ID: 5, Weight: 45}, {ID: 6, Weight: 45, Effect: 10}}}
	for identifier := int64(1); identifier <= 89; identifier++ {
		catalog.Targets = append(catalog.Targets, Target{ID: identifier, Group: 1 + (identifier-1)%4, HeroTableID: 10001000 + identifier, ItemID: 40001000 + identifier, Amount: 1, Weight: 10, Probability: 200})
	}
	catalog.Targets = append(catalog.Targets, Target{ID: 90, Group: 5, ItemID: 50001308, Amount: 1, Weight: 100, Probability: 1000})
	return catalog
}

func TestBoardPolicyDeterministicAndNoImplicitSeason(t *testing.T) {
	catalog := testCatalog()
	first, err := catalog.BuildBoard(zeroRandom{})
	if err != nil {
		t.Fatal(err)
	}
	second, err := catalog.BuildBoard(zeroRandom{})
	if err != nil || !reflect.DeepEqual(first, second) {
		t.Fatal("board replay drift", err)
	}
	if len(first.Monsters) != 25 || len(first.Marked) != 3 || len(first.Buffs) != 6 {
		t.Fatal(first)
	}
	counts := map[int64]int{}
	present := map[int64]bool{}
	for _, identifier := range first.Monsters {
		target, found := catalog.Target(identifier)
		if !found || target.Group == 5 {
			t.Fatal("seasonal target activated", identifier)
		}
		counts[target.Group]++
		present[identifier] = true
	}
	if !reflect.DeepEqual(counts, map[int64]int{1: 10, 2: 12, 3: 2, 4: 1}) {
		t.Fatal(counts)
	}
	marked := map[int64]bool{}
	for _, identifier := range first.Marked {
		if !present[identifier] || marked[identifier] {
			t.Fatal("marked identity", identifier)
		}
		marked[identifier] = true
	}
	for _, buff := range first.Buffs {
		if buff.Position < 1 || buff.Position > 26 {
			t.Fatal(buff)
		}
	}
	policy := catalog.DrawPolicy()
	if !policy.Valid() || policy.Streams[0].Length != 650 || policy.Streams[1].Length != 650 {
		t.Fatal(policy)
	}
}

func TestBoardRejectsInvalidCatalogBeforeDrawing(t *testing.T) {
	catalog := testCatalog()
	catalog.Targets[0].Probability = 1001
	if _, err := catalog.BuildBoard(zeroRandom{}); err == nil {
		t.Fatal("invalid probability accepted")
	}
	catalog = testCatalog()
	catalog.Targets[1].ID = catalog.Targets[0].ID
	if catalog.Validate() == nil {
		t.Fatal("duplicate table identity accepted")
	}
	catalog = testCatalog()
	catalog.Buffs[1].Effect = 200
	if catalog.Validate() == nil {
		t.Fatal("probability scale drift accepted")
	}
}

package characterhero

import (
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
)

func TestHeroSkillLevelCostAndChangeNormalization(t *testing.T) {
	hero := character.Hero{RawSkills: character.NewHeroRawSkillSeed()}
	var skillIDs [6]int64
	for index := range skillIDs {
		skillIDs[index] = int64(index + 1)
	}

	manaCost, pointCost, valid := heroSkillLevelCost(hero, character.NormalHero, skillIDs, []HeroSkillLevelChange{{Slot: 1, Count: 1}}, 21, 10000)
	if !valid || manaCost != 100 || pointCost != 1 {
		t.Fatal(manaCost, pointCost, valid)
	}

	manaCost, pointCost, valid = heroSkillLevelCost(hero, character.SuperHero, skillIDs, []HeroSkillLevelChange{{Slot: 3, Count: 1}}, 22, 5000)
	if !valid || manaCost != 50000 || pointCost != 1 {
		t.Fatal(manaCost, pointCost, valid)
	}

	_, _, valid = heroSkillLevelCost(hero, character.NormalHero, skillIDs, []HeroSkillLevelChange{{Slot: 3, Count: 1}}, 21, 10000)
	if valid {
		t.Fatal("skill above the bookshelf cap accepted")
	}

	changes, err := normalizeHeroSkillLevelChanges([]HeroSkillLevelChange{{Slot: 4, Count: 2}, {Slot: 1, Count: 1}})
	if err != nil || !reflect.DeepEqual(changes, []HeroSkillLevelChange{{Slot: 1, Count: 1}, {Slot: 4, Count: 2}}) {
		t.Fatal(changes, err)
	}

	for _, invalid := range [][]HeroSkillLevelChange{
		{{Slot: 1, Count: 1}, {Slot: 1, Count: 2}},
		{{Slot: 0, Count: 1}},
		{{Slot: 1, Count: 0}},
		{},
	} {
		if _, err := normalizeHeroSkillLevelChanges(invalid); err == nil {
			t.Fatal("invalid changes accepted", invalid)
		}
	}
}

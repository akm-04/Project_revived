package march

import (
	"testing"

	"gxb.local/backend/v2/internal/application/publicstats"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/statrules"
)

// sourceRequiredByColor is the highest ordinary-equipment required level of
// each colour for Hero 10001001, compiled from src_64 partner.lua and item.lua
// into hero_equipment_catalog.json and equipment_primitives_catalog.json.
func sourceRequiredByColor() map[int64]int64 {
	return map[int64]int64{
		1: 2, 2: 10, 3: 22, 4: 34, 5: 43, 6: 51, 7: 59, 8: 72,
		9: 79, 10: 80, 11: 85, 12: 88, 13: 90, 14: 90, 15: 93, 16: 97,
	}
}

func scaledTestHero(level, star, color int64, levels d.HeroColorLevels) scaledHero {
	return scaledHero{
		row: map[string]any{},
		evaluate: func(level, star, color int64) (publicstats.Result, error) {
			return publicstats.Result{Stats: statrules.Result{Force: float64(level*star) * (1 + float64(color)/10)}}, nil
		},
		levels: levels, levelsKnown: true, level: level, star: star, color: color,
	}
}

// TestScaleEnemyClampsImpossibleGrade scales a level-100 red+1 owner team to a
// stage-1-sized target. The fitted level must not keep the owner's grade: the
// final triple has to satisfy the source equipment level rule and stay within
// the stage limit.
func TestScaleEnemyClampsImpossibleGrade(t *testing.T) {
	levels, err := d.HeroColorLevelsFromColorRequiredLevels(sourceRequiredByColor())
	if err != nil {
		t.Fatal(err)
	}
	heroes := []scaledHero{scaledTestHero(100, 3, 16, levels)}
	policy := d.Policy{RivalForceTolerance: 500, RivalScaleMinLevel: 1, RivalScaleMinColor: 1, RivalScaleMinStar: 1}
	// The evaluator's force is 100*3*(1+16/10)=780 before scaling.
	limit := 35 * 3 * (1 + 16.0/10)
	if err = (Mode{}).fitCoherentTeam(heroes, policy, limit); err != nil {
		t.Fatal(err)
	}
	hero := heroes[0]
	if hero.level != 35 {
		t.Fatalf("fitted level=%d want 35", hero.level)
	}
	highest, err := d.CoherentColor(levels, hero.level, 16, policy.RivalScaleMinColor)
	if err != nil {
		t.Fatal(err)
	}
	if hero.color != highest {
		t.Fatalf("colour=%d at level %d, want the highest legal colour %d", hero.color, hero.level, highest)
	}
	if hero.color != 5 {
		t.Fatalf("colour=%d want 5 for level 35", hero.color)
	}
	if hero.star != 3 {
		t.Fatalf("star=%d want the owner star 3; no source table caps star by colour or level", hero.star)
	}
	force := float64(hero.level*hero.star) * (1 + float64(hero.color)/10)
	if force > limit {
		t.Fatalf("force %.1f exceeds stage limit %.1f", force, limit)
	}
}

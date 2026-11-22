package march

import "testing"

// requiredByColor is the highest ordinary-equipment required level of each
// colour for Hero 10001001, compiled into
// internal/content/builtin/generated/hero_equipment_catalog.json and
// equipment_primitives_catalog.json.
func sourceRequiredByColor() map[int64]int64 {
	return map[int64]int64{
		1: 2, 2: 10, 3: 22, 4: 34, 5: 43, 6: 51, 7: 59, 8: 72,
		9: 79, 10: 80, 11: 85, 12: 88, 13: 90, 14: 90, 15: 93, 16: 97,
	}
}

func TestCoherentColorClampsGradeToFittedLevel(t *testing.T) {
	levels, err := HeroColorLevelsFromColorRequiredLevels(sourceRequiredByColor())
	if err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		name  string
		level int64
		color int64
		floor int64
		want  int64
	}{
		{"red+1 cannot hold at level 35", 35, 16, 1, 5},
		{"red+1 holds at level 93", 93, 16, 1, 16},
		{"red+1 holds at level 100", 100, 16, 1, 16},
		{"level 1 floor", 1, 16, 1, 1},
		{"policy floor wins", 1, 16, 7, 7},
		{"never raises", 100, 5, 1, 5},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := CoherentColor(levels, tc.level, tc.color, tc.floor)
			if err != nil {
				t.Fatal(err)
			}
			if got != tc.want {
				t.Fatalf("CoherentColor(level=%d,color=%d,floor=%d)=%d want %d", tc.level, tc.color, tc.floor, got, tc.want)
			}
		})
	}
}

func TestCoherentColorRejectsInvalidInput(t *testing.T) {
	levels, err := HeroColorLevelsFromColorRequiredLevels(sourceRequiredByColor())
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct{ level, color, floor int64 }{
		{0, 16, 1}, {101, 16, 1}, {35, 0, 1}, {35, 17, 1}, {35, 5, 6}, {35, 5, 0},
	} {
		if _, err := CoherentColor(levels, tc.level, tc.color, tc.floor); err == nil {
			t.Fatalf("CoherentColor(%d,%d,%d) accepted invalid input", tc.level, tc.color, tc.floor)
		}
	}
}

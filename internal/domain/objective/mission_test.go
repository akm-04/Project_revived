package objective

import (
	"testing"
	"time"
)

func TestMissionGenerationUsesResetAndHeroIdentity(t *testing.T) {
	at := time.Date(2026, 10, 25, 20, 59, 59, 0, time.UTC)
	daily := MissionDefinition{GenerationKind: "DAY"}
	before, err := daily.MissionGeneration(at, 0)
	if err != nil {
		t.Fatal(err)
	}
	after, err := daily.MissionGeneration(at.Add(time.Second), 0)
	if err != nil || before == after {
		t.Fatalf("05:00 reset identity %q -> %q: %v", before, after, err)
	}
	partner := MissionDefinition{GenerationKind: "HERO"}
	if _, err := partner.MissionGeneration(at, 0); err == nil {
		t.Fatal("partner mission accepted an absent hero identity")
	}
	first, _ := partner.MissionGeneration(at, 10)
	second, _ := partner.MissionGeneration(at, 11)
	if first == second {
		t.Fatal("different hero templates share a mission occurrence")
	}
}

func TestMissionMealsUseTheirOwnSourceWindows(t *testing.T) {
	cases := []struct {
		kind       int64
		parameters []int64
		hour       int
		minute     int
		want       bool
	}{
		{111, []int64{43200, 50400}, 12, 0, false},
		{111, []int64{43200, 50400}, 12, 1, true},
		{111, []int64{43200, 50400}, 14, 0, false},
		{118, []int64{43200}, 11, 59, false},
		{118, []int64{43200}, 12, 0, true},
		{118, []int64{43200}, 4, 59, true},
		{118, []int64{43200}, 5, 0, false},
	}
	zone := time.FixedZone("GMT+8", 8*3600)
	for _, c := range cases {
		mission := MissionDefinition{Presentation: MissionPresentation{Condition: c.kind, Parameters: c.parameters}}
		at := time.Date(2026, 10, 26, c.hour, c.minute, 0, 0, zone)
		got, err := mission.MealClaimable(at)
		if err != nil || got != c.want {
			t.Errorf("kind %d at %s = %v, %v; want %v", c.kind, at, got, err, c.want)
		}
	}
}

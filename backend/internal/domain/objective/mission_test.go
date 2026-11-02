package objective

import (
	"gxb.local/backend/v2/internal/domain/grant"
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

func TestMissionRewardSelectsOneLevelAlternativeAndPinnedVIPQuantity(t *testing.T) {
	m := MissionDefinition{Presentation: MissionPresentation{DetailType: 6}, Reward: grant.Plan{Lines: []grant.Line{
		{Kind: grant.PlayerExp, Amount: 200}, {Kind: grant.ScalarCurrency, ResourceKey: "march_coin", Amount: 20}, {Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 50},
	}}}
	for _, tc := range []struct {
		level int64
		kind  grant.LineKind
		key   string
	}{{79, grant.PlayerExp, ""}, {80, grant.ScalarCurrency, "march_coin"}} {
		plan, err := m.RewardFor(tc.level, 80, 0)
		if err != nil || len(plan.Lines) != 2 || plan.Lines[0].Kind != tc.kind || plan.Lines[0].ResourceKey != tc.key {
			t.Fatalf("level %d: %+v %v", tc.level, plan, err)
		}
	}
	if len(m.Reward.Lines) != 3 {
		t.Fatal("reward projection mutated pinned definition")
	}
	m.Presentation = MissionPresentation{VIPSweepReward: true, VIPSweepItemID: 50001013, VIPSweepByLevel: []int64{0, 3, 5}}
	m.Reward.Lines = nil
	for vip, want := range []int64{0, 3, 5} {
		plan, err := m.RewardFor(1, 80, int64(vip))
		if err != nil {
			t.Fatal(err)
		}
		if want == 0 {
			if len(plan.Lines) != 0 {
				t.Fatal("invented VIP0 reward")
			}
		} else if len(plan.Lines) != 1 || plan.Lines[0].Amount != want || plan.Lines[0].ItemID != 50001013 {
			t.Fatalf("VIP %d: %+v", vip, plan)
		}
	}
	if _, err := m.RewardFor(1, 80, 3); err == nil {
		t.Fatal("unbound VIP level accepted")
	}
	if _, err := m.RewardFor(81, 80, 0); err == nil {
		t.Fatal("invalid progression accepted")
	}
}

func TestInscriptionForIsStableWeightedAndEmptyWithoutPool(t *testing.T) {
	definition := MissionDefinition{ObjectiveID: 10031, Presentation: MissionPresentation{InscriptionPool: []InscriptionChoice{{ItemID: 160400101, Weight: 8}, {ItemID: 160400102, Weight: 8}, {ItemID: 160400201, Weight: 0}}}}
	seen := map[int64]bool{}
	for player := int64(1); player <= 64; player++ {
		item := definition.InscriptionFor(player, "day:2026-10-26")
		if item != definition.InscriptionFor(player, "day:2026-10-26") {
			t.Fatal("pick is not stable")
		}
		seen[item] = true
	}
	if len(seen) != 2 || !seen[160400101] || !seen[160400102] {
		t.Fatalf("picks = %v", seen)
	}
	if item := (MissionDefinition{ObjectiveID: 10002}).InscriptionFor(1, "day:2026-10-26"); item != 0 {
		t.Fatalf("no pool pick = %d", item)
	}
}

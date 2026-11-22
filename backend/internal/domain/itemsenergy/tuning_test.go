package itemsenergy

import (
	"errors"
	"testing"
)

func tuneTestCatalog() Catalog {
	catalog := testCatalog()
	catalog.VIP = map[int64]VIPRow{}
	for level := int64(0); level < 16; level++ {
		catalog.VIP[level] = VIPRow{Level: level, NumEnergy: 1, NumMidas: 1}
	}
	catalog.DailyConsume = map[int64]DailyConsume{}
	for id := int64(1); id <= 10; id++ {
		catalog.DailyConsume[id] = DailyConsume{ID: id, Cost: 50, Num: 1, Value: 1}
	}
	catalog.Items[SkillPointItemID] = Item{ID: SkillPointItemID, Type: 4, SubType: 19, Stack: 99, SkillPoint: 10}
	row := catalog.RefreshCost[1]
	row.BuySkillCost = 30
	catalog.RefreshCost[1] = row
	return catalog
}

func TestTuneAppliesValidatedOverlay(t *testing.T) {
	catalog := tuneTestCatalog()
	tuned, err := catalog.Tune(Tuning{EnergyMaxLimit: 600, MidasBase: 30000,
		MidasCritTypes: []int64{5}, MidasCritRates: []int64{1}, BuyEnergyCost: []int64{80}})
	if err != nil {
		t.Fatal(err)
	}
	if tuned.Misc.EnergyMaxLimit != 600 || tuned.Misc.MidasBase != 30000 ||
		len(tuned.Misc.MidasCritTypes) != 1 || tuned.RefreshCost[1].BuyEnergyCost != 80 {
		t.Fatalf("tuned catalog %+v", tuned.Misc)
	}
	if catalog.Misc.EnergyMaxLimit != 500 || catalog.RefreshCost[1].BuyEnergyCost != 50 {
		t.Fatal("tune mutated the source catalog")
	}
}

func TestTuneRejectsInvalidOverlay(t *testing.T) {
	catalog := tuneTestCatalog()
	for name, tuning := range map[string]Tuning{
		"crit mismatch":  {MidasCritTypes: []int64{2}, MidasCritRates: []int64{1, 1}},
		"zero rates":     {MidasCritTypes: []int64{2}, MidasCritRates: []int64{0}},
		"cost ladder":    {BuyManaCost: []int64{1, 2}},
		"negative cost":  {BuyManaCost: []int64{-1}},
		"float order":    {MidasFloatUpBasisPoints: 10, MidasFloatDownBasisPoints: 20},
		"skill ladder":   {BuySkillCost: []int64{1, 2}},
		"skill negative": {BuySkillCost: []int64{-1}},
		"vip gate value": {VipSkillBuy: map[string]int64{"2": 2}},
		"vip gate level": {VipSkillBuy: map[string]int64{"x": 1}},
		"item negative":  {SkillPointItemAmount: -1},
		"negative cap":   {EnergyMaxLimit: -1},
		"negative grant": {BuyEnergyNum: -1},
		"mixed invalid":  {EnergyMaxLimit: -1, BuyEnergyNum: 240},
	} {
		if _, err := catalog.Tune(tuning); !errors.Is(err, errTuning) {
			t.Fatalf("%s: %v", name, err)
		}
	}
}

// A down-only overlay is valid when the source up bound still covers it; the
// bounds are compared after the source fallback is applied, not as raw overlay
// fields.
func TestTuneDownOnlyOverlayKeepsSourceUpBound(t *testing.T) {
	catalog := tuneTestCatalog()
	tuned, err := catalog.Tune(Tuning{BuyEnergyNum: 240, MidasFloatDownBasisPoints: 100})
	if err != nil {
		t.Fatalf("down-only overlay rejected: %v", err)
	}
	if tuned.Misc.BuyEnergyNum != 240 || tuned.Misc.MidasFloatDownBasisPoints != 100 ||
		tuned.Misc.MidasFloatUpBasisPoints != catalog.Misc.MidasFloatUpBasisPoints {
		t.Fatalf("down-only overlay %+v", tuned.Misc)
	}
}

func TestTuneInvalidOverlayFallsBackAsAUnit(t *testing.T) {
	catalog := tuneTestCatalog()
	tuned, err := catalog.Tune(Tuning{EnergyMaxLimit: -1, BuyEnergyNum: 240})
	if !errors.Is(err, errTuning) {
		t.Fatalf("mixed overlay: %v", err)
	}
	if tuned.Misc.BuyEnergyNum != catalog.Misc.BuyEnergyNum || tuned.Misc.EnergyMaxLimit != catalog.Misc.EnergyMaxLimit {
		t.Fatalf("invalid overlay kept a valid field: %+v", tuned.Misc)
	}
}

func TestTuneAppliesSkillTunables(t *testing.T) {
	catalog := tuneTestCatalog()
	tuned, err := catalog.Tune(Tuning{
		BuySkillCost:         []int64{123},
		VipSkillBuy:          map[string]int64{"2": 1},
		SkillPointItemAmount: 25,
	})
	if err != nil {
		t.Fatal(err)
	}
	if tuned.RefreshCost[1].BuySkillCost != 123 || tuned.VIP[2].SkillBuy != 1 ||
		tuned.Items[SkillPointItemID].SkillPoint != 25 {
		t.Fatalf("tuned skill values %+v %+v %+v", tuned.RefreshCost[1], tuned.VIP[2], tuned.Items[SkillPointItemID])
	}
	if catalog.RefreshCost[1].BuySkillCost != 30 || catalog.VIP[2].SkillBuy != 0 ||
		catalog.Items[SkillPointItemID].SkillPoint != 10 {
		t.Fatal("tune mutated the source catalog")
	}
}

func TestTuneAbsentSkillTunablesKeepSource(t *testing.T) {
	catalog := tuneTestCatalog()
	tuned, err := catalog.Tune(Tuning{})
	if err != nil {
		t.Fatal(err)
	}
	if tuned.RefreshCost[1].BuySkillCost != 30 || tuned.VIP[2].SkillBuy != 0 ||
		tuned.Items[SkillPointItemID].SkillPoint != 10 {
		t.Fatalf("absent overlay changed source values %+v", tuned)
	}
}

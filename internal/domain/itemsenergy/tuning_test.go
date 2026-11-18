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
		"crit mismatch": {MidasCritTypes: []int64{2}, MidasCritRates: []int64{1, 1}},
		"zero rates":    {MidasCritTypes: []int64{2}, MidasCritRates: []int64{0}},
		"cost ladder":   {BuyManaCost: []int64{1, 2}},
		"negative cost": {BuyManaCost: []int64{-1}},
		"float order":   {MidasFloatUpBasisPoints: 10, MidasFloatDownBasisPoints: 20},
	} {
		if _, err := catalog.Tune(tuning); !errors.Is(err, errTuning) {
			t.Fatalf("%s: %v", name, err)
		}
	}
}

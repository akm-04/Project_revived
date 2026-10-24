package publicprofile

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/application/characterasset"
	"testing"
)

func TestSelectionReceiptAndEdgeGrammar(t *testing.T) {
	for _, raw := range []string{`[1,0,-1,0,0,2]`, `[1e0,0,-1.0,0,0,2]`} {
		var s Selection
		if e := json.Unmarshal([]byte(raw), &s); e != nil || s != (Selection{1, 0, -1, 0, 0, 2}) {
			t.Fatal(e, s)
		}
	}
	for _, raw := range []string{`null`, `{}`, `[1]`, `[1,0,0,0,0,0,0]`, `[1,null,0,0,0,0]`, `[1.5,0,0,0,0,0]`, `[9007199254740992,0,0,0,0,0]`, `[-9007199254740992,0,0,0,0,0]`, `["1",0,0,0,0,0]`, `[1e-400,0,0,0,0,0]`} {
		var s Selection
		if json.Unmarshal([]byte(raw), &s) == nil {
			t.Fatal("invalid receipt accepted", raw)
		}
	}
}
func TestFacetCloneProtectsSlices(t *testing.T) {
	f := characterasset.PublicHeroCharacterFacet{Equipment: characterasset.ProviderObservation[characterasset.RawEquipmentState]{Value: characterasset.RawEquipmentState{Slots: []characterasset.RawEquipmentSlot{{Slot: 1}}}}, Practice: characterasset.ProviderObservation[characterasset.PracticeContribution]{Value: characterasset.PracticeContribution{Contributions: []characterasset.PracticeContributionEntry{{Value: 5}}}}}
	copy, e := cloneFacet(f)
	if e != nil {
		t.Fatal(e)
	}
	copy.Equipment.Value.Slots[0].Slot = 9
	copy.Practice.Value.Contributions[0].Value = 99
	if f.Equipment.Value.Slots[0].Slot != 1 || f.Practice.Value.Contributions[0].Value != 5 {
		t.Fatal("aliased facet")
	}
}

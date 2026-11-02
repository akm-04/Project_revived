package summon

import "testing"

func TestSXPityForcesTheHotspotAndRestartsOnChange(t *testing.T) {
	c := load(t)
	hotspot, other := c.Policy.Cohorts.SX[0], c.Policy.Cohorts.SX[1]
	slots, s := c.DrawSX(State{SXTarget: hotspot, SXPity: c.Policy.SX.HotspotPity - 1}, hotspot, &fixed{})
	if len(slots) != 6 || slots[5].ItemID != hotspot || slots[5].Kind != HeroKind || s.SXPity != 0 {
		t.Fatal("25th purchase is the hotspot", slots, s)
	}
	for _, slot := range slots[:5] {
		if slot.Kind != ItemKind {
			t.Fatal("static slots are items", slots)
		}
	}
	slots, s = c.DrawSX(State{SXTarget: other, SXPity: c.Policy.SX.HotspotPity - 1}, hotspot, &fixed{})
	if slots[5].Kind != HeroKind || slots[5].ItemID == hotspot || s.SXTarget != hotspot || s.SXPity != 1 {
		t.Fatal("a new hotspot restarts the pity; the last class is an ordinary hero", slots, s)
	}
}

func TestSXDynamicClasses(t *testing.T) {
	c := load(t)
	hotspot := c.Policy.Cohorts.SX[2]
	slots, s := c.DrawSX(State{SXTarget: hotspot, SXPity: 3}, hotspot, &fixed{values: []uint64{0, 0, 0, 0, 0, 0, 0}})
	if slots[5].ItemID != hotspot || s.SXPity != 0 {
		t.Fatal("full SX class inside the hotspot share", slots, s)
	}
	slots, s = c.DrawSX(State{SXTarget: hotspot, SXPity: 3}, hotspot, &fixed{values: []uint64{0, 0, 0, 0, 0, 500, 0, 0}})
	first := c.caskets(2)[0]
	if slots[5].Kind != ItemKind || slots[5].ItemID != c.heroes[first.PartnerID].StoneItemID || slots[5].ItemNum != first.RollNums[0] || s.SXPity != 4 {
		t.Fatal("three-star fragment class", slots, s, first)
	}
}

func TestMagicDraws(t *testing.T) {
	c := load(t)
	slots, fragments := c.DrawMagic(button(t, c, 33, 1), &fixed{})
	if len(slots) != 1 || fragments != 5 || slots[0].Kind != ItemKind {
		t.Fatal("single magic", slots, fragments)
	}
	slots, fragments = c.DrawMagic(button(t, c, 33, 2), &fixed{})
	if len(slots) != 10 || fragments != 50 {
		t.Fatal("ten magic uses magic_drop_rate", slots, fragments)
	}
	if stone, ok := c.MagicFragment(11001); !ok || stone <= 0 {
		t.Fatal("Vows target", stone)
	}
	if scroll, ok := c.VowsScroll(11014); !ok || scroll <= 0 {
		t.Fatal("Vows scroll", scroll)
	}
	if _, ok := c.VowsScroll(10001001); ok {
		t.Fatal("a normal girl has no Vows scroll")
	}
	if _, ok := c.MagicFragment(c.Policy.Cohorts.SX[0]); ok {
		t.Fatal("SX girls are not Magic targets")
	}
}

func TestSXOperatorTuning(t *testing.T) {
	c := load(t)
	if _, err := c.Tune(Tuning{Version: 1, SXClassWeights: map[string]int64{"sx_full_hero": 1}}); err == nil {
		t.Fatal("partial class weights must be rejected")
	}
	tuned, err := c.Tune(Tuning{Version: 1, SXHotspotPity: 2, SXClassWeights: map[string]int64{"sx_full_hero": 0, "normal_three_star_fragments": 0, "normal_two_star_fragments": 1, "ordinary_full_hero": 0}})
	if err != nil {
		t.Fatal(err)
	}
	hotspot := c.Policy.Cohorts.SX[0]
	slots, s := tuned.DrawSX(State{}, hotspot, &fixed{})
	if slots[5].Kind != ItemKind || s.SXPity != 1 {
		t.Fatal("tuned class weights", slots, s)
	}
	if slots, _ = tuned.DrawSX(s, hotspot, &fixed{}); slots[5].ItemID != hotspot {
		t.Fatal("tuned pity 2", slots)
	}
}

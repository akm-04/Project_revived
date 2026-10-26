package march

import (
	"strings"
	"testing"
)

type fixedRandom uint64

func (r fixedRandom) Uniform(n uint64) uint64 { return uint64(r) % n }
func testCatalog() Catalog {
	c := Catalog{Schema: 1, Contract: ContractID, PolicyID: PolicyID, PolicySHA: strings.Repeat("a", 64), Policy: Policy{SuperChance: 100, ManaPerLevel: 1000, MarchCoin: 20, Reagents: 1, ResultWindow: 600, CandidateLimit: 200}, Pools: map[string][][3]int64{}, Misc: map[string]string{}, Milestones: []int64{600, 780, 960, 1140}}
	for key, n := range map[string]int{"130001": 1, "130002": 1, "130003": 1, "130004": 1, "200012": 226, "200013": 64, "200015": 165, "200016": 40} {
		rows := make([][3]int64, n)
		for i := range rows {
			rows[i] = [3]int64{int64(i + 1), 1, 0}
		}
		rows[0][2] = 10000
		c.Pools[key] = rows
	}
	for i := int64(65); i <= 100; i++ {
		c.Advances = append(c.Advances, Advance{Level: i, Rates: []int64{100, 200, 300, 400}, Counts: [][]int64{{1}, {4}, {7}, {10}, {12}}})
	}
	for i := 0; i < 6; i++ {
		c.Recommendations = append(c.Recommendations, []int64{1})
	}
	for _, key := range []string{"expedition_rival_param", "expedition_mana_param", "expedition_init_mana"} {
		c.Misc[key] = strings.TrimSuffix(strings.Repeat("1|", 15), "|")
	}
	return c
}
func TestCatalogSourceBoundsAndPrivatePoolBranches(t *testing.T) {
	c := testCatalog()
	if c.Validate() != nil {
		t.Fatal("valid catalog")
	}
	c.Pools["200012"][0][0] = 12
	c.Pools["200013"][0][0] = 13
	c.Pools["130001"][0][0] = 60
	if c.Draw(false, 1, fixedRandom(9999))[0][0] != 12 || c.Draw(false, 1, fixedRandom(0))[0][0] != 13 || c.Draw(false, 600, fixedRandom(0))[0][0] != 60 {
		t.Fatal("ordinary/super/milestone routing")
	}
	if len(c.Draw(true, 0, fixedRandom(0))) != 3 {
		t.Fatal("Mystic draws")
	}
	for force, want := range map[int64]int64{0: 1, 100: 4, 200: 7, 300: 10, 400: 12} {
		n, err := c.SweepCount(65, force, fixedRandom(0))
		if err != nil || n != want {
			t.Fatal(force, n, err)
		}
	}
	if _, err := c.SweepCount(64, 400, fixedRandom(0)); err == nil {
		t.Fatal("level gate")
	}
	c.Policy.SuperChance = 10001
	if c.Validate() == nil {
		t.Fatal("bad probability")
	}
	c.Policy.SuperChance = 100
	c.Pools["200012"][0][2] = 9999
	if c.Validate() == nil {
		t.Fatal("bad source weight total")
	}
}

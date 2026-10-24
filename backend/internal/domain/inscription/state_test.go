package inscription_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	ins "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

func catalog(t *testing.T) ins.Catalog {
	t.Helper()
	b, e := builtin.GeneratedFile("inscription_input_catalog.json")
	if e != nil {
		t.Fatal(e)
	}
	var c ins.Catalog
	if e = json.Unmarshal(b, &c); e != nil {
		t.Fatal(e)
	}
	if e = c.Validate(); e != nil {
		t.Fatal(e)
	}
	return c
}
func TestSourcePositionsSuitsAndDisplayBattleAreDistinct(t *testing.T) {
	c := catalog(t)
	n := 0
	for _, r := range c.Tables["items"] {
		_ = r
		n++
	}
	if n != 240 {
		t.Fatal(n)
	}
	it, ok := c.Item(160100103)
	if !ok || it.Display[23] != "3" || it.Battle[23] != "300" {
		t.Fatal(it)
	}
	f := ins.HeroFacts{Slots: [3]int64{160500101, 160500102, 160500103}}
	if f.Validate(c) != nil || len(f.Suits(c)) != 1 || f.Suits(c)[0] != 2001 {
		t.Fatal(f)
	}
	f.Slots[1] = 160500101
	if f.Validate(c) == nil {
		t.Fatal("wrong slot accepted")
	}
}
func TestRollCeilingsExclusionRetryAndLaneBoundaries(t *testing.T) {
	c := catalog(t)
	o := operation.Context{}
	o.EntropySeed[0] = 9
	for _, lane := range []string{"forge", "reforge"} {
		limit := int64(999)
		if lane == "reforge" {
			limit = 99
		}
		f, _ := c.Family(10007)
		id, n, e := c.Draw(f, lane, limit, 160100701, o, 0)
		it, _ := c.Item(id)
		fam, _ := c.Family(it.Family)
		if e != nil || n != 0 || fam.Special != 1 {
			t.Fatal(lane, id, n, e)
		}
	}
	f, _ := c.Family(10001)
	for ordinal := uint64(0); ordinal < 1000; ordinal++ {
		id, n, e := c.Draw(f, "reforge", 7, 160100101, o, ordinal)
		id2, n2, e2 := c.Draw(f, "reforge", 7, 160100101, o, ordinal)
		if e != nil || e2 != nil || id == 160100101 || id != id2 || n != 7 || n2 != 7 {
			t.Fatal(id, n, e)
		}
	}
}
func TestPendingCloneIsolationAndInvalidSourceRejected(t *testing.T) {
	c := catalog(t)
	s := ins.Seed()
	if s.Validate(c) != nil {
		t.Fatal("seed")
	}
	h := ins.SeedHero()
	if len(h.Wire()) != 0 {
		t.Fatal(h)
	}
	if ins.Certificate(19) != "degree_cer" || ins.Certificate(20) != "graduate_cer" || ins.Certificate(21) != "patent_cer" {
		t.Fatal("scalar identity")
	}
	s.ForgeMisses = 1000
	if s.Validate(c) == nil {
		t.Fatal("counter ceiling")
	}
}

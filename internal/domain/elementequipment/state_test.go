package elementequipment_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	elem "gxb.local/backend/v2/internal/domain/elementequipment"
	"math/big"
	"testing"
)

func catalog(t *testing.T) elem.Catalog {
	t.Helper()
	c, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	return elem.Catalog{SchemaVersion: c.ElementInputs.SchemaVersion, PolicyID: c.ElementInputs.PolicyID, Tables: c.ElementInputs.Tables}
}
func TestSourceRationalRatesBackupIsolationAndExclusiveCount(t *testing.T) {
	c := catalog(t)
	f := elem.SeedHero()
	f.Slots = [4]int64{1, 7, 0, 0}
	f.Levels = [4]int64{0, 1, 0, 0}
	f.Backup[8] = 10
	v, e := c.Evaluate(f, true, 10001001, 0)
	if e != nil || len(v) != 1 || v[5].Value != "3456/25" || v[5].Rate != "6/5" {
		t.Fatal(v, e)
	}
	f.Backup[1] = 0
	f.Slots[0] = 0
	v, e = c.Evaluate(f, true, 10001001, 0)
	if e != nil || v[5].Value != "576/5" {
		t.Fatal("zero core must not inherit intrinsic element", v, e)
	}
	f = elem.SeedHero()
	f.Slots[0] = 39
	f.Levels[0] = 1
	v, e = c.Evaluate(f, true, 10001144, 3)
	if e != nil || v[2].Value != "384/5" {
		t.Fatal(v, e)
	}
	v, e = c.Evaluate(f, false, 10001144, 3)
	if e != nil || v[2].Value != "128/5" {
		t.Fatal("Super must not inherit Normal multiplier", v, e)
	}
	v, e = c.Evaluate(f, true, 10001144, 0)
	if e != nil || v[2].Value != "0" {
		t.Fatal("qualified no owned books", v, e)
	}
}
func TestSourceCoreParametersAndCostBoundaryVectors(t *testing.T) {
	c := catalog(t)
	for _, q := range []struct {
		id, l int64
		v     string
		p     bool
	}{{2, 3, "333/100", true}, {27, 1, "-64/5", false}, {39, 10, "80", false}} {
		v, p, e := c.BattleValue(q.id, q.l)
		if e != nil || v != q.v || p != q.p {
			t.Fatal(q, v, p, e)
		}
	}
	m, e := c.Materials(6, 1, false)
	if e != nil || m[50001886] != 10 || m[50001885] != 1 {
		t.Fatal(m, e)
	}
	m, e = c.Materials(10, 3, true)
	if e != nil || m[50001886] != 59 || m[50001885] != 6 {
		t.Fatal(m, e)
	}
	if _, e = c.Materials(10, 1, false); e == nil {
		t.Fatal("cap admits paid enhancement")
	}
}
func TestBindingFactsRejectAliasesDuplicateTemplatesAndBadLevels(t *testing.T) {
	c := catalog(t)
	for _, makeBad := range []func(*elem.HeroFacts){func(f *elem.HeroFacts) { f.Slots[0] = 7 }, func(f *elem.HeroFacts) { f.Slots[1] = 1 }, func(f *elem.HeroFacts) { f.Slots[1] = 7; f.Backup[7] = 1 }, func(f *elem.HeroFacts) { f.Backup[7] = 11 }, func(f *elem.HeroFacts) { f.Levels[0] = 1 }, func(f *elem.HeroFacts) { f.Backup[99999] = 0 }, func(f *elem.HeroFacts) { f.Policy = "unknown" }} {
		f := elem.SeedHero()
		makeBad(&f)
		if f.Validate(c) == nil {
			t.Fatal(f)
		}
	}
	f := elem.SeedHero()
	f.Backup[7] = 3
	cl := f.Clone()
	cl.Backup[7] = 4
	if f.Backup[7] != 3 {
		t.Fatal("aliased owner facts")
	}
	b, _ := json.Marshal(f.Wire())
	if len(b) == 0 {
		t.Fatal("empty wire")
	}
}
func FuzzSourceBattleValueExactAndLevelBounded(f *testing.F) {
	f.Add(int64(2), int64(3))
	f.Add(int64(27), int64(1))
	f.Add(int64(39), int64(10))
	c, e := builtin.Load()
	if e != nil {
		f.Fatal(e)
	}
	f.Fuzz(func(t *testing.T, id, l int64) {
		v, _, e := (elem.Catalog{SchemaVersion: c.ElementInputs.SchemaVersion, PolicyID: c.ElementInputs.PolicyID, Tables: c.ElementInputs.Tables}).BattleValue(id, l)
		_, exists := (elem.Catalog{SchemaVersion: c.ElementInputs.SchemaVersion, PolicyID: c.ElementInputs.PolicyID, Tables: c.ElementInputs.Tables}).Item(id)
		if !exists || l < 0 || l > 10 {
			if e == nil {
				t.Fatal("out of source domain")
			}
			return
		}
		if e != nil {
			t.Fatal(e)
		}
		if _, ok := new(big.Rat).SetString(v); !ok {
			t.Fatal(v)
		}
	})
}

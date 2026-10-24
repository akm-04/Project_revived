package privilege_test

import (
	"gxb.local/backend/v2/internal/content/builtin"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"testing"
)

var charges = []int64{0, 30, 300, 900, 1500, 3000, 6000, 9000, 15000, 20000, 30000, 45000, 60000, 100000, 250000, 500000}
var caps = []int64{10, 10, 10, 10, 10, 20, 20, 30, 30, 40, 40, 50, 50, 60, 60, 80}

func catalog(t testing.TB) d.Catalog {
	t.Helper()
	b, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	c := d.Catalog{SchemaVersion: 1, PolicyID: d.CatalogPolicy}
	for _, r := range b.Privilege.Rows {
		c.Rows = append(c.Rows, d.Threshold{Level: r.Level, Charge: r.Charge, SkillCap: r.SkillCap})
	}
	return c
}
func TestSourceVIPAllThresholdsAndCaps(t *testing.T) {
	c := catalog(t)
	for i, n := range charges {
		for _, charge := range []int64{n, n + 1} {
			v, e := c.Derive(charge)
			if e != nil || v != int64(i) {
				t.Fatal(i, charge, v, e)
			}
		}
		if i > 0 {
			v, e := c.Derive(n - 1)
			if e != nil || v != int64(i-1) {
				t.Fatal(i, v, e)
			}
		}
		v, e := c.SkillCap(int64(i))
		if e != nil || v != caps[i] {
			t.Fatal(i, v, e)
		}
	}
	for _, n := range []int64{-1, 9007199254740992} {
		if _, e := c.Derive(n); e == nil {
			t.Fatal(n)
		}
	}
	bad := c
	bad.Rows = append([]d.Threshold{}, c.Rows...)
	bad.Rows[2].Charge = 29
	if bad.Validate() == nil {
		t.Fatal("unordered thresholds")
	}
}
func FuzzVIPThresholdReduction(f *testing.F) {
	for _, n := range charges {
		f.Add(n)
	}
	f.Add(int64(9007199254740991))
	c := catalog(f)
	f.Fuzz(func(t *testing.T, n int64) {
		got, e := c.Derive(n)
		if n < 0 || n > 9007199254740991 {
			if e == nil {
				t.Fatal(n)
			}
			return
		}
		var want int64
		for i, threshold := range charges {
			if n >= threshold {
				want = int64(i)
			}
		}
		if e != nil || got != want {
			t.Fatal(n, got, want, e)
		}
	})
}

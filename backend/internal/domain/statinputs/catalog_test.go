package statinputs_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	n "gxb.local/backend/v2/internal/domain/statinputs"
	rules "gxb.local/backend/v2/internal/domain/statrules"
	"math"
	"os"
	"testing"
)

func materializer(t *testing.T) *n.Materializer {
	t.Helper()
	c, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	i, e := n.NewCatalog(c.StatInputs.SchemaVersion, c.StatInputs.PolicyID, c.StatInputs.Tables)
	if e != nil {
		t.Fatal(e)
	}
	b, _ := json.Marshal(c.StatRules)
	var r rules.Catalog
	if e = json.Unmarshal(b, &r); e != nil {
		t.Fatal(e)
	}
	m, e := n.New(c.RevisionID(), i, r)
	if e != nil {
		t.Fatal(e)
	}
	return m
}
func TestOriginalLuaRawSkillLevelBuffAndForcePaths(t *testing.T) {
	m := materializer(t)
	b, e := os.ReadFile("../../../testdata/sourcefacts/i7c3b_skill_input_vectors.json")
	if e != nil {
		t.Fatal(e)
	}
	var v struct {
		Vectors []struct {
			State    n.SkillState
			Expected []float64
		}
	}
	if e = json.Unmarshal(b, &v); e != nil {
		t.Fatal(e)
	}
	if len(v.Vectors) != 75 {
		t.Fatal("source coverage drift")
	}
	for _, v := range v.Vectors {
		a, f, e := m.SkillNumbers(v.State)
		if e != nil {
			t.Fatal(v.State, e)
		}
		for i, n := range a {
			if math.Abs(n-v.Expected[i]) > 1e-8 {
				t.Fatalf("%+v attr%d got%v want%v", v.State, i+1, n, v.Expected[i])
			}
		}
		if math.Abs(f-v.Expected[49]) > 1e-8 {
			t.Fatal(v.State, "force", f, v.Expected[49])
		}
	}
}
func TestOriginalLuaEquipmentPromotionFumoEnhancement(t *testing.T) {
	m := materializer(t)
	b, e := os.ReadFile("../../../testdata/sourcefacts/i7c3b_equipment_vectors.json")
	if e != nil {
		t.Fatal(e)
	}
	var v struct {
		Vectors []struct {
			Model      string
			TemplateID int64
			Color      int
			Slots      []n.Slot
			Expected   [][]float64
		}
	}
	if e = json.Unmarshal(b, &v); e != nil {
		t.Fatal(e)
	}
	if len(v.Vectors) != 27 {
		t.Fatal("source coverage drift")
	}
	for _, v := range v.Vectors {
		eq, p, f, e := m.Inputs.Equipment(v.Model, v.TemplateID, v.Color, v.Slots)
		if e != nil {
			t.Fatal(v.Model, v.TemplateID, v.Color, e)
		}
		for i, row := range v.Expected {
			for j, got := range []float64{eq[i], p[i], f[i]} {
				if math.Abs(got-row[j]) > 1e-8 {
					t.Fatal(v.Model, v.TemplateID, v.Color, i+1, j, got, row[j])
				}
			}
		}
	}
}
func TestCatalogDetachedAndUnknownNeverZero(t *testing.T) {
	c, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	r := c.StatInputs
	cat, e := n.NewCatalog(r.SchemaVersion, r.PolicyID, r.Tables)
	if e != nil {
		t.Fatal(e)
	}
	row, e := cat.Row("item", 20000001)
	if e == nil {
		row["attr_values"] = "999999"
		again, _ := cat.Row("item", 20000001)
		if again["attr_values"] == "999999" {
			t.Fatal("mutable catalog")
		}
	}
	if _, e = cat.Item(-1); e == nil {
		t.Fatal("unknown item became zero")
	}
	if _, _, _, e = cat.Equipment("Pet", -1, 1, nil); e == nil {
		t.Fatal("unknown template became zero")
	}
	for _, s := range []string{"NaN", "Inf", "-Inf", "9007199254740992"} {
		if _, e = n.Number(s); e == nil {
			t.Fatal("unsafe numeric", s)
		}
	}
}
func FuzzRejectUnsafeNumbers(f *testing.F) {
	for _, s := range []string{"0", "-2.5", "NaN", "Inf", "1e500", "9007199254740992"} {
		f.Add(s)
	}
	f.Fuzz(func(t *testing.T, s string) {
		v, e := n.Number(s)
		if e == nil && !n.Finite(v) {
			t.Fatal("nonfinite accepted")
		}
	})
}

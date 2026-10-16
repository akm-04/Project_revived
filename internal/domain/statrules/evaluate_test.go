package statrules_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/statrules"
	"math"
	"os"
	"reflect"
	"strconv"
	"strings"
	"testing"
	"time"
)

type vector struct {
	Model              string
	TemplateID         int64
	Level, Star, Color int
	Inputs             map[string]statrules.Observation
	Expected           [][]float64
}

func fixture(t *testing.T) (*statrules.Engine, statrules.Catalog, string, []vector) {
	t.Helper()
	c, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	raw, _ := json.Marshal(c.StatRules)
	var domain statrules.Catalog
	if json.Unmarshal(raw, &domain) != nil {
		t.Fatal("domaincatalog")
	}
	e, err := statrules.NewEngine(c.RevisionID(), domain)
	if err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile("../../../testdata/sourcefacts/i7c3a_numeric_adapter_vectors.json")
	if err != nil {
		t.Fatal(err)
	}
	var f struct{ Vectors []vector }
	if json.Unmarshal(b, &f) != nil {
		t.Fatal("fixture")
	}
	return e, domain, c.RevisionID(), f.Vectors
}
func snap(v vector, rev string) statrules.Snapshot {
	return statrules.Snapshot{Model: v.Model, TemplateID: v.TemplateID, Level: v.Level, Star: v.Star, Color: v.Color, ActorReference: "source-numeric-fixture/target-actor", ObservationID: "fixed-witness-numerical-only", ContentRevision: rev, PolicyID: statrules.PolicyID, ObservedAt: time.Date(2026, 10, 16, 12, 0, 0, 0, time.UTC), Inputs: v.Inputs}
}
func close(a, b float64) bool { return math.Abs(a-b) <= 1e-10*math.Max(1, math.Abs(b)) }
func TestExactSourceMaterializedDifferential(t *testing.T) {
	e, _, rev, vs := fixture(t)
	for _, v := range vs {
		t.Run(v.Model, func(t *testing.T) {
			out, err := e.Evaluate(snap(v, rev))
			if err != nil {
				t.Fatal(err)
			}
			for a := 0; a < 49; a++ {
				if !close(out.Total[a], v.Expected[a][0]) {
					t.Fatalf("attr%d total %.17g want%.17g", a+1, out.Total[a], v.Expected[a][0])
				}
				if out.WithoutBook != nil {
					if !close(out.WithoutBook[a], v.Expected[a][1]) {
						t.Fatalf("attr%d withoutbook %.17g want%.17g", a+1, out.WithoutBook[a], v.Expected[a][1])
					}
				} else if out.PetInitialLabel[a] != v.Expected[a][1] || out.PetAddedLabel[a] != v.Expected[a][2] {
					t.Fatalf("attr%d label split", a+1)
				}
			}
			if out.Force != v.Expected[49][0] {
				t.Fatalf("force %.17g want%.17g", out.Force, v.Expected[49][0])
			}
		})
	}
}
func TestFailClosedAndIsolation(t *testing.T) {
	e, c, rev, vs := fixture(t)
	s := snap(vs[0], rev)
	want, err := e.Evaluate(s)
	if err != nil {
		t.Fatal(err)
	}
	c.Models["NormalHero"].Rules["getTotalAttr"][0].Value = 999
	got, err := e.Evaluate(s)
	if err != nil || !reflect.DeepEqual(want, got) {
		t.Fatal("catalog alias")
	}
	got.Total[0] = -1
	again, err := e.Evaluate(s)
	if err != nil || again.Total[0] != want.Total[0] {
		t.Fatal("result alias")
	}
	bad := s
	bad.ContentRevision = strings.Repeat("f", 64)
	if _, err = e.Evaluate(bad); err == nil {
		t.Fatal("wrongrevision")
	}
	bad = s
	bad.TemplateID = vs[4].TemplateID
	if _, err = e.Evaluate(bad); err == nil {
		t.Fatal("wrongmodel")
	}
	bad = s
	bad.ActorReference = ""
	if _, err = e.Evaluate(bad); err == nil {
		t.Fatal("unboundactor")
	}
	bad = s
	bad.Inputs = map[string]statrules.Observation{}
	if _, err = e.Evaluate(bad); err == nil {
		t.Fatal("missing zeroed")
	}
	o := s.Inputs["getSkillAttr"]
	old := o.Values[1]
	o.Values[1] = math.NaN()
	if _, err = e.Evaluate(s); err == nil {
		t.Fatal("NaN")
	}
	o.Values[1] = old
	delete(o.Values, 1)
	if _, err = e.Evaluate(s); err == nil {
		t.Fatal("missingvalue")
	}
	o.Values[1] = old
}
func TestPetFumoAndEnergyRemainDistinct(t *testing.T) {
	e, _, rev, vs := fixture(t)
	p := snap(vs[8], rev)
	before, err := e.Evaluate(p)
	if err != nil {
		t.Fatal(err)
	}
	p.Inputs["getEquipFumoAttr"].Values[4] += 1000
	after, err := e.Evaluate(p)
	if err != nil || before.Total != after.Total || before.Force != after.Force || after.PetAddedLabel[3] != before.PetAddedLabel[3]+1000 {
		t.Fatal("PetFumo path collapsed", err)
	}
	h, err := e.Evaluate(snap(vs[0], rev))
	if err != nil || h.Total[41] != 1 || h.WithoutBook[41] == 1 {
		t.Fatal("Energy42 paths", err)
	}
}
func FuzzMaterializedRejectNonfinite(f *testing.F) {
	f.Add(float64(1))
	f.Add(math.Inf(1))
	f.Fuzz(func(t *testing.T, v float64) {
		if math.IsNaN(v) || math.IsInf(v, 0) || math.Abs(v) > 9007199254740991 {
			c, err := builtin.Load()
			if err != nil {
				t.Fatal(err)
			}
			raw, _ := json.Marshal(c.StatRules)
			var domain statrules.Catalog
			if json.Unmarshal(raw, &domain) != nil {
				t.Fatal("domaincatalog")
			}
			e, err := statrules.NewEngine(c.RevisionID(), domain)
			if err != nil {
				t.Fatal(err)
			}
			s := statrules.Snapshot{Model: "NormalHero", TemplateID: 10001001, Level: 1, Star: 1, Color: 1, ActorReference: "numeric", ObservationID: "numeric", ContentRevision: c.RevisionID(), PolicyID: statrules.PolicyID, ObservedAt: time.Unix(1, 0), Inputs: map[string]statrules.Observation{"getSkillAttr": {Reference: "fixture", Values: map[int]float64{1: v}}}}
			if _, err = e.Evaluate(s); err == nil {
				t.Fatal("nonfinite")
			}
		}
	})
}
func TestFlatBuffLevelAndPercent(t *testing.T) {
	e, c, _, _ := fixture(t)
	flat, percent := false, false
	for _, r := range c.Buffs {
		if r["attr"] == "0" {
			continue
		}
		id, er := strconv.ParseInt(r["id"], 10, 64)
		if er != nil {
			t.Fatal(er)
		}
		if strings.Contains(r["init"], "p") {
			_, v, er := e.FlatBuff(id, 7)
			if er != nil || v != 0 {
				t.Fatal("percent included", er)
			}
			percent = true
		} else if r["init"] != "" && r["step"] != "" && !strings.Contains(r["step"], "p") {
			ini, er := strconv.ParseFloat(r["init"], 64)
			step, er2 := strconv.ParseFloat(r["step"], 64)
			if er != nil || er2 != nil {
				continue
			}
			_, v, er := e.FlatBuff(id, 7)
			if er != nil || !close(v, ini+7*step) {
				t.Fatal("effectivelevel", er)
			}
			flat = true
		}
		if flat && percent {
			break
		}
	}
	if !flat || !percent {
		t.Fatal("missing source counterexamples")
	}
}
func TestRejectUnknownMaterializedMethod(t *testing.T) {
	e, _, rev, vs := fixture(t)
	s := snap(vs[0], rev)
	s.Inputs["viewerBackpackFallback"] = statrules.Observation{Reference: "forbidden", Values: map[int]float64{0: 0}}
	if _, err := e.Evaluate(s); err == nil {
		t.Fatal("unknown adapter method")
	}
}

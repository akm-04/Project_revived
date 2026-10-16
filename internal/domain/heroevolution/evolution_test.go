package heroevolution_test

import (
	"encoding/json"
	"math"
	"reflect"
	"strconv"
	"testing"

	"gxb.local/backend/v2/internal/content/builtin"
	e "gxb.local/backend/v2/internal/domain/heroevolution"
)

func catalog(t testing.TB) e.Catalog {
	t.Helper()
	b, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	c, err := e.NewCatalog(b.EvolutionInputs.SchemaVersion, b.EvolutionInputs.PolicyID, b.EvolutionInputs.Tables)
	if err != nil {
		t.Fatal(err)
	}
	return c
}
func TestActualSourceFullNormalSuperLifecycleAndCumulativeContributions(t *testing.T) {
	c := catalog(t)
	for _, id := range []int64{10001001, 11001} {
		h, ok := c.Hero(id)
		if !ok {
			t.Fatal("source template missing")
		}
		f := e.Seed()
		for stage := int64(1); stage <= 3; stage++ {
			s, _ := c.Stage(stage)
			for _, attr := range s.Attrs {
				before := f.Clone()
				next, err := c.Allocate(f, id, 100, 5, attr, s.Limit, h.StoneID)
				if err != nil || !reflect.DeepEqual(before, f) {
					t.Fatalf("allocate mutated input or failed: %v", err)
				}
				f = next
				if _, err := c.Allocate(f, id, 100, 5, attr, 1, h.StoneID); err == nil {
					t.Fatal("overcap accepted")
				}
			}
			before, err := c.Evaluate(f)
			if err != nil {
				t.Fatal(err)
			}
			if stage < 3 {
				next, err := c.Advance(f, id, 100, 5)
				if err != nil {
					t.Fatal(err)
				}
				after, err := c.Evaluate(next)
				if err != nil || !reflect.DeepEqual(before, after) || len(next.Points) != 0 {
					t.Fatal("completed-stage contribution lost at reset")
				}
				f = next
			} else {
				want := map[int64]int64{4: 14400, 7: 320, 8: 320, 11: 6400, 26: 3600}
				if !reflect.DeepEqual(before, want) {
					t.Fatalf("source cumulative vector: %v", before)
				}
				if _, err := c.Advance(f, id, 100, 5); err == nil {
					t.Fatal("max stage advanced")
				}
			}
		}
	}
}
func TestAllocationSourceTicketsRequirementsAndInvalidStates(t *testing.T) {
	c := catalog(t)
	f := e.Seed()
	for _, item := range []int64{40001001, 50005148, 50005149} {
		if _, err := c.Allocate(f, 10001001, 80, 3, 4, 1, item); err != nil {
			t.Fatal(item, err)
		}
	}
	for _, args := range [][6]int64{{79, 3, 4, 1, 40001001, 10001001}, {80, 2, 4, 1, 40001001, 10001001}, {80, 3, 4, 1, 40001002, 10001001}, {80, 3, 5, 1, 40001001, 10001001}, {80, 3, 4, 0, 40001001, 10001001}, {80, 3, 4, math.MaxInt64, 40001001, 10001001}, {80, 3, 4, 1, 50005148, 11001}} {
		if _, err := c.Allocate(f, args[5], args[0], args[1], args[2], args[3], args[4]); err == nil {
			t.Fatal("invalid allocation accepted", args)
		}
	}
	for _, bad := range []e.Facts{{Stage: 0, Points: map[string]int64{}}, {Stage: 4, Points: map[string]int64{}}, {Stage: 1}, {Stage: 1, Points: map[string]int64{"04": 1}}, {Stage: 1, Points: map[string]int64{"4": 21}}, {Stage: 1, Points: map[string]int64{"4": -1}}, {Stage: 1, Points: map[string]int64{"999": 1}}} {
		if _, err := c.Evaluate(bad); err == nil {
			t.Fatal("unqualified state evaluated", bad)
		}
	}
	if _, err := c.Advance(f, 10001001, 100, 5); err == nil {
		t.Fatal("incomplete stage advanced")
	}
	s, _ := c.Stage(1)
	for _, a := range s.Attrs {
		f.Points[strconv.FormatInt(a, 10)] = s.Limit
	}
	if _, err := c.Advance(f, 10001001, 89, 4); err == nil {
		t.Fatal("next level gate ignored")
	}
	if _, err := c.Advance(f, 10001001, 90, 3); err == nil {
		t.Fatal("next star gate ignored")
	}
	if _, err := c.Advance(f, 10001001, 90, 4); err != nil {
		t.Fatal(err)
	}
}
func TestCatalogAndWireCopiesDoNotAliasOwnerFacts(t *testing.T) {
	c := catalog(t)
	s, _ := c.Stage(1)
	s.Attrs[0] = 999
	s.Coefficients[0] = 999
	got, _ := c.Stage(1)
	if got.Attrs[0] != 4 || got.Coefficients[0] != 180 {
		t.Fatal("catalog leaked slice")
	}
	f := e.Seed()
	f.Points["4"] = 3
	wire := f.Wire()
	wire["evo_attr_points"].(map[string]int64)["4"] = 7
	if f.Points["4"] != 3 {
		t.Fatal("wire leaked canonical map")
	}
}
func FuzzAllocationNeverExceedsSourceCapOrMutatesInput(f *testing.F) {
	c := catalog(f)
	f.Add(int64(1), int64(4), int64(1), int64(0))
	f.Add(int64(3), int64(26), int64(math.MaxInt64), int64(39))
	f.Fuzz(func(t *testing.T, stage, attr, amount, stored int64) {
		facts := e.Facts{Stage: stage, Points: map[string]int64{strconv.FormatInt(attr, 10): stored}}
		before, _ := json.Marshal(facts)
		next, err := c.Allocate(facts, 10001001, 100, 5, attr, amount, 40001001)
		after, _ := json.Marshal(facts)
		if string(before) != string(after) {
			t.Fatal("input mutated")
		}
		if err == nil {
			if next.Validate(c) != nil || next.Points[strconv.FormatInt(attr, 10)] != stored+amount {
				t.Fatal("invalid successful transition")
			}
		}
	})
}

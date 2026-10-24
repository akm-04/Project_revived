package spirit_test

import (
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/identity"
	s "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"reflect"
	"sort"
	"testing"
	"time"
)

func catalog(t testing.TB) s.Catalog {
	t.Helper()
	b, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	v, e := s.NewCatalog(b.SpiritInputs.SchemaVersion, b.SpiritInputs.PolicyID, b.SpiritInputs.Tables)
	if e != nil {
		t.Fatal(e)
	}
	return v
}
func op(t testing.TB) operation.Context {
	t.Helper()
	v, e := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if e != nil {
		t.Fatal(e)
	}
	return v
}
func instance(c s.Catalog, id, template int64) s.Instance {
	m, _, e := c.ModelFor(template)
	if e != nil {
		panic(e)
	}
	return s.Instance{ID: id, TemplateID: template, Star: m.Star, Main: 1, MainValue: json.Number(m.MainBase[0]), Sub: []int64{}, SubValues: []json.Number{}, BirthSub: []int64{}, Policy: s.ReconstructionPolicy}
}
func TestSourceContributionRatesSuitAndOathDescriptor(t *testing.T) {
	c := catalog(t)
	v := s.Seed()
	v.Instances[1] = instance(c, 1, 250000111)
	v.Instances[2] = instance(c, 2, 250000112)
	v.NextID = 3
	out, e := c.Evaluate(v, [6]int64{1, 2})
	if e != nil || out.Raw[5] != "18" || out.Values[5] != "126/5" || out.Values[48] != "4000" || out.Values[43] != "40" || !reflect.DeepEqual(out.TwoPiece, []int64{1001}) {
		t.Fatal(out, e)
	}
	v = s.Seed()
	for i, id := range []int64{250001131, 250001132, 250001133, 250001134} {
		v.Instances[int64(i+1)] = instance(c, int64(i+1), id)
	}
	v.NextID = 5
	out, e = c.Evaluate(v, [6]int64{1, 2, 3, 4})
	if e != nil || out.FourPiece != 1011 || out.FourPieceKnownCombatID || out.Raw[1] != "100" {
		t.Fatal("preserve source Oath helper and descriptor; never V1 blanket suppression", out, e)
	}
}
func TestSourceEXPBoundaryCostAndUnknownMilestoneGate(t *testing.T) {
	c := catalog(t)
	target := instance(c, 1, 250000111)
	fodder := []s.Instance{}
	for id := int64(2); id <= 4; id++ {
		fodder = append(fodder, instance(c, id, 250000111))
	}
	got, gain, cost, e := c.Enhancement(target, fodder, nil, op(t))
	if e != nil || gain != 1500 || cost != 37500 || got.Level != 1 || got.EXP != 1500 || got.MainValue != "23.4" {
		t.Fatal(got, gain, cost, e)
	}
	for id := int64(5); id <= 10; id++ {
		fodder = append(fodder, instance(c, id, 250000111))
	}
	if _, _, _, e = c.Enhancement(target, fodder, nil, op(t)); !errors.Is(e, s.ErrUnavailable) {
		t.Fatal("unknown milestone must fail unavailable", e)
	}
	got, gain, cost, e = c.Enhancement(target, fodder, s.V1PreservationPolicy{}, op(t))
	if e != nil || got.Level != 3 || got.EXP != 4500 || got.MainValue != "34.2" || len(got.Sub) != 1 || gain != 4500 || cost != 112500 {
		t.Fatal(got, gain, cost, e)
	}
	if target.Level != 0 || target.MainValue != "18" {
		t.Fatal("mutated input")
	}
	max, _ := c.MaxEXP(1)
	if max != 67500 {
		t.Fatal("source cap", max)
	}
	for _, x := range []struct{ exp, want int64 }{{999, 0}, {1000, 1}, {2499, 1}, {2500, 2}, {4499, 2}, {4500, 3}, {67500, 15}} {
		lev, e := c.Level(1, x.exp)
		if e != nil || lev != x.want {
			t.Fatal(x, lev, e)
		}
	}
	if _, e := c.Level(1, 67501); e == nil {
		t.Fatal("overcap imported EXP")
	}
}
func TestConditionalMintDeterminismSelectorsAndOpaqueIdentity(t *testing.T) {
	c := catalog(t)
	o := op(t)
	p := s.V1PreservationPolicy{}
	a, e := p.Generate(c, 250000111, o, "source=one/ordinal=0")
	b, f := p.Generate(c, 250000111, o, "source=one/ordinal=0")
	if e != nil || f != nil || !reflect.DeepEqual(a, b) {
		t.Fatal(e, f)
	}
	a.ID = 1
	if e = a.Validate(c); e != nil {
		t.Fatal(e)
	}
	if _, _, e := c.ModelFor(1); e == nil {
		t.Fatal("model/instance ID must not be template ID")
	}
	a.MainValue = "18.0000001"
	if a.Validate(c) == nil {
		t.Fatal("unqualified materialized value")
	}
}
func TestStateRejectsConsumedReferencesDuplicateBindingsAndAliasing(t *testing.T) {
	c := catalog(t)
	v := s.Seed()
	v.NextID = 2
	v.Instances[1] = instance(c, 1, 250000111)
	v.NextProgramID = 2
	v.Programs[1] = s.Program{ID: 1, Name: "保存", Slots: [6]int64{1}}
	if e := v.Validate(c); e != nil {
		t.Fatal(e)
	}
	if v.ReferenceCount(1) != 1 {
		t.Fatal("program reference")
	}
	cl := v.Clone()
	delete(cl.Instances, 1)
	if cl.Validate(c) == nil {
		t.Fatal("consumed reference retained")
	}
	if len(v.Instances) != 1 {
		t.Fatal("aliased instance map")
	}
	now := time.Unix(1700000000, 0)
	h := s.HeroRoot{Player: identity.PlayerID(1), PartnerID: 1, Version: 1, Facts: s.SeedHero(), CreatedAt: now, UpdatedAt: now}
	h.Facts.Slots[0] = 1
	other := h
	other.PartnerID = 2
	if _, e := v.ValidateBindings(c, []s.HeroRoot{h, other}); e == nil {
		t.Fatal("same instance bound twice")
	}
	if !s.ValidName("一二三四五六七八九十") || s.ValidName("一二三四五六七八九十一") || s.ValidName(" ") {
		t.Fatal("UTF8 source name bound")
	}
	for _, mutate := range []func(*s.Instance){func(x *s.Instance) { x.EXP = 1000 }, func(x *s.Instance) { x.Main = 0 }, func(x *s.Instance) { x.Sub = []int64{1, 1}; x.SubValues = []json.Number{"40", "40"} }, func(x *s.Instance) { x.Policy = "unqualified" }} {
		x := instance(c, 1, 250000111)
		mutate(&x)
		if x.Validate(c) == nil {
			t.Fatal("bad state admitted", x)
		}
	}
}
func FuzzConditionalMintExactMaterializedState(f *testing.F) {
	f.Add(uint64(1), uint16(0))
	f.Add(uint64(378), uint16(15))
	c := catalog(f)
	o := op(f)
	ids := make([]int64, 0, len(c.Templates))
	for id := range c.Templates {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	f.Fuzz(func(t *testing.T, index uint64, salt uint16) {
		id := ids[index%uint64(len(ids))]
		x, e := (s.V1PreservationPolicy{}).Generate(c, id, o, fmt.Sprint("fuzz/", salt))
		if e != nil {
			t.Fatal(e)
		}
		x.ID = 1
		if e = x.Validate(c); e != nil {
			t.Fatal(e)
		}
		raw, e := json.Marshal(x)
		if e != nil {
			t.Fatal(e)
		}
		var back s.Instance
		if e = json.Unmarshal(raw, &back); e != nil || back.Validate(c) != nil {
			t.Fatal("roundtrip", e)
		}
		if _, _, e := c.ModelFor(x.ID); e == nil {
			t.Fatal("instance/template identity alias")
		}
	})
}

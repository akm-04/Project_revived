package librarylocal

import (
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

func selectedRules() library.FeedRules {
	return library.FeedRules{DecreaseBeginPercent: 10, Axes: [6]library.FeedAxis{
		{AttrID: 4, Cap: 5000, Positive: [2]int64{60, 80}, Negative: [2]int64{45, 60}},
		{AttrID: 5, Cap: 480, Positive: [2]int64{5, 8}, Negative: [2]int64{3, 5}},
		{AttrID: 6, Cap: 480, Positive: [2]int64{5, 8}, Negative: [2]int64{3, 5}},
		{AttrID: 7, Cap: 120, Positive: [2]int64{2, 3}, Negative: [2]int64{1, 2}},
		{AttrID: 8, Cap: 120, Positive: [2]int64{2, 3}, Negative: [2]int64{1, 2}},
		{AttrID: 9, Cap: 120, Positive: [2]int64{2, 3}, Negative: [2]int64{1, 2}},
	}, Methods: [3]library.FeedMethod{
		{ID: 1, CostType: 1, Cost: 500000, InitialRates: [2]int64{70, 30}, ChangeStepPercent: 8, NegativeStepBP: 80},
		{ID: 2, CostType: 2, Cost: 80, InitialRates: [2]int64{55, 45}, ChangeStepPercent: 15, NegativeStepBP: 60},
		{ID: 3, CostType: 50001375, Cost: 1, InitialRates: [2]int64{20, 80}, ChangeStepPercent: 20, NegativeStepBP: 40},
	}}
}
func TestReconstructionProbabilityBoundaryVectors(t *testing.T) {
	r := selectedRules()
	for _, c := range []struct{ method, applied, want int64 }{{1, 0, 0}, {1, 499, 0}, {1, 500, 7000}, {1, 2500, 7400}, {1, 4500, 7800}, {1, 5000, 7880}, {2, 5000, 5860}, {3, 5000, 2160}} {
		got, e := NegativeProbabilityBP(r, c.method, 0, c.applied)
		if e != nil || got != c.want {
			t.Fatalf("%+v got%d %v", c, got, e)
		}
	}
}
func TestFeedingDeterminismBoundsAndMarriedGate(t *testing.T) {
	r := selectedRules()
	now := time.Unix(100, 0).UTC()
	f, _ := library.NewHeroFacts(character.HeroRef{PlayerID: identity.PlayerID(7), PartnerID: 3}, now)
	template := library.TemplateRule{TableID: 10001001, RelationshipSourceID: 10001001, CollectionSourceID: 10001001, DialogEnabled: true}
	catalog := library.Catalog{ContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", Feeding: r, Templates: map[int64]library.TemplateRule{template.TableID: template}}
	id, _ := ids.ParseUUID("12345678-1234-4234-8234-123456789012")
	op := operation.Context{ID: id, StartedAt: now}
	if _, e := RollFeedingV1(op, catalog, f, template, 1); e != library.ErrNotMarried {
		t.Fatal(e)
	}
	f.Married = true
	f.Favor = 2000
	for i, a := range r.Axes {
		f.Applied[i] = a.Cap / 2
	}
	negativeSeen := false
	for seed := 0; seed < 128; seed++ {
		op.EntropySeed[0] = byte(seed)
		for method := int64(1); method <= 3; method++ {
			a, e := RollFeedingV1(op, catalog, f, template, method)
			if e != nil {
				t.Fatal(e)
			}
			b, e := RollFeedingV1(op, catalog, f, template, method)
			if e != nil || a != b {
				t.Fatal("retry changed paid outcome", e)
			}
			for axis, v := range a.Proposed {
				if v < 0 || v > r.Axes[axis].Cap || a.Delta[axis] != v-f.Applied[axis] {
					t.Fatal("invalid effective delta", a)
				}
				if a.Delta[axis] < 0 {
					negativeSeen = true
				}
			}
		}
	}
	if !negativeSeen {
		t.Fatal("source-visible negative previews missing")
	}
	for i, a := range r.Axes {
		f.Applied[i] = a.Cap
	}
	if _, e := RollFeedingV1(op, catalog, f, template, 1); e != library.ErrAtCap {
		t.Fatal(e)
	}
	for i := range f.Applied {
		f.Applied[i] = 0
	}
	a, e := RollFeedingV1(op, catalog, f, template, 1)
	if e != nil {
		t.Fatal(e)
	}
	for i, d := range a.Delta {
		if d < r.Axes[i].Positive[0] || d > r.Axes[i].Positive[1] {
			t.Fatal("initial source span", a)
		}
	}
}
func FuzzFeedingBounds(f *testing.F) {
	f.Add(uint64(7), uint8(1), uint16(9999))
	f.Fuzz(func(t *testing.T, seed uint64, method uint8, progress uint16) {
		r := selectedRules()
		now := time.Unix(100, 0).UTC()
		facts, _ := library.NewHeroFacts(character.HeroRef{PlayerID: identity.PlayerID(7), PartnerID: 1}, now)
		facts.Married = true
		facts.Favor = 2000
		for i, a := range r.Axes {
			facts.Applied[i] = int64(progress%10001) * a.Cap / 10000
		}
		id, _ := ids.ParseUUID("12345678-1234-4234-8234-123456789012")
		op := operation.Context{ID: id, StartedAt: now}
		for i := 0; i < 8; i++ {
			op.EntropySeed[i] = byte(seed >> uint(8*i))
		}
		template := library.TemplateRule{TableID: 1, DialogEnabled: true}
		catalog := library.Catalog{ContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", Feeding: r, Templates: map[int64]library.TemplateRule{1: template}}
		c, e := RollFeedingV1(op, catalog, facts, template, int64(method%3)+1)
		if e == library.ErrAtCap {
			return
		}
		if e != nil {
			t.Fatal(e)
		}
		for i, v := range c.Proposed {
			if v < 0 || v > r.Axes[i].Cap {
				t.Fatal(c)
			}
		}
	})
}

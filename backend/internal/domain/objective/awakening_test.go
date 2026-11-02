package objective

import (
	"errors"
	"strings"
	"testing"
)

func awakeFixture() AwakeCatalog {
	return AwakeCatalog{WishItem: 50005037, Definitions: []AwakeDefinition{
		{ID: 1001001, Type: 1, Stage: 1, Before: 10001001, After: 11001001, Next: 1001003, Target: 1, Item: 20001185, Material: 50001019, Routes: []int64{1200021}},
		{ID: 1001003, Type: 1, Stage: 2, Before: 10001001, After: 11001001, Previous: 1001001, Target: 1, Goal: 4, Routes: []int64{1200021}},
	}, Drops: []AwakeDropRoute{{Mission: 1001001, Campaign: 1200021, Type: 2, Box: 930001, Item: 60001043, Rate: 6666}}}
}

func TestAwakeningLifecycleAndStaleGeneration(t *testing.T) {
	c := awakeFixture()
	if err := c.Validate(); err != nil {
		t.Fatal(err)
	}
	s := NewAwakeRoot()
	a, e := s.Open(c.Definitions[0], 7, strings.Repeat("a", 64))
	if e != nil {
		t.Fatal(e)
	}
	if _, e = s.Open(c.Definitions[0], 8, a.Revision); !errors.Is(e, ErrAwakeningRefused) {
		t.Fatal("parallel ordinary mission admitted", e)
	}
	if _, _, e = s.Claim(c, 1, a.Mission); !errors.Is(e, ErrAwakeningRefused) {
		t.Fatal("incomplete claim", e)
	}
	if e = s.Complete(1, a.Mission, a.Generation, 0); !errors.Is(e, ErrAwakeningRefused) {
		t.Fatal("zero progress completed equipment", e)
	}
	if e = s.Complete(1, a.Mission, a.Generation, 1); e != nil {
		t.Fatal(e)
	}
	old, next, e := s.Claim(c, 1, a.Mission)
	if e != nil || old.Mission != a.Mission || next.Mission != 1001003 || next.Complete {
		t.Fatal(old, next, e)
	}
	if _, e = s.Cancel(1, next.Mission); e != nil {
		t.Fatal(e)
	}
	b, e := s.Open(c.Definitions[0], 7, a.Revision)
	if e != nil || b.Generation <= a.Generation {
		t.Fatal(b, e)
	}
	if e = s.Complete(1, b.Mission, a.Generation, 1); !errors.Is(e, ErrAwakeningRefused) {
		t.Fatal("old attempt completed reopened mission", e)
	}
	if e = s.Complete(1, b.Mission, b.Generation, 1); e != nil {
		t.Fatal(e)
	}
	_, last, e := s.Claim(c, 1, b.Mission)
	if e != nil {
		t.Fatal(e)
	}
	if e = s.Complete(1, last.Mission, last.Generation, 1); e != nil {
		t.Fatal(e)
	}
	_, terminal, e := s.Claim(c, 1, last.Mission)
	if e != nil || terminal.Mission != 0 {
		t.Fatal(terminal, e)
	}
	if e = s.Remember("claim", last, map[string]any{"awards": []any{}}); e != nil {
		t.Fatal(e)
	}
	if _, ok, e := s.Replay("claim", 1, last.Mission); e != nil || !ok {
		t.Fatal(ok, e)
	}
	if e = s.Validate(); e != nil {
		t.Fatal(e)
	}
}

func TestAwakeningCatalogRejectsDanglingRouteAndWishExclusion(t *testing.T) {
	c := awakeFixture()
	if !c.WishAllowed(c.Definitions[0]) {
		t.Fatal("ordinary Wish not available")
	}
	c.WishExcludedItems = []int64{50001019}
	if c.WishAllowed(c.Definitions[0]) {
		t.Fatal("excluded material allowed")
	}
	c.Drops[0].Campaign = 999
	if c.Validate() == nil {
		t.Fatal("dangling source mapping accepted")
	}
	c = awakeFixture()
	c.Definitions[1].Previous = 1
	if c.Validate() == nil {
		t.Fatal("broken chain accepted")
	}
}

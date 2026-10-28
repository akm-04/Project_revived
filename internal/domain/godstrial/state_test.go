package godstrial

import (
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/grant"
	"os"
	"testing"
)

func sourceCatalog(t *testing.T) Catalog {
	t.Helper()
	raw, e := os.ReadFile("../../content/builtin/generated/gods_trial_catalog.json")
	if e != nil {
		t.Fatal(e)
	}
	var c Catalog
	if e = json.Unmarshal(raw, &c); e != nil {
		t.Fatal(e)
	}
	if e = c.Validate(); e != nil {
		t.Fatal(e)
	}
	return c
}

type zeroRNG struct{ draws int }

func (r *zeroRNG) Uniform(n uint64) uint64 { r.draws++; return 0 }
func TestSourceCatalogAndAdmission(t *testing.T) {
	c := sourceCatalog(t)
	s := State{}
	if e := s.Normalize(100); e != nil {
		t.Fatal(e)
	}
	first, _ := c.Stage(1001)
	second, _ := c.Stage(1002)
	if !s.Open(first, 4, 60) || s.Open(first, 5, 100) || s.Open(second, 4, 100) || s.Open(first, 4, 59) {
		t.Fatal("admission")
	}
	s.Wins[1001] = 1
	if !s.Open(second, 4, 70) {
		t.Fatal("previous clear")
	}
	s.Auto = &Auto{Campaign: 1001, Times: 2, Start: 100, Due: 700}
	if e := s.Normalize(99); !errors.Is(e, ErrRefused) {
		t.Fatal(e)
	}
	if e := s.Normalize(800); e != nil || s.Auto == nil || s.Wins[1001] != 1 {
		t.Fatal("rotation lost accepted occurrence")
	}
	if Weekday(-3) != 1 || Weekday(4) != 1 || Weekday(10) != 7 {
		t.Fatal("weekday")
	}
	info := s.Info(c, 4, 70)
	if len(info["campaign_infos"].(map[string]any)) != 6 {
		t.Fatal(info)
	}
}
func TestSourceDropAndTypedOwners(t *testing.T) {
	c := sourceCatalog(t)
	first, _ := c.Stage(1001)
	rng := &zeroRNG{}
	items := c.Drop(first.FirstBox, rng)
	if len(items) == 0 || rng.draws != 0 {
		t.Fatal(items, rng.draws)
	}
	for _, l := range c.Lines(items) {
		if l.Kind != grant.SpecializedDomain || l.Domain != "spirit" {
			t.Fatal(l)
		}
	}
	lines := c.Lines([]campaign.Item{{ItemID: 50002148, Num: 1}})
	if lines[0].Kind != grant.StackItem {
		t.Fatal(lines)
	}
	c.Boxes[0].Rows[0][0] = 1
	if c.Validate() == nil {
		t.Fatal("unknown award owner admitted")
	}
}

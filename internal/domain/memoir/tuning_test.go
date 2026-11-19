package memoir

import (
	"reflect"
	"testing"
)

// maxUniform misses every fractional roll, so only guaranteed rows drop.
type maxUniform struct{}

func (maxUniform) Uniform(uint64) uint64 { return 9999 }

func TestMemoirTuneReplacesOneDropRateOnACopy(t *testing.T) {
	before := sourceCatalog(t)
	after, err := before.Tune(Tuning{Version: 1, BoxRates: map[string]map[string]int64{"597011": {"20001154": 20000}}})
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(before, sourceCatalog(t)) {
		t.Fatal("tuning mutated the source catalog")
	}
	row := boxRow(t, after, 597011, 20001154)
	if row.Rate != 20000 {
		t.Fatalf("rate %d, want 20000", row.Rate)
	}
	if got := after.Draw(597011, maxUniform{}); len(got) != 1 || got[0].ItemID != 20001154 || got[0].Num != 2 {
		t.Fatalf("tuned draw %#v, want two copies of 20001154", got)
	}
	if row := boxRow(t, before, 597011, 20001154); row.Rate != 100 {
		t.Fatalf("source rate %d changed", row.Rate)
	}
}

func TestMemoirTuneRejectsInvalidOverlaysWhole(t *testing.T) {
	source := sourceCatalog(t)
	cases := map[string]Tuning{
		"unknown box":     {BoxRates: map[string]map[string]int64{"1": {"20001154": 10000}}},
		"unknown item":    {BoxRates: map[string]map[string]int64{"597011": {"1": 10000}}},
		"negative rate":   {BoxRates: map[string]map[string]int64{"597011": {"20001154": -1}}},
		"over maximum":    {BoxRates: map[string]map[string]int64{"597011": {"20001154": 100001}}},
		"unparsable item": {BoxRates: map[string]map[string]int64{"597011": {"item": 10000}}},
	}
	for name, tuning := range cases {
		t.Run(name, func(t *testing.T) {
			after, err := source.Tune(tuning)
			if err == nil {
				t.Fatal("invalid overlay accepted")
			}
			if !reflect.DeepEqual(after, source) {
				t.Fatal("rejected overlay changed the catalog")
			}
		})
	}
}

func boxRow(t *testing.T, catalog Catalog, box, item int64) Drop {
	t.Helper()
	for _, candidate := range catalog.Boxes {
		if candidate.ID != box {
			continue
		}
		for _, row := range candidate.Rows {
			if row.Item == item {
				return row
			}
		}
	}
	t.Fatalf("box %d item %d not found", box, item)
	return Drop{}
}

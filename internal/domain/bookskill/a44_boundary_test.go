package bookskill

import (
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"
)

// a44Catalog mirrors the source-qualified cardinalities: schema1 has only the
// three legacy building types; schema2 adds table/administrator/notice/pet.
func a44Catalog(extension bool) Catalog {
	counts := map[int64]int64{1: 6, 3: 6, 4: 100}
	if extension {
		counts[2] = 8
		counts[5] = 5
		counts[6] = 5
		counts[7] = 5
	}
	buildings := map[[2]int64]BookBuildingRule{}
	for sourceType, levels := range counts {
		for level := int64(1); level <= levels; level++ {
			buildings[[2]int64{sourceType, level}] = BookBuildingRule{Type: sourceType, Level: level, Duration: 60, RequiresType: 1}
		}
	}
	return Catalog{
		Buildings: buildings,
		Books:     map[int64]BookRule{100: {ID: 100, Star: 1, Type: 1, Skills: []int64{200}}},
		Skills:    map[int64]BookSkillRule{200: {ID: 200, Book: 100, Partner: 1, CostClass: 1, Times: []int64{60}}},
		Costs:     map[[2]int64]BookCostRule{{1, 1}: {Level: 1, Class: 1, Resources: map[string]int64{"mana": 1}}},
	}
}

// Review13 correction 1: cardinality is a state property, so the seven-type
// catalog alone must not turn an old root red.
func TestA44LegacyRootWithSevenRuleCatalogPasses(t *testing.T) {
	catalog := a44Catalog(true)
	if e := catalog.Validate(); e != nil {
		t.Fatalf("fixture catalog not source-qualified: %v", e)
	}
	if len(catalog.Buildings) != 135 {
		t.Fatalf("fixture building rows = %d, want 135", len(catalog.Buildings))
	}
	if e := Seed().Validate(catalog); e != nil {
		t.Fatalf("legacy three-building root rejected by seven-rule catalog: %v", e)
	}
}

// The actual current boundary: it starts at persisted extension facts, not at
// the catalog shape. Both a seven-rule and a legacy catalog refuse this root,
// so this test must stay green until qualification replaces the cardinality.
func TestA44PersistedExtensionRootIsRefusedToday(t *testing.T) {
	state := Seed()
	state.Buildings[2] = Building{Level: 1}
	for name, catalog := range map[string]Catalog{"seven-rule": a44Catalog(true), "legacy": a44Catalog(false)} {
		if e := state.Validate(catalog); !errors.Is(e, ErrUnqualified) {
			t.Fatalf("%s catalog accepted a persisted extension building: %v", name, e)
		}
	}
}

func TestA44SettlementRetainsCompletedJobRevision(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	state := Seed()
	state.Buildings[2] = Building{Level: 1, Job: &Job{Occurrence: "op", Revision: strings.Repeat("d", 64), StartedAt: at, Duration: 10, Target: 2, Subject: 2, Cost: EmptyCost()}}
	due, e := state.Settle(at.Add(10 * time.Second))
	if e != nil || !due || state.Buildings[2].Level != 2 || state.Buildings[2].Job != nil {
		t.Fatalf("extension settlement: due %t state %+v err %v", due, state.Buildings[2], e)
	}
	saved, e := json.Marshal(state)
	if e != nil {
		t.Fatal(e)
	}
	if !strings.Contains(string(saved), `"CatalogRevision":"`+strings.Repeat("d", 64)+`"`) {
		t.Fatalf("completed settlement lost its accepted revision: %s", saved)
	}
}

func TestA44BuildingPinSurvivesFactsRoundTrip(t *testing.T) {
	pin := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	raw := []byte(`{"Buildings":{"1":{"Level":1,"Job":null,"Recent":false},"2":{"Level":1,"Job":null,"Recent":false,"CatalogRevision":"` + pin + `"},"3":{"Level":1,"Job":null,"Recent":false},"4":{"Level":1,"Job":null,"Recent":false}},"Skills":{}}`)
	var state State
	if e := json.Unmarshal(raw, &state); e != nil {
		t.Fatal(e)
	}
	if state.Buildings[2].Level != 1 {
		t.Fatalf("fixture extension fact not read: %+v", state.Buildings[2])
	}
	saved, e := json.Marshal(state)
	if e != nil {
		t.Fatal(e)
	}
	var document struct {
		Buildings map[string]map[string]any `json:"Buildings"`
	}
	if e = json.Unmarshal(saved, &document); e != nil {
		t.Fatal(e)
	}
	if value, kept := document.Buildings["2"]["CatalogRevision"]; !kept || value != pin {
		t.Fatal("building provenance lost in facts round trip")
	}
}

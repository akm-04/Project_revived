package characterasset

import "testing"

func TestRosterSummaryPreservesCurrentDistinctOriginSemantics(t *testing.T) {
	population := RosterMetricPopulation{Family: "Hero", Rows: []RosterMetricRow{
		{InstanceID: 1, OriginTableID: 1001, TableID: 1001, Star: 4, Version: 2},
		{InstanceID: 2, OriginTableID: 1002, TableID: 11002, Star: 6, Version: 3, BeforeAwaken: 1002},
	}}
	summary, err := population.Summary()
	if err != nil || summary.OwnedCount != 2 || summary.StarCount != 10 || summary.AwakenedCount != 1 {
		t.Fatal(summary, err)
	}
	for _, mutate := range []func(*RosterMetricPopulation){
		func(p *RosterMetricPopulation) { p.Rows[1].OriginTableID = p.Rows[0].OriginTableID },
		func(p *RosterMetricPopulation) { p.Rows[1].InstanceID = p.Rows[0].InstanceID },
		func(p *RosterMetricPopulation) { p.Rows[0].TableID = 0 },
		func(p *RosterMetricPopulation) { p.Rows[0].Star = 0 },
		func(p *RosterMetricPopulation) { p.Rows[0].Version = 0 },
		func(p *RosterMetricPopulation) { p.Rows[0].BeforeAwaken = -1 },
	} {
		copy := population
		copy.Rows = append([]RosterMetricRow(nil), population.Rows...)
		mutate(&copy)
		if _, err := copy.Summary(); err == nil {
			t.Fatal("invalid or duplicate population accepted", copy)
		}
	}
	pet := RosterMetricPopulation{Family: "Pet", Rows: []RosterMetricRow{{InstanceID: 1, OriginTableID: 2001, TableID: 2001, Star: 2, Version: 1}}}
	petSummary, err := pet.Summary()
	if err != nil || petSummary.OwnedCount != 1 || petSummary.StarCount != 2 || petSummary.AwakenedCount != 0 {
		t.Fatal(petSummary, err)
	}
	pet.Rows[0].BeforeAwaken = 2001
	if _, err := pet.Summary(); err == nil {
		t.Fatal("pet awakening origin accepted")
	}
	empty, err := (RosterMetricPopulation{Family: "Hero"}).Summary()
	if err != nil || empty.OwnedCount != 0 {
		t.Fatal(empty, err)
	}
}

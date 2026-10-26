package builtin

import (
	"encoding/json"
	"testing"
)

func TestMissionCatalogRejectsUnknownConditionsAndBrokenChains(t *testing.T) {
	raw, err := GeneratedFile("objective_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	for _, fault := range []string{"unknown condition", "cycle", "missing target", "cross-family target", "reward owner"} {
		t.Run(fault, func(t *testing.T) {
			var catalog ObjectiveCatalog
			if err := json.Unmarshal(raw, &catalog); err != nil {
				t.Fatal(err)
			}
			switch fault {
			case "unknown condition":
				catalog.Definitions[0].Presentation.Condition = 999
			case "cycle":
				catalog.Definitions[0].Prerequisite.Previous = catalog.Definitions[0].ObjectiveID
			case "missing target":
				catalog.Definitions[0].Presentation.Next = 999999
			case "cross-family target":
				catalog.Definitions[0].Presentation.Next = 30001
			case "reward owner":
				catalog.Definitions[0].Reward.Source.PolicyVersion = "unknown"
			}
			if err := validateMissions(catalog); err == nil {
				t.Fatal("corrupt mission catalog accepted")
			}
		})
	}
}

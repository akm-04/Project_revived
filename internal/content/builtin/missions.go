package builtin

import (
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/domain/objective"
)

func validateMissions(c ObjectiveCatalog) error {
	if c.Status != "I9_4_MISSION_CATALOG" || len(c.Definitions) != 476 || len(c.VIP) != 16 {
		return errors.New("builtin content: mission profile drift")
	}
	byID := make(map[int64]ObjectiveDefinition, len(c.Definitions))
	counts := map[objective.StockFamily]int{}
	lastID := int64(0)
	for _, row := range c.Definitions {
		if err := row.Validate(); err != nil {
			return fmt.Errorf("builtin content: mission %d: %w", row.ObjectiveID, err)
		}
		if row.ObjectiveID <= lastID {
			return errors.New("builtin content: mission id order drift")
		}
		lastID = row.ObjectiveID
		byID[row.ObjectiveID] = row
		counts[row.Family]++
	}
	if counts[objective.Daily] != 35 || counts[objective.GrowMain] != 184 || counts[objective.Story] != 250 || counts[objective.Partner] != 7 {
		return errors.New("builtin content: mission family counts drift")
	}
	for _, row := range c.Definitions {
		for _, link := range []int64{row.Prerequisite.Previous, row.Presentation.Next} {
			if link != 0 && byID[link].Family != row.Family {
				return errors.New("builtin content: missing/cross-family mission chain target")
			}
		}
		seen := map[int64]bool{}
		for node := row; node.Prerequisite.Previous != 0; node = byID[node.Prerequisite.Previous] {
			if seen[node.ObjectiveID] {
				return errors.New("builtin content: mission chain cycle")
			}
			seen[node.ObjectiveID] = true
		}
	}
	for index, row := range c.VIP {
		if row.Level != int64(index) || row.SweepCard < 0 {
			return errors.New("builtin content: mission VIP sweep-card profile drift")
		}
	}
	return nil
}

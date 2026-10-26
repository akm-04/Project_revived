package builtin

import (
	"errors"
	"fmt"
)

func validateMissions(c ObjectiveCatalog) error {
	if c.Status != "I9_4_MISSION_CATALOG" || len(c.Definitions) != 476 {
		return errors.New("builtin content: mission profile drift")
	}
	if c.ActivityChests == nil {
		return errors.New("builtin content: activity catalog missing")
	}
	if c.ActivityChests != nil {
		if err := validateActivityCatalog(*c.ActivityChests); err != nil {
			return err
		}
	}
	byID := make(map[int64]ObjectiveDefinition, len(c.Definitions))
	counts := map[int64]int{}
	lastID := int64(0)
	for _, row := range c.Definitions {
		if err := validateMissionRow(row); err != nil {
			return fmt.Errorf("builtin content: mission %d: %w", row.ObjectiveID, err)
		}
		if row.ObjectiveID <= lastID {
			return errors.New("builtin content: mission id order drift")
		}
		lastID = row.ObjectiveID
		byID[row.ObjectiveID] = row
		counts[row.Family]++
	}
	if counts[1] != 35 || counts[2] != 184 || counts[4] != 250 || counts[6] != 7 {
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
	return nil
}

func validateMissionRow(row ObjectiveDefinition) error {
	if row.ObjectiveID <= 0 || row.Target <= 0 || row.ProgramID != fmt.Sprintf("mission:%d", row.Family) || row.DefinitionRevision != "I9_MISSIONS_V1" || row.AcceptedFactKind == "" || row.Huoyue < 0 || row.Prerequisite.Previous < 0 || row.Presentation.Next < 0 || row.Presentation.BattlepassScore < 0 {
		return errors.New("invalid mission content identity")
	}
	generation := "LIFETIME"
	switch row.Family {
	case 1:
		generation = "DAY"
	case 2, 4:
	case 6:
		generation = "HERO"
	default:
		return errors.New("invalid mission family")
	}
	if row.GenerationKind != generation {
		return errors.New("invalid mission occurrence")
	}
	switch row.Strategy {
	case "HIGH_WATER", "COMMITTED_DELTA", "TEMPORAL_ENTITLEMENT":
	default:
		return errors.New("invalid mission strategy")
	}
	gate := row.Prerequisite.Gate
	if !(len(gate) == 1 && (gate[0] == 0 || gate[0] == 9) || len(gate) == 2 && gate[0] >= 1 && gate[0] <= 8 && gate[1] > 0) {
		return errors.New("invalid mission gate")
	}
	kind := row.Presentation.Condition
	if !(kind >= 2 && kind <= 24 || kind >= 101 && kind <= 111 || kind >= 113 && kind <= 121 || kind >= 123 && kind <= 127 || kind >= 129 && kind <= 132) {
		return errors.New("invalid mission condition")
	}
	arity := 1
	if kind == 15 || kind == 19 || kind == 111 {
		arity = 2
	}
	if len(row.Presentation.Parameters) != arity {
		return errors.New("invalid mission parameters")
	}
	for _, v := range row.Presentation.Parameters {
		if v <= 0 {
			return errors.New("invalid mission parameter")
		}
	}
	for _, plan := range []ObjectiveRewardPlan{row.Reward, row.Presentation.BaseReward} {
		if plan.Source.PolicyVersion != "I9_MISSIONS_V1" {
			return errors.New("invalid mission reward policy")
		}
		for _, line := range plan.Lines {
			if line.Amount <= 0 {
				return errors.New("invalid mission reward amount")
			}
			switch line.Kind {
			case "SCALAR_CURRENCY", "TEMPORAL":
				if line.ResourceKey == "" || line.ItemID != 0 || line.Domain != "" {
					return errors.New("invalid mission fungible line")
				}
			case "STACK_ITEM":
				if line.ItemID <= 0 || line.ResourceKey != "" || line.Domain != "" {
					return errors.New("invalid mission stack line")
				}
			case "PLAYER_EXP":
				if line.ItemID != 0 || line.ResourceKey != "" || line.Domain != "" {
					return errors.New("invalid mission EXP line")
				}
			default:
				return errors.New("unqualified mission reward kind")
			}
		}
	}
	if row.Presentation.VIPSweepReward && (kind != 113 || row.Presentation.VIPSweepItemID != 50001013 || len(row.Presentation.VIPSweepByLevel) != 16) {
		return errors.New("invalid mission VIP profile")
	}
	for _, choice := range row.Presentation.InscriptionPool {
		if choice.ItemID <= 0 || choice.Weight <= 0 {
			return errors.New("invalid mission inscription pool")
		}
	}
	return nil
}

func validateActivityCatalog(c ActivityCatalog) error {
	if len(c.Rules) != 7 || len(c.Gifts) != 12 {
		return errors.New("invalid activity content profile")
	}
	gifts := map[int64]bool{}
	rules := map[string]bool{}
	for _, g := range c.Gifts {
		if g.ID <= 0 || gifts[g.ID] || g.Plan.Source.PolicyVersion != "I9_ACTIVITY_CHESTS_V1" || len(g.Plan.Lines) == 0 || g.VIPThreshold < 0 || g.VIPThreshold > 15 || g.VIPBonus < 0 {
			return errors.New("invalid activity gift content")
		}
		gifts[g.ID] = true
		for _, line := range g.Plan.Lines {
			if line.Amount <= 0 {
				return errors.New("invalid activity gift amount")
			}
		}
	}
	for _, r := range c.Rules {
		limit := int64(5)
		if r.Period == "WEEK" {
			limit = 2
		} else if r.Period != "DAY" {
			return errors.New("invalid activity period")
		}
		key := fmt.Sprintf("%s:%d", r.Period, r.Index)
		if r.Index < 1 || r.Index > limit || r.Medal <= 0 || rules[key] || !gifts[r.GiftEXP] || !gifts[r.GiftMarch] {
			return errors.New("invalid activity rule content")
		}
		rules[key] = true
	}
	return nil
}

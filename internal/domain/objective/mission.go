package objective

import (
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/modes"
)

type MissionPrerequisite struct {
	Gate              []int64 `json:"gate"`
	Previous          int64   `json:"previous"`
	DeferredUntil     string  `json:"deferred_until"`
	UnavailableReason string  `json:"unavailable_reason"`
}

type MissionPresentation struct {
	DetailType      int64      `json:"detail_type"`
	Condition       int64      `json:"condition"`
	Parameters      []int64    `json:"parameters"`
	Next            int64      `json:"next"`
	DeferredUntil   string     `json:"deferred_until"`
	BaseReward      grant.Plan `json:"base_reward"`
	BattlepassScore int64      `json:"battlepass_score"`
	VIPSweepReward  bool       `json:"vip_sweep_reward"`
	VIPSweepItemID  int64      `json:"vip_sweep_item_id"`
	VIPSweepByLevel []int64    `json:"vip_sweep_by_level,omitempty"`
}

func (m MissionDefinition) RewardFor(level, maximumLevel, vipLevel int64) (grant.Plan, error) {
	if level < 1 || maximumLevel < level || vipLevel < 0 {
		return grant.Plan{}, errors.New("invalid mission reward observation")
	}
	plan := m.Reward
	plan.Lines = make([]grant.Line, 0, len(m.Reward.Lines)+1)
	for _, line := range m.Reward.Lines {
		if m.Presentation.DetailType == 6 && (level == maximumLevel && line.Kind == grant.PlayerExp || level < maximumLevel && line.ResourceKey == "march_coin") {
			continue
		}
		plan.Lines = append(plan.Lines, line)
	}
	if m.Presentation.VIPSweepReward {
		if vipLevel >= int64(len(m.Presentation.VIPSweepByLevel)) || m.Presentation.VIPSweepItemID <= 0 {
			return grant.Plan{}, errors.New("mission VIP sweep reward unavailable")
		}
		if count := m.Presentation.VIPSweepByLevel[vipLevel]; count > 0 {
			plan.Lines = append(plan.Lines, grant.Line{Kind: grant.StackItem, ItemID: m.Presentation.VIPSweepItemID, Amount: count})
		}
	}
	return plan, nil
}

type MissionDefinition struct {
	ProgramID          string              `json:"program_id"`
	Family             StockFamily         `json:"stock_family"`
	ObjectiveID        int64               `json:"objective_id"`
	DefinitionRevision string              `json:"definition_revision"`
	Strategy           string              `json:"strategy"`
	AcceptedFactKind   string              `json:"accepted_fact_kind"`
	Target             int64               `json:"target"`
	GenerationKind     string              `json:"generation_kind"`
	Prerequisite       MissionPrerequisite `json:"prerequisite_policy"`
	Reward             grant.Plan          `json:"reward_plan"`
	Huoyue             int64               `json:"huoyue"`
	Presentation       MissionPresentation `json:"presentation"`
}

func (m MissionDefinition) Definition() (Definition, error) {
	strategies := map[string]Strategy{"HIGH_WATER": HighWaterFromCanonicalState, "COMMITTED_DELTA": CommittedDeltaFact, "TEMPORAL_ENTITLEMENT": TemporalEntitlement}
	d := Definition{ProgramID: m.ProgramID, ObjectiveID: m.ObjectiveID, DefinitionRevision: m.DefinitionRevision, Strategy: strategies[m.Strategy], AcceptedFactKind: m.AcceptedFactKind, Target: m.Target}
	return d, d.Validate()
}

func (m MissionDefinition) Validate() error {
	if _, err := m.Definition(); err != nil {
		return err
	}
	if m.ProgramID != fmt.Sprintf("mission:%d", m.Family) || m.DefinitionRevision != "I9_MISSIONS_V1" || m.Huoyue < 0 || m.Presentation.BattlepassScore < 0 || m.Prerequisite.Previous < 0 || m.Presentation.Next < 0 {
		return errors.New("invalid mission identity or metadata")
	}
	wantGeneration := "LIFETIME"
	switch m.Family {
	case Daily:
		wantGeneration = "DAY"
	case GrowMain, Story:
	case Partner:
		wantGeneration = "HERO"
	default:
		return errors.New("invalid mission family")
	}
	if m.GenerationKind != wantGeneration || !validMissionGate(m.Prerequisite.Gate) {
		return errors.New("invalid mission generation or gate")
	}
	kind, parameters := m.Presentation.Condition, m.Presentation.Parameters
	if !(kind >= 2 && kind <= 24 || kind >= 101 && kind <= 111 || kind >= 113 && kind <= 121 || kind >= 123 && kind <= 127 || kind >= 129 && kind <= 132) {
		return errors.New("unknown mission condition")
	}
	arity := 1
	if kind == 15 || kind == 19 || kind == 111 {
		arity = 2
	}
	if len(parameters) != arity {
		return errors.New("invalid mission condition arity")
	}
	for _, value := range parameters {
		if value <= 0 {
			return errors.New("invalid mission condition parameter")
		}
	}
	if kind == 111 && (parameters[0] >= parameters[1] || parameters[1] > 86400) || kind == 118 && parameters[0] >= 86400 {
		return errors.New("invalid mission meal window")
	}
	if deferred := m.Prerequisite.DeferredUntil; deferred != "" && (deferred != "I10_COMMERCE_ACTIVE_ENTITLEMENTS" || !(m.Prerequisite.Gate[0] == 4 || m.Prerequisite.Gate[0] >= 6 && m.Prerequisite.Gate[0] <= 8)) {
		return errors.New("invalid mission prerequisite binding")
	}
	if unavailable := m.Prerequisite.UnavailableReason; unavailable != "" && (unavailable != "UNKNOWN_SOURCE_CAMPAIGN_200114" || m.ObjectiveID != 30014 || len(m.Prerequisite.Gate) != 2 || m.Prerequisite.Gate[0] != 2 || m.Prerequisite.Gate[1] != 200114) {
		return errors.New("invalid mission unavailable-source binding")
	}
	if m.Presentation.VIPSweepReward {
		if kind != 113 || m.Presentation.VIPSweepItemID != 50001013 || len(m.Presentation.VIPSweepByLevel) != 16 {
			return errors.New("invalid mission VIP reward profile")
		}
		for _, count := range m.Presentation.VIPSweepByLevel {
			if count < 0 {
				return errors.New("invalid mission VIP reward quantity")
			}
		}
	} else if m.Presentation.VIPSweepItemID != 0 || len(m.Presentation.VIPSweepByLevel) != 0 {
		return errors.New("unexpected mission VIP reward profile")
	}
	for _, plan := range []grant.Plan{m.Reward, m.Presentation.BaseReward} {
		if plan.Source.PolicyVersion != "I9_MISSIONS_V1" {
			return errors.New("invalid mission reward policy")
		}
		for _, line := range plan.Lines {
			if err := line.Validate(); err != nil {
				return err
			}
		}
	}
	return nil
}

func validMissionGate(gate []int64) bool {
	if len(gate) == 1 {
		return gate[0] == 0 || gate[0] == 9
	}
	return len(gate) == 2 && gate[0] >= 1 && gate[0] <= 8 && gate[1] > 0
}

// MissionGeneration keeps daily claim/fact receipts distinct without changing legacy objective identities.
func (m MissionDefinition) MissionGeneration(at time.Time, heroTableID int64) (string, error) {
	if at.IsZero() {
		return "", errors.New("mission decision time required")
	}
	switch m.GenerationKind {
	case "DAY":
		return fmt.Sprintf("day:%d", modes.Day(at)), nil
	case "LIFETIME":
		return "lifetime", nil
	case "HERO":
		if heroTableID <= 0 {
			return "", errors.New("partner mission requires hero template identity")
		}
		return fmt.Sprintf("hero:%d", heroTableID), nil
	default:
		return "", errors.New("unknown mission generation")
	}
}

func (m MissionDefinition) MealClaimable(at time.Time) (bool, error) {
	if at.IsZero() {
		return false, errors.New("mission decision time required")
	}
	seconds := (at.Unix()%86400 + 86400 + 8*3600) % 86400
	parameters := m.Presentation.Parameters
	switch m.Presentation.Condition {
	case 111:
		if len(parameters) != 2 {
			return false, errors.New("invalid meal window")
		}
		return seconds > parameters[0] && seconds < parameters[1], nil
	case 118:
		if len(parameters) != 1 {
			return false, errors.New("invalid meal start")
		}
		return seconds >= parameters[0] || seconds < 5*3600, nil
	default:
		return false, errors.New("mission is not a meal")
	}
}

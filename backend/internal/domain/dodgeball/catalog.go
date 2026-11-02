package dodgeball

import (
	"errors"
	"sort"

	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/combat"
)

const ContractID = "I9_DODGEBALL_V1"
const PolicyID = "I9_DODGEBALL_PRIVATE_POLICY_V1"
const DrawPolicyID = "I9_DODGEBALL_DRAWS_V1"
const MaximumSelfBalls = 10
const ProbabilityBuff = 2
const FriendProbabilityBuff = 3
const AdditionalBallsBuff = 4

var ErrInvalid = errors.New("dodgeball invalid request")
var ErrRefused = errors.New("dodgeball refused")
var ErrUnavailable = errors.New("dodgeball unavailable")

type Target struct {
	ID          int64 `json:"id"`
	Group       int64 `json:"group"`
	HeroTableID int64 `json:"hero_table_id"`
	ItemID      int64 `json:"item_id"`
	Amount      int64 `json:"amount"`
	Weight      int64 `json:"weight"`
	Probability int64 `json:"probability_permille"`
}

type Group struct {
	ID       int64 `json:"id"`
	Minimum  int64 `json:"minimum"`
	Maximum  int64 `json:"maximum"`
	Weight   int64 `json:"weight"`
	Activity int64 `json:"activity"`
}

type Buff struct {
	ID     int64 `json:"id"`
	Weight int64 `json:"weight"`
	Effect int64 `json:"effect"`
}

type Activity struct {
	ID        int64  `json:"id"`
	Kind      int64  `json:"kind"`
	Parameter string `json:"parameter"`
	Count     int64  `json:"count"`
}

type Catalog struct {
	Activities        []Activity `json:"activities"`
	Schema            int        `json:"schema_version"`
	Contract          string     `json:"contract_id"`
	Targets           []Target   `json:"targets"`
	Groups            []Group    `json:"groups"`
	Buffs             []Buff     `json:"buffs"`
	TicketItem        int64      `json:"ticket_item"`
	InitialBalls      int64      `json:"initial_balls"`
	MinimumBuffs      int64      `json:"minimum_buffs"`
	MaximumBuffs      int64      `json:"maximum_buffs"`
	FriendProbability int64      `json:"friend_probability_permille"`
	FriendBalls       int64      `json:"friend_balls"`
	IncomingLimit     int64      `json:"incoming_limit"`
	MarkedMultiplier  int64      `json:"marked_multiplier"`
}

func (catalog Catalog) Validate() error {
	if catalog.Schema != 1 || catalog.Contract != ContractID || len(catalog.Targets) != 90 || len(catalog.Groups) != 5 || len(catalog.Buffs) != 6 || len(catalog.Activities) != 2 || catalog.TicketItem != 50001979 || catalog.InitialBalls != 200 || catalog.MinimumBuffs != 6 || catalog.MaximumBuffs != 9 || catalog.FriendProbability != 100 || catalog.FriendBalls != 5 || catalog.IncomingLimit != 3 || catalog.MarkedMultiplier != 2 {
		return ErrUnavailable
	}
	if catalog.Activities[0] != (Activity{ID: 1210, Kind: 1, Parameter: "0.02", Count: 2}) || catalog.Activities[1] != (Activity{ID: 1211, Kind: 2, Parameter: "5", Count: 2}) {
		return ErrUnavailable
	}
	seenTargets := map[int64]bool{}
	for _, target := range catalog.Targets {
		if target.ID <= 0 || seenTargets[target.ID] || target.Group < 1 || target.Group > 5 || target.ItemID <= 0 || target.Amount != 1 || target.Weight <= 0 || target.Weight > 10000 || target.Probability < 0 || target.Probability > combat.PermilleScale {
			return ErrUnavailable
		}
		if target.Group < 5 && target.HeroTableID <= 0 {
			return ErrUnavailable
		}
		seenTargets[target.ID] = true
	}
	seenGroups := map[int64]bool{}
	var baselineCount int64
	for _, group := range catalog.Groups {
		if group.ID < 1 || group.ID > 5 || seenGroups[group.ID] || group.Minimum < 1 || group.Maximum < group.Minimum || group.Maximum > 100 || group.Weight <= 0 {
			return ErrUnavailable
		}
		seenGroups[group.ID] = true
		if group.Activity == 0 {
			baselineCount += group.Minimum
		}
		foundTarget := false
		for _, target := range catalog.Targets {
			if target.Group == group.ID {
				foundTarget = true
			}
		}
		if !foundTarget {
			return ErrUnavailable
		}
	}
	if baselineCount != 25 {
		return ErrUnavailable
	}
	seenBuffs := map[int64]bool{}
	for _, buff := range catalog.Buffs {
		if buff.ID < 1 || buff.ID > 6 || seenBuffs[buff.ID] || buff.Weight <= 0 || buff.Weight > 10000 {
			return ErrUnavailable
		}
		seenBuffs[buff.ID] = true
	}
	if catalog.BuffEffect(ProbabilityBuff) != 20 || catalog.BuffEffect(FriendProbabilityBuff) != 100 || catalog.BuffEffect(AdditionalBallsBuff) != 50 {
		return ErrUnavailable
	}
	return nil
}

func (catalog Catalog) Target(identifier int64) (Target, bool) {
	for _, target := range catalog.Targets {
		if target.ID == identifier {
			return target, true
		}
	}
	return Target{}, false
}

func (catalog Catalog) BuffEffect(identifier int64) int64 {
	for _, buff := range catalog.Buffs {
		if buff.ID == identifier {
			return buff.Effect
		}
	}
	return 0
}

func (catalog Catalog) DrawPolicy() combat.DrawPolicy {
	length := int(catalog.InitialBalls + catalog.MaximumBuffs*catalog.BuffEffect(AdditionalBallsBuff))
	return combat.DrawPolicy{ID: DrawPolicyID, Version: 1, Streams: []combat.DrawStream{{Name: "self", Length: length, Low: 1, High: 1000}, {Name: "friend", Length: length, Low: 1, High: 1000}}}
}

type PositionedBuff struct {
	ID       int64 `json:"id"`
	Position int64 `json:"pos"`
}

type Board struct {
	Monsters []int64          `json:"monsters"`
	Buffs    []PositionedBuff `json:"buffs"`
	Marked   []int64          `json:"select_monsters"`
}

func weightedIndex(random campaign.Uniform, weights []int64) int {
	var total int64
	for _, weight := range weights {
		total += weight
	}
	draw := int64(random.Uniform(uint64(total)))
	for index, weight := range weights {
		if draw < weight {
			return index
		}
		draw -= weight
	}
	panic("validated dodgeball weights")
}

func (catalog Catalog) BuildBoard(random campaign.Uniform) (Board, error) {
	if random == nil || catalog.Validate() != nil {
		return Board{}, ErrUnavailable
	}
	board := Board{Monsters: []int64{}, Buffs: []PositionedBuff{}, Marked: []int64{}}
	for _, group := range catalog.Groups {
		if group.Activity != 0 {
			continue
		}
		targets, weights := []Target{}, []int64{}
		for _, target := range catalog.Targets {
			if target.Group == group.ID {
				targets = append(targets, target)
				weights = append(weights, target.Weight)
			}
		}
		for occurrence := int64(0); occurrence < group.Minimum; occurrence++ {
			board.Monsters = append(board.Monsters, targets[weightedIndex(random, weights)].ID)
		}
	}
	for index := len(board.Monsters) - 1; index > 0; index-- {
		other := int(random.Uniform(uint64(index + 1)))
		board.Monsters[index], board.Monsters[other] = board.Monsters[other], board.Monsters[index]
	}
	unique := []int64{}
	seen := map[int64]bool{}
	for _, identifier := range board.Monsters {
		if !seen[identifier] {
			unique = append(unique, identifier)
			seen[identifier] = true
		}
	}
	if len(unique) < 3 {
		return Board{}, ErrUnavailable
	}
	for choice := 0; choice < 3; choice++ {
		index := int(random.Uniform(uint64(len(unique))))
		board.Marked = append(board.Marked, unique[index])
		unique = append(unique[:index], unique[index+1:]...)
	}
	count := catalog.MinimumBuffs + int64(random.Uniform(uint64(catalog.MaximumBuffs-catalog.MinimumBuffs+1)))
	weights := []int64{}
	for _, buff := range catalog.Buffs {
		weights = append(weights, buff.Weight)
	}
	for occurrence := int64(0); occurrence < count; occurrence++ {
		board.Buffs = append(board.Buffs, PositionedBuff{ID: catalog.Buffs[weightedIndex(random, weights)].ID, Position: 1 + int64(random.Uniform(uint64(len(board.Monsters)+1)))})
	}
	sort.SliceStable(board.Buffs, func(left, right int) bool { return board.Buffs[left].Position < board.Buffs[right].Position })
	return board, nil
}

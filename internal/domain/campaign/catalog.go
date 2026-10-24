// Package campaign holds the pure Campaign rules (I9_CAMPAIGN_V1): the source
// catalog, node opening, the drop law, settlement and the world map projection.
// I9_CAMPAIGN_PRIVATE_POLICY_V1 marks every rule not recovered from source.
package campaign

import (
	"errors"
	"fmt"
)

const (
	ContractID = "I9_CAMPAIGN_V1"
	PolicyID   = "I9_CAMPAIGN_PRIVATE_POLICY_V1"
	MaxStar    = 3
)

// Wire campaign types (campaign_type on 112-117); campaign.lua campaign_type is the node size, not this.
const (
	Normal    int64 = 1
	Super     int64 = 2
	Challenge int64 = 24
)

var (
	ErrUnavailable = errors.New("campaign: unavailable")
	ErrInvalid     = errors.New("campaign: invalid request")
	ErrRefused     = errors.New("campaign: refused by rule")
)

type Node struct {
	ID         int64 `json:"id"`
	Type       int64 `json:"type"`
	Chapter    int64 `json:"chapter"`
	OpenLevel  int64 `json:"open_level"`
	EnergyCost int64 `json:"energy_cost"`
	DefeatCost int64 `json:"defeat_cost"`
	PartnerExp int64 `json:"partner_exp"`
	ManaGain   int64 `json:"mana_gain"`
	StarGift   int64 `json:"star_gift"`
	DailyLimit int64 `json:"daily_limit"`
	FirstBox   int64 `json:"first_box"`
	// RepeatBox is 0 where the source dropbox id has no rows (UNKNOWN: no repeat drop).
	RepeatBox     int64      `json:"repeat_box"`
	Next          []int64    `json:"next"`
	Previous      int64      `json:"previous"`
	Related       int64      `json:"related"`
	StoryPartners []int64    `json:"story_partners"`
	SweepReward   [][2]int64 `json:"sweep_reward"`
}

type Chapter struct {
	ID              int64   `json:"id"`
	NextID          int64   `json:"next_id"`
	EventType       int64   `json:"event_type"`
	EventCondition  []int64 `json:"event_condition"`
	EventBossID     int64   `json:"event_boss_id"`
	EventBattleID   int64   `json:"event_battle_id"`
	EventGift       []int64 `json:"event_gift"`
	EventEnergyNeed int64   `json:"event_energy_need"`
	EventOpenTimes  int64   `json:"event_open_times"`
	Normal          []int64 `json:"normal"`
	Super           []int64 `json:"super"`
	Challenge       []int64 `json:"challenge"`
}

// DropBox rows are [item_id, increase_rate] in source row order.
type DropBox struct {
	ID   int64      `json:"id"`
	Rows [][2]int64 `json:"rows"`
}

type StarBonus struct {
	ID      int64      `json:"id"`
	NextID  int64      `json:"next_id"`
	Type    int64      `json:"type"`
	StarNum int64      `json:"star_num"`
	Crystal int64      `json:"crystal"`
	Mana    int64      `json:"mana"`
	Items   [][2]int64 `json:"items"`
}

type VIP struct {
	Level      int64 `json:"level"`
	NumElite   int64 `json:"num_elite"`
	QuickSweep int64 `json:"quick_sweep"`
}

type Monthly struct {
	NumElite   int64 `json:"num_elite"`
	QuickSweep int64 `json:"quick_sweep"`
}

type PrivatePolicy struct {
	ResultWindowSeconds int64    `json:"result_window_seconds"`
	SweepCrystalPerCard int64    `json:"sweep_crystal_per_card"`
	Labels              []string `json:"labels"`
}

type Catalog struct {
	SchemaVersion           int           `json:"schema_version"`
	ContractID              string        `json:"contract_id"`
	PolicyID                string        `json:"policy_id"`
	FirstNormalID           int64         `json:"first_normal_id"`
	SuperFunctionID         int64         `json:"super_function_id"`
	ChallengeGateCampaignID int64         `json:"challenge_gate_campaign_id"`
	ExpMultiplier           int64         `json:"exp_multiplier"`
	SweepCardItemID         int64         `json:"sweep_card_item_id"`
	NormalSweepMax          int64         `json:"normal_sweep_max"`
	PrivatePolicy           PrivatePolicy `json:"private_policy"`
	AbsentRepeatBoxes       []int64       `json:"absent_repeat_box_campaigns"`
	Monthly                 Monthly       `json:"monthly"`
	Chapters                []Chapter     `json:"chapters"`
	Nodes                   []Node        `json:"nodes"`
	DropBoxes               []DropBox     `json:"drop_boxes"`
	StarBonus               []StarBonus   `json:"star_bonus"`
	EliteResetCosts         []int64       `json:"elite_reset_costs"`
	VIP                     []VIP         `json:"vip"`

	nodes  map[int64]int
	boxes  map[int64]int
	chains map[int64][]int64
}

// Validate checks the generation-40 profile and builds the lookups; opening
// relies on the Normal and Super chains being linear in catalog order.
func (c *Catalog) Validate() error {
	profile := c.SchemaVersion == 1 && c.ContractID == ContractID && c.PolicyID == PolicyID && c.FirstNormalID == 100001 && c.SuperFunctionID == 31 &&
		c.ChallengeGateCampaignID == 1600016 && c.ExpMultiplier == 3 && c.PrivatePolicy.ResultWindowSeconds > 0 && len(c.Chapters) == 23 && len(c.Nodes) == 728 &&
		len(c.DropBoxes) == 996 && len(c.StarBonus) == 46 && len(c.EliteResetCosts) == 330 && len(c.VIP) == 16
	if !profile {
		return fmt.Errorf("%w: catalog profile", ErrUnavailable)
	}
	c.boxes = make(map[int64]int, len(c.DropBoxes))
	for i, b := range c.DropBoxes {
		c.boxes[b.ID] = i
	}
	c.nodes = make(map[int64]int, len(c.Nodes))
	c.chains = map[int64][]int64{}
	for i, n := range c.Nodes {
		_, first := c.boxes[n.FirstBox]
		_, repeat := c.boxes[n.RepeatBox]
		if _, duplicate := c.nodes[n.ID]; duplicate || n.FirstBox != 0 && !first || n.RepeatBox != 0 && !repeat || n.EnergyCost < 0 || n.DefeatCost < 0 {
			return fmt.Errorf("%w: node %d", ErrUnavailable, n.ID)
		}
		c.nodes[n.ID] = i
		c.chains[n.Type] = append(c.chains[n.Type], n.ID)
	}
	for _, kind := range []int64{Normal, Super} {
		if err := c.linear(kind); err != nil {
			return err
		}
	}
	if c.chains[Normal][0] != c.FirstNormalID {
		return fmt.Errorf("%w: first normal node", ErrUnavailable)
	}
	for _, id := range c.chains[Super] {
		if related, ok := c.Node(c.Nodes[c.nodes[id]].Related); !ok || related.Type != Normal {
			return fmt.Errorf("%w: super node %d related", ErrUnavailable, id)
		}
	}
	for i, v := range c.VIP {
		if v.Level != int64(i) {
			return fmt.Errorf("%w: vip row %d", ErrUnavailable, i)
		}
	}
	return nil
}

func (c Catalog) linear(kind int64) error {
	chain := c.chains[kind]
	for i, id := range chain {
		next := c.Nodes[c.nodes[id]].Next
		last := i == len(chain)-1
		if last && len(next) != 0 || !last && (len(next) != 1 || next[0] != chain[i+1]) {
			return fmt.Errorf("%w: type %d chain at %d", ErrUnavailable, kind, id)
		}
	}
	return nil
}

func (c Catalog) Node(id int64) (Node, bool) {
	i, ok := c.nodes[id]
	if !ok {
		return Node{}, false
	}
	return c.Nodes[i], true
}

func (c Catalog) Box(id int64) (DropBox, bool) {
	i, ok := c.boxes[id]
	if !ok {
		return DropBox{}, false
	}
	return c.DropBoxes[i], true
}

// Chain is the node ids of one wire type in opening order.
func (c Catalog) Chain(kind int64) []int64 { return c.chains[kind] }

// Package worldboss owns the shared boss occurrence and per-player daily state.
package worldboss

import (
	"errors"
	"slices"
)

const (
	ContractID    = "I9_WORLD_BOSS_V1"
	PolicyID      = "I9_WORLD_BOSS_POLICY_V1"
	PolicyVersion = 1

	ActivityID = 1026
	OpenLevel  = 48

	FirstBossID    = 10011
	LastBossID     = 10015
	DamageCap      = 10000000
	AttemptsPerDay = 5
	AttemptsPerBuy = 5
	SweepsPerDay   = 1

	ClosedStartSecond   = 79080
	SecondsPerDay       = 86400
	CourageUpdateSecond = 79200

	DailyCourageBase          = 6666668
	DailyCouragePerLevel90    = 100000
	DailyCouragePerChallenger = 10000
)

var (
	ErrInvalid     = errors.New("world boss invalid request")
	ErrRefused     = errors.New("world boss refused")
	ErrUnavailable = errors.New("world boss unavailable")
)

type Boss struct {
	ID           int64   `json:"id"`
	CampaignType int64   `json:"campaign_type"`
	Name         string  `json:"name"`
	Title        string  `json:"title"`
	Description  string  `json:"description"`
	FightID      int64   `json:"fight_id"`
	MonsterID    int64   `json:"monster_id"`
	NeedBrave    int64   `json:"need_brave"`
	DefeatStone  int64   `json:"defeat_stone"`
	PreviousID   int64   `json:"previous_id"`
	NextID       int64   `json:"next_id"`
	OpenExplain  string  `json:"open_explain"`
	Skills       []int64 `json:"skills"`
}

type RankReward struct {
	Range   int64 `json:"range"`
	Diamond int64 `json:"diamond"`
	Mana    int64 `json:"mana"`
	Stone   int64 `json:"stone"`
}

type Mail struct {
	Sender string `json:"sender"`
	Title  string `json:"title"`
	Text   string `json:"text"`
}

type Texts struct {
	Title      string   `json:"title"`
	Rules      string   `json:"rules"`
	OpenTip    string   `json:"open_tip"`
	BuyAlert   string   `json:"buy_alert"`
	Sweep      string   `json:"sweep"`
	NoHero     string   `json:"no_hero"`
	KeepRank   string   `json:"keep_rank"`
	BraveState string   `json:"brave_state"`
	RankReward string   `json:"rank_reward"`
	RankTitles []string `json:"rank_titles"`
}

type Catalog struct {
	Schema        int          `json:"schema_version"`
	Contract      string       `json:"contract_id"`
	PolicyID      string       `json:"policy_id"`
	PolicyVersion int          `json:"policy_version"`
	ActivityID    int64        `json:"activity_id"`
	OpenLevel     int64        `json:"open_level"`
	Attempts      int64        `json:"attempts"`
	WindowStart   int64        `json:"window_start_seconds"`
	WindowStop    int64        `json:"window_stop_seconds"`
	Bosses        []Boss       `json:"bosses"`
	RankRewards   []RankReward `json:"rank_rewards"`
	BuyCosts      []int64      `json:"buy_costs"`
	BuyCaps       []int64      `json:"buy_caps"`
	Mail          Mail         `json:"mail"`
	Texts         Texts        `json:"texts"`
}

func (c Catalog) Validate() error {
	if c.Schema != 1 || c.Contract != ContractID || c.PolicyID != PolicyID || c.PolicyVersion != PolicyVersion {
		return ErrUnavailable
	}
	if c.ActivityID != ActivityID || c.OpenLevel != OpenLevel || c.Attempts != AttemptsPerDay || c.WindowStart != 0 || c.WindowStop != ClosedStartSecond {
		return ErrUnavailable
	}
	if len(c.Bosses) != 5 || len(c.RankRewards) != 25 || len(c.Texts.RankTitles) != 5 || c.Mail.Sender == "" || c.Mail.Title == "" || c.Mail.Text == "" {
		return ErrUnavailable
	}
	if len(c.BuyCaps) != 16 || len(c.BuyCosts) < int(c.BuyCaps[len(c.BuyCaps)-1]) {
		return ErrUnavailable
	}
	for level, cap := range c.BuyCaps {
		if cap < 1 || level > 0 && cap < c.BuyCaps[level-1] {
			return ErrUnavailable
		}
	}
	for index, boss := range c.Bosses {
		expected := int64(FirstBossID + index)
		if boss.ID != expected || boss.CampaignType != 8 || boss.NeedBrave <= 0 || boss.FightID <= 0 || boss.MonsterID <= 0 || boss.DefeatStone <= 0 || len(boss.Skills) != 4 {
			return ErrUnavailable
		}
		previous, next := int64(0), int64(0)
		if index > 0 {
			previous = expected - 1
		}
		if index < len(c.Bosses)-1 {
			next = expected + 1
		}
		if boss.PreviousID != previous || boss.NextID != next {
			return ErrUnavailable
		}
	}
	lastRange := int64(0)
	for _, reward := range c.RankRewards {
		if reward.Range <= lastRange {
			return ErrUnavailable
		}
		lastRange = reward.Range
	}
	return nil
}

func (c Catalog) Boss(id int64) (Boss, bool) {
	for _, boss := range c.Bosses {
		if boss.ID == id {
			return boss, true
		}
	}
	return Boss{}, false
}

// Reward returns the first source bucket covering rank; rank 0 and ranks above
// the last bucket earn nothing.
func (c Catalog) Reward(rank int64) RankReward {
	if rank <= 0 {
		return RankReward{}
	}
	for _, reward := range c.RankRewards {
		if rank <= reward.Range {
			return reward
		}
	}
	return RankReward{}
}

// BuyCost is the 1-based refresh_cost.buy_boss_cost entry; zero means the
// ladder refuses that purchase.
func (c Catalog) BuyCost(n int64) (int64, bool) {
	if n < 1 || n > int64(len(c.BuyCosts)) {
		return 0, false
	}
	cost := c.BuyCosts[n-1]
	return cost, cost > 0
}

// BuyCap is vip.num_boss for a level, the day's purchase cap.
func (c Catalog) BuyCap(vip int64) int64 {
	if vip < 0 || vip >= int64(len(c.BuyCaps)) {
		return 0
	}
	return c.BuyCaps[vip]
}

// ClampDamage bounds one reported attempt to the damage cap and to the courage
// still needed for the current boss.
func ClampDamage(courage, needBrave, reported int64) int64 {
	if reported <= 0 || courage >= needBrave {
		return 0
	}
	remaining := needBrave - courage
	if remaining > DamageCap {
		remaining = DamageCap
	}
	if reported > remaining {
		return remaining
	}
	return reported
}

// DailyCourage is the 22:00 GMT+8 increment from D364.
func DailyCourage(level90Players, challengers int64) int64 {
	if level90Players < 0 || challengers < 0 {
		return 0
	}
	return DailyCourageBase + DailyCouragePerLevel90*level90Players + DailyCouragePerChallenger*challengers
}

// OrderRank sorts by total hurt descending and ties by the earlier first hit.
func OrderRank(entries []RankEntry) []RankEntry {
	out := slices.Clone(entries)
	slices.SortFunc(out, func(left, right RankEntry) int {
		if left.TotalHurt != right.TotalHurt {
			if left.TotalHurt > right.TotalHurt {
				return -1
			}
			return 1
		}
		if left.FirstHurtAt != right.FirstHurtAt {
			if left.FirstHurtAt < right.FirstHurtAt {
				return -1
			}
			return 1
		}
		if left.PlayerID < right.PlayerID {
			return -1
		}
		if left.PlayerID > right.PlayerID {
			return 1
		}
		return 0
	})
	return out
}

func RankOf(entries []RankEntry, playerID int64) (int64, int64) {
	for index, entry := range OrderRank(entries) {
		if entry.PlayerID == playerID {
			return int64(index + 1), entry.TotalHurt
		}
	}
	return 0, 0
}

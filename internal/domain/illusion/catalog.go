// Package illusion owns the shared Fantasy boss occurrence, daily chances and
// the frozen team composition rules.
package illusion

import (
	"errors"
	"slices"
)

const (
	ContractID    = "I9_ILLUSION_V1"
	PolicyID      = "I9_ILLUSION_POLICY_V1"
	PolicyVersion = 1

	OpenLevel      = 65
	FreeChances    = 5
	ChancesPerBuy  = 5
	DamageCap      = 12000000
	DefaultPoolHP  = 120000000
	OpenSecond     = 28800
	CloseSecond    = 79080
	SettleSecond   = 79200
	SecondsPerDay  = 86400
	CycleDays      = 2
	RestDays       = 1
	TeamSeats      = 3
	MasterHeroes   = 1
	MateHeroes     = 2
	TeamHeroLimit  = 5
	TeamPowerLimit = 30
	TeamLevelBand  = 5

	LockPlayerRank     uint16 = 605
	LockOccurrenceRank uint16 = 606
)

const (
	FirstCampaignID = 100001
	LastCampaignID  = 100012
)

var (
	ErrInvalid     = errors.New("illusion invalid request")
	ErrRefused     = errors.New("illusion refused")
	ErrUnavailable = errors.New("illusion unavailable")
)

type Campaign struct {
	ID           int64   `json:"id"`
	CampaignType int64   `json:"campaign_type"`
	Name         string  `json:"name"`
	Description  string  `json:"description"`
	Skills       []int64 `json:"skills"`
	PreviousID   int64   `json:"previous_id"`
	NextID       int64   `json:"next_id"`
	FightID      int64   `json:"fight_id"`
	ModelID      int64   `json:"model_id"`
	MonsterID    int64   `json:"monster_id"`
	Hidden       bool    `json:"hidden"`
	ModelBlack   string  `json:"model_black"`
	BossNameText string  `json:"boss_name_text"`
}

type PersonReward struct {
	ID       int64   `json:"id"`
	Range    int64   `json:"range"`
	Coin     int64   `json:"coin"`
	ItemIDs  []int64 `json:"item_ids"`
	ItemNums []int64 `json:"item_nums"`
}

type CommunityReward struct {
	ID         int64 `json:"id"`
	Range      int64 `json:"range"`
	Coin       int64 `json:"coin"`
	PersonCoin int64 `json:"person_coin"`
}

type Catalog struct {
	Schema                  int               `json:"schema_version"`
	Contract                string            `json:"contract_id"`
	PolicyID                string            `json:"policy_id"`
	PolicyVersion           int               `json:"policy_version"`
	OpenLevel               int64             `json:"open_level"`
	FreeChances             int64             `json:"free_chances"`
	ChancesPerBuy           int64             `json:"chances_per_buy"`
	DamageCap               int64             `json:"damage_cap"`
	OpenSecond              int64             `json:"open_second"`
	CloseSecond             int64             `json:"close_second"`
	SettleSecond            int64             `json:"settle_second"`
	TeamHeroLimit           int64             `json:"team_hero_limit"`
	TeamPowerLimit          int64             `json:"team_power_limit"`
	RewardPercentHundredths int64             `json:"reward_percent_hundredths"`
	Campaigns               []Campaign        `json:"campaigns"`
	PersonRewards           []PersonReward    `json:"person_rewards"`
	CommunityRewards        []CommunityReward `json:"community_rewards"`
	BuyCosts                []int64           `json:"buy_costs"`
	BuyCaps                 []int64           `json:"buy_caps"`
}

func (c Catalog) Validate() error {
	if c.Schema != 1 || c.Contract != ContractID || c.PolicyID != PolicyID || c.PolicyVersion != PolicyVersion {
		return ErrUnavailable
	}
	if c.OpenLevel != OpenLevel || c.FreeChances != FreeChances || c.ChancesPerBuy != ChancesPerBuy || c.DamageCap != DamageCap {
		return ErrUnavailable
	}
	if c.OpenSecond != OpenSecond || c.CloseSecond != CloseSecond || c.SettleSecond != SettleSecond {
		return ErrUnavailable
	}
	if c.TeamHeroLimit != TeamHeroLimit || c.TeamPowerLimit != TeamPowerLimit || c.RewardPercentHundredths != 20 {
		return ErrUnavailable
	}
	if len(c.Campaigns) != int(LastCampaignID-FirstCampaignID+1) || len(c.PersonRewards) != 30 || len(c.CommunityRewards) != 15 || len(c.BuyCaps) != 16 {
		return ErrUnavailable
	}
	for index, campaign := range c.Campaigns {
		if campaign.ID != int64(FirstCampaignID+index) || campaign.CampaignType != 8 || campaign.Hidden || len(campaign.Skills) != 4 || campaign.FightID <= 0 || campaign.MonsterID <= 0 || campaign.ModelID <= 0 {
			return ErrUnavailable
		}
	}
	if c.NextCampaignID(FirstCampaignID) != FirstCampaignID+1 || c.NextCampaignID(LastCampaignID-1) != FirstCampaignID || c.NextCampaignID(LastCampaignID) != FirstCampaignID {
		return ErrUnavailable
	}
	lastRange := int64(0)
	for _, reward := range c.PersonRewards {
		if reward.Range <= lastRange || reward.Coin < 0 || len(reward.ItemIDs) != len(reward.ItemNums) {
			return ErrUnavailable
		}
		lastRange = reward.Range
	}
	lastRange = 0
	for _, reward := range c.CommunityRewards {
		if reward.Range <= lastRange || reward.Coin < 0 || reward.PersonCoin < 0 {
			return ErrUnavailable
		}
		lastRange = reward.Range
	}
	if len(c.BuyCosts) < int(c.BuyCaps[len(c.BuyCaps)-1]) || c.BuyCaps[0] != 0 || c.BuyCaps[1] != 0 || c.BuyCaps[2] != 0 || c.BuyCaps[3] != 1 {
		return ErrUnavailable
	}
	for level := 1; level < len(c.BuyCaps); level++ {
		if c.BuyCaps[level] < c.BuyCaps[level-1] {
			return ErrUnavailable
		}
	}
	return nil
}

func (c Catalog) Campaign(id int64) (Campaign, bool) {
	for _, campaign := range c.Campaigns {
		if campaign.ID == id {
			return campaign, true
		}
	}
	return Campaign{}, false
}

// NextCampaignID follows the source chain and restarts the cycle at the head so
// a terminal row is never exposed as the current boss.
func (c Catalog) NextCampaignID(id int64) int64 {
	campaign, ok := c.Campaign(id)
	if !ok {
		return 0
	}
	if campaign.NextID == 0 {
		return FirstCampaignID
	}
	if _, ok = c.Campaign(campaign.NextID); !ok {
		return 0
	}
	return campaign.NextID
}

// PersonReward returns the first source bucket covering rank; rank 0 and ranks
// above the last bucket earn nothing.
func (c Catalog) PersonReward(rank int64) PersonReward {
	if rank <= 0 {
		return PersonReward{}
	}
	for _, reward := range c.PersonRewards {
		if rank <= reward.Range {
			return reward
		}
	}
	return PersonReward{}
}

func (c Catalog) CommunityReward(rank int64) CommunityReward {
	if rank <= 0 {
		return CommunityReward{}
	}
	for _, reward := range c.CommunityRewards {
		if rank <= reward.Range {
			return reward
		}
	}
	return CommunityReward{}
}

// BuyCost is the 1-based refresh_cost.buy_paradise_cost entry; zero means the
// ladder refuses that purchase.
func (c Catalog) BuyCost(n int64) (int64, bool) {
	if n < 1 || n > int64(len(c.BuyCosts)) {
		return 0, false
	}
	cost := c.BuyCosts[n-1]
	return cost, cost > 0
}

// BuyCap is vip.paradise_buy_num for a level, the day's purchase cap.
func (c Catalog) BuyCap(vip int64) int64 {
	if vip < 0 || vip >= int64(len(c.BuyCaps)) {
		return 0
	}
	return c.BuyCaps[vip]
}

// ClampDamage bounds one reported hit to the damage cap and to the pool left.
func ClampDamage(poolHP, poolHurt, reported int64) int64 {
	if reported <= 0 || poolHP <= poolHurt {
		return 0
	}
	remaining := poolHP - poolHurt
	if remaining > DamageCap {
		remaining = DamageCap
	}
	if reported > remaining {
		return remaining
	}
	return reported
}

// OrderRank sorts by best hurt descending and ties by the shorter cost time.
func OrderRank(entries []Result) []Result {
	out := slices.Clone(entries)
	slices.SortFunc(out, func(left, right Result) int {
		if left.Hurt != right.Hurt {
			if left.Hurt > right.Hurt {
				return -1
			}
			return 1
		}
		if left.CostTime != right.CostTime {
			if left.CostTime < right.CostTime {
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

func RankOf(entries []Result, playerID int64) (int64, int64) {
	for index, entry := range OrderRank(entries) {
		if entry.PlayerID == playerID {
			return int64(index + 1), entry.Hurt
		}
	}
	return 0, 0
}

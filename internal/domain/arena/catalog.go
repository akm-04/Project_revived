// Package arena holds the pure Arena (Region Arena, MIDs 768-779) rules: the
// source catalog, the 45-day GMT+8 season calendar, stars and protections,
// Lord points, defense streaks, matching, missions, exchanges and season
// settlement. C5D_ARENA_PRIVATE_POLICY_V1 marks every rule not recovered from
// source.
package arena

import (
	"errors"
	"fmt"
	"time"
)

const (
	ContractID = "C5D_ARENA_SEASON_MODE_V1"
	PolicyID   = "C5D_ARENA_PRIVATE_POLICY_V1"
	// Engine CampaignType.REGION_ARENA and MapBattleID.ARENA.
	CampaignType int64 = 45
	BattleID     int64 = 111001
	// Registered resolver transform: season awards, then region balancing.
	Transform = "REGION_ARENA_SEASON_AWARDS_V1"
	TeamSize  = 5
	Missions  = 3
	// C5D policy: retained records per player and the abandon window of a started match.
	RecordsMax     = 20
	AbandonSeconds = 600
)

const (
	ExchangeStar   int64 = 1
	ExchangeAwaken int64 = 2
	ExchangeSummon int64 = 3
)

const (
	MissionKills   int64 = 1
	MissionDamage  int64 = 2
	MissionStreak  int64 = 3
	MissionWins    int64 = 4
	maxNormalStars int64 = 5
	maxSuperStars  int64 = 8
)

var (
	ErrUnavailable = errors.New("arena: unavailable")
	ErrConflict    = errors.New("arena: conflicting state")
	ErrInvalid     = errors.New("arena: invalid request")
	ErrRefused     = errors.New("arena: refused by rule")
	ErrClosed      = errors.New("arena: season closed")
)

type Level struct {
	Level     int64  `json:"level"`
	Star      int64  `json:"star"`
	LevelStar int64  `json:"level_star"`
	Name      string `json:"name"`
}

type Reward struct {
	Level      int64      `json:"level"`
	RegionCoin int64      `json:"region_coin"`
	Mana       int64      `json:"mana"`
	Items      [][2]int64 `json:"items"`
	FrameID    int64      `json:"frame_id"`
	SkinID     int64      `json:"skin_id"`
}

type MissionRule struct {
	MissionID int64 `json:"mission_id"`
	Kind      int64 `json:"kind"`
	Target    int64 `json:"target"`
	KingCoin  int64 `json:"king_coin"`
	Weight    int64 `json:"weight"`
}

type Exchange struct {
	ExchangeType int64   `json:"exchange_type"`
	Costs        []int64 `json:"costs"`
}

type Catalog struct {
	SchemaVersion         int               `json:"schema_version"`
	ContractID            string            `json:"contract_id"`
	PolicyID              string            `json:"policy_id"`
	FunctionID            int64             `json:"function_id"`
	RequiredLevel         int64             `json:"required_level"`
	RequiredHeroes        int64             `json:"required_heroes"`
	SeasonAnchor          string            `json:"season_anchor"`
	SeasonDays            int64             `json:"season_days"`
	SeasonOpenSeconds     int64             `json:"season_open_seconds"`
	SeasonCloseSeconds    int64             `json:"season_close_seconds"`
	Levels                []Level           `json:"levels"`
	Rewards               []Reward          `json:"rewards"`
	ChampionItem          int64             `json:"champion_item"`
	UpgradeProtect        int64             `json:"upgrade_protect"`
	FailProtect           int64             `json:"fail_protect"`
	StreakBonusBelowLevel int64             `json:"streak_bonus_below_level"`
	StreakBonusAfter      int64             `json:"streak_bonus_after"`
	DailyLimit            int64             `json:"daily_limit"`
	DailyWinCoin          int64             `json:"daily_win_coin"`
	DailyLossCoin         int64             `json:"daily_loss_coin"`
	PointBase             int64             `json:"point_base"`
	PointLimit            int64             `json:"point_limit"`
	PointHundredths       [2]int64          `json:"point_hundredths"`
	MatchHundredths       [3]int64          `json:"match_hundredths"`
	HeroLevel             int64             `json:"hero_level"`
	HeroGrade             int64             `json:"hero_grade"`
	MissionRefillSeconds  int64             `json:"mission_refill_seconds"`
	Missions              []MissionRule     `json:"missions"`
	Exchanges             []Exchange        `json:"exchanges"`
	Mail                  map[string]string `json:"mail"`
}

func (c Catalog) Validate() error {
	_, err := time.Parse("2006-01-02", c.SeasonAnchor)
	profile := err == nil && c.SchemaVersion == 1 && c.ContractID == ContractID && c.PolicyID == PolicyID && c.FunctionID == 37 && c.RequiredLevel == 60 &&
		c.RequiredHeroes == 5 && c.SeasonAnchor == "2022-10-28" && c.SeasonDays == 45 && c.SeasonOpenSeconds == 18000 && c.SeasonCloseSeconds == 0 &&
		len(c.Levels) == 26 && len(c.Rewards) == 26 && c.ChampionItem == 110006001 && c.UpgradeProtect == 90 && c.FailProtect == 10 &&
		c.StreakBonusBelowLevel == 20 && c.StreakBonusAfter == 4 && c.DailyLimit == 10 && c.DailyWinCoin == 50 && c.DailyLossCoin == 25 &&
		c.PointBase == 10 && c.PointLimit == 50 && c.PointHundredths == [2]int64{10, 1} && c.MatchHundredths == [3]int64{80, 120, 10} &&
		c.HeroLevel == 100 && c.HeroGrade == 16 && c.MissionRefillSeconds == 72000 && len(c.Missions) >= Missions && len(c.Exchanges) == 3
	for _, key := range []string{"REGION_ARENA_MAIL_TITLE", "REGION_ARENA_MAIL_TEXT", "REGION_ARENA_MAIL_SENDER"} {
		profile = profile && c.Mail[key] != ""
	}
	if !profile {
		return fmt.Errorf("%w: catalog profile", ErrUnavailable)
	}
	var previous int64
	for i, l := range c.Levels {
		if l.Level != int64(i+1) || l.Star <= previous {
			return fmt.Errorf("%w: level %d", ErrUnavailable, i+1)
		}
		previous = l.Star
	}
	for _, r := range c.Rewards {
		if r.Level < 1 || r.Level > int64(len(c.Levels)) || r.RegionCoin < 0 || r.Mana < 0 {
			return fmt.Errorf("%w: reward level %d", ErrUnavailable, r.Level)
		}
	}
	for i, e := range c.Exchanges {
		if e.ExchangeType != int64(i+1) || len(e.Costs) == 0 {
			return fmt.Errorf("%w: exchange %d", ErrUnavailable, i+1)
		}
	}
	for _, m := range c.Missions {
		if m.Kind < MissionKills || m.Kind > MissionWins || m.Target <= 0 || m.KingCoin <= 0 || m.Weight <= 0 {
			return fmt.Errorf("%w: mission %d", ErrUnavailable, m.MissionID)
		}
	}
	return nil
}

// MaxStars is the top of region_arena_level (Challenger).
func (c Catalog) MaxStars() int64 { return c.Levels[len(c.Levels)-1].Star }

func (c Catalog) Challenger(star int64) bool { return star >= c.MaxStars() }

// LevelOf follows RegionArenaLevelTable: s <= star[1] is level 1 and
// star[L-1] < s <= star[L] is level L.
func (c Catalog) LevelOf(star int64) int64 {
	for _, l := range c.Levels {
		if star <= l.Star {
			return l.Level
		}
	}
	return c.Levels[len(c.Levels)-1].Level
}

func (c Catalog) LevelName(star int64) string { return c.Levels[c.LevelOf(star)-1].Name }

func (c Catalog) RewardFor(level int64) (Reward, bool) {
	for _, r := range c.Rewards {
		if r.Level == level {
			return r, true
		}
	}
	return Reward{}, false
}

func (c Catalog) Mission(id int64) (MissionRule, bool) {
	for _, m := range c.Missions {
		if m.MissionID == id {
			return m, true
		}
	}
	return MissionRule{}, false
}

// ExchangeCost is region_exchange.cost for the next exchange of the type,
// clamped to the last entry (RegionArenaWindow.updateKingCoin).
func (c Catalog) ExchangeCost(exchangeType, times int64) (int64, bool) {
	if exchangeType < ExchangeStar || exchangeType > ExchangeSummon || times < 0 {
		return 0, false
	}
	costs := c.Exchanges[exchangeType-1].Costs
	return costs[min(times, int64(len(costs))-1)], true
}

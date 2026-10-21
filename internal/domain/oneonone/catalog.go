// Package oneonone holds the pure 1 on 1 (Peak, revised "legend") rules: the
// source catalog, the GMT+8 calendar, groups and standings, Elo points,
// matches, promotion and settlement. C5C_ONE_ON_ONE_PRIVATE_POLICY_V1 marks
// every rule not recovered from source.
package oneonone

import (
	"errors"
	"fmt"
	"math"
)

const (
	ContractID = "C5C_ONE_ON_ONE_MODE_V1"
	PolicyID   = "C5C_ONE_ON_ONE_PRIVATE_POLICY_V1"
	// Engine CampaignType.SUPER_ARENA and battle.lua 114001 (map "dn").
	CampaignType int64 = 65
	BattleID     int64 = 114001
	// Registered resolver transform: one round as team groups.
	Transform = "SUPER_ARENA_ROUND_V1"
	TeamSize  = 5
)

const (
	LevelMaster  int64 = 1
	LevelSenior  int64 = 2
	LevelJunior1 int64 = 3
	LevelJunior2 int64 = 4
	LevelJunior3 int64 = 5
)

const (
	ModeNormal    int64 = 1
	ModePromotion int64 = 2
)

var (
	ErrUnavailable = errors.New("oneonone: unavailable")
	ErrConflict    = errors.New("oneonone: conflicting state")
	ErrInvalid     = errors.New("oneonone: invalid request")
	ErrRefused     = errors.New("oneonone: refused by rule")
	// ErrClosedHours is answered in-band as source message 30002.
	ErrClosedHours = errors.New("oneonone: outside 08:00-22:00")
)

type Level struct {
	Level             int64 `json:"level"`
	RankType          int64 `json:"rank_type"`
	Bound             int64 `json:"bound"`
	Teams             int64 `json:"teams"`
	Hidden            int64 `json:"hidden"`
	CooldownSeconds   int64 `json:"cooldown_seconds"`
	PromotionEntrants int64 `json:"promotion_entrants"`
	PromotionPool     int64 `json:"promotion_pool"`
}

type Reward struct {
	ID      int64      `json:"id"`
	Range   int64      `json:"range"`
	Crystal int64      `json:"crystal"`
	Mana    int64      `json:"mana"`
	TopCoin int64      `json:"top_coin"`
	Items   [][2]int64 `json:"items"`
	FrameID int64      `json:"frame_id"`
}

type VIP struct {
	Level     int64 `json:"level"`
	Purchases int64 `json:"purchases"`
	Reset     int64 `json:"reset"`
}

type Title struct {
	TitleID int64 `json:"title_id"`
	First   int64 `json:"first"`
	Last    int64 `json:"last"`
	Seconds int64 `json:"seconds"`
}

type WeekTime struct {
	Weekday int64 `json:"weekday"`
	Seconds int64 `json:"seconds"`
}

type Catalog struct {
	SchemaVersion            int               `json:"schema_version"`
	ContractID               string            `json:"contract_id"`
	PolicyID                 string            `json:"policy_id"`
	FunctionID               int64             `json:"function_id"`
	RequiredLevel            int64             `json:"required_level"`
	RequiredHeroes           int64             `json:"required_heroes"`
	FreeTries                int64             `json:"free_tries"`
	OpenSeconds              int64             `json:"open_seconds"`
	CloseSeconds             int64             `json:"close_seconds"`
	SettlementWeekdays       []int64           `json:"settlement_weekdays"`
	SettlementSeconds        int64             `json:"settlement_seconds"`
	PromotionStart           WeekTime          `json:"promotion_start"`
	PromotionEnd             WeekTime          `json:"promotion_end"`
	PromotionCooldownSeconds int64             `json:"promotion_cooldown_seconds"`
	PromotionWins            int64             `json:"promotion_wins"`
	PromotionChances         int64             `json:"promotion_chances"`
	EloDivisor               int64             `json:"elo_divisor"`
	EloWin                   int64             `json:"elo_win"`
	EloBase                  int64             `json:"elo_base"`
	EloK                     int64             `json:"elo_k"`
	PointsFloor              int64             `json:"points_floor"`
	EntryPoints              int64             `json:"entry_points"`
	SplitBound               int64             `json:"split_bound"`
	MatchHundredths          [4]int64          `json:"match_hundredths"`
	MatchNewRank             int64             `json:"match_new_rank"`
	MatchNewHundredths       [4]int64          `json:"match_new_hundredths"`
	Candidates               int64             `json:"candidates"`
	RecordsMax               int64             `json:"records_max"`
	ResetCost                int64             `json:"reset_cost"`
	Titles                   []Title           `json:"titles"`
	Mail                     map[string]string `json:"mail"`
	OpeningMessage           string            `json:"opening_message"`
	Levels                   []Level           `json:"levels"`
	Rewards                  []Reward          `json:"rewards"`
	VIP                      []VIP             `json:"vip"`
	BuyCosts                 []int64           `json:"buy_costs"`
}

func (c Catalog) Validate() error {
	profile := c.SchemaVersion == 1 && c.ContractID == ContractID && c.PolicyID == PolicyID && c.FunctionID == 16 && c.RequiredLevel == 55 && c.RequiredHeroes == 15 &&
		c.FreeTries == 10 && c.OpenSeconds == 28800 && c.CloseSeconds == 79200 && len(c.SettlementWeekdays) == 2 && c.SettlementSeconds == 79200 &&
		c.PromotionStart == WeekTime{5, 75600} && c.PromotionEnd == WeekTime{6, 75600} && c.PromotionCooldownSeconds == 3600 && c.PromotionWins == 2 && c.PromotionChances == 3 &&
		c.EloDivisor == 400 && c.EloWin == 1 && c.EloBase == 10 && c.EloK == 20 && c.PointsFloor == 3000 && c.EntryPoints == 4300 && c.SplitBound == 5000 &&
		c.MatchHundredths == [4]int64{30, 50, 98, 100} && c.MatchNewRank == 200 && c.MatchNewHundredths == [4]int64{50, 75, 95, 100} && c.Candidates == 3 &&
		c.RecordsMax == 20 && c.ResetCost == 50 && len(c.Titles) == 4 && len(c.Levels) == 5 && len(c.Rewards) == 30 && len(c.VIP) == 16 && len(c.BuyCosts) > 0
	for _, key := range []string{"LEGEND_MAIL_TITLE", "LEGEND_MAIL_TEXT", "LEGEND_MAIL_SENDER", "LEGEND_KUAFU_MAIL_TITLE", "LEGEND_KUAFU_MAIL_TEXT", "LEGEND_KUAFU_MAIL_SENDER"} {
		profile = profile && c.Mail[key] != ""
	}
	if !profile {
		return fmt.Errorf("%w: catalog profile", ErrUnavailable)
	}
	for i, l := range c.Levels {
		if l.Level != int64(i+1) || l.Teams < 1 || l.Teams > 7 || l.Hidden < 0 || l.Hidden >= l.Teams || l.CooldownSeconds < 0 {
			return fmt.Errorf("%w: level %d", ErrUnavailable, i+1)
		}
	}
	if c.Levels[0].Bound != 500 || c.Levels[1].Bound != c.SplitBound || c.Levels[2].Bound <= c.Levels[3].Bound {
		return fmt.Errorf("%w: level bounds", ErrUnavailable)
	}
	var previous int64
	for i, r := range c.Rewards {
		if r.ID != int64(i+1) || r.Range <= previous || r.Crystal < 0 || r.Mana < 0 || r.TopCoin < 0 {
			return fmt.Errorf("%w: reward row %d", ErrUnavailable, i+1)
		}
		previous = r.Range
	}
	for i, v := range c.VIP {
		if v.Level != int64(i) || v.Purchases < 0 || v.Reset < 0 || v.Reset > 1 {
			return fmt.Errorf("%w: vip row %d", ErrUnavailable, i)
		}
	}
	return nil
}

// Group folds the three Junior levels into one competition group.
func Group(level int64) int64 {
	return min(level, LevelJunior1)
}

func (c Catalog) Level(level int64) Level {
	return c.Levels[level-1]
}

func (c Catalog) MasterSlots() int64 { return c.Levels[0].Bound }

// JuniorLevel follows points: Junior 1 and Junior 2 start at their rank_bound.
func (c Catalog) JuniorLevel(points int64) int64 {
	if points >= c.Levels[LevelJunior1-1].Bound {
		return LevelJunior1
	}
	if points >= c.Levels[LevelJunior2-1].Bound {
		return LevelJunior2
	}
	return LevelJunior3
}

// RewardFor is the legend_reward row whose range covers the server rank.
func (c Catalog) RewardFor(serverRank int64) (Reward, bool) {
	var lower int64
	for _, r := range c.Rewards {
		if serverRank > lower && serverRank <= r.Range {
			return r, true
		}
		lower = r.Range
	}
	return Reward{}, false
}

// TitleFor is the title_system row whose condition covers the global rank.
func (c Catalog) TitleFor(globalRank int64) (Title, bool) {
	for _, t := range c.Titles {
		if globalRank >= t.First && globalRank <= t.Last {
			return t, true
		}
	}
	return Title{}, false
}

func (c Catalog) Privilege(level int64) VIP {
	if level < 0 || level >= int64(len(c.VIP)) {
		return VIP{}
	}
	return c.VIP[level]
}

// BuyCost is refresh_cost.buy_top_cost for the n-th purchase of the day.
func (c Catalog) BuyCost(n int64) int64 {
	if n < 1 {
		return 0
	}
	return c.BuyCosts[min(n, int64(len(c.BuyCosts)))-1]
}

// Gain is the Elo transfer from loser to winner with misc legend_elo1..4 read
// as divisor, win score, base and K (STRONG_INFERENCE, C5C policy).
func (c Catalog) Gain(winnerPoints, loserPoints int64) int64 {
	expected := 1 / (1 + math.Pow(float64(c.EloBase), float64(loserPoints-winnerPoints)/float64(c.EloDivisor)))
	return int64(math.Round(float64(c.EloK) * (float64(c.EloWin) - expected)))
}

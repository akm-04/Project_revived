// Package topfloor holds the pure Top Floor rules: the source catalog, the
// GMT+8 calendar, ladder occupants, admission, opponent bands, settlement and
// rewards. C5B_TOP_FLOOR_PRIVATE_POLICY_V1 marks every rule not recovered from source.
package topfloor

import (
	"errors"
	"fmt"
)

const (
	ContractID = "C5B_TOP_FLOOR_MODE_V1"
	PolicyID   = "C5B_TOP_FLOOR_PRIVATE_POLICY_V1"
	RobotTeams = 10325
	// Source client classifies table_id <= 25000 as a robot.
	RobotTableLimit = 25000
	DefenseSlots    = 5
)

var (
	ErrUnavailable = errors.New("topfloor: unavailable")
	ErrConflict    = errors.New("topfloor: conflicting state")
	ErrInvalid     = errors.New("topfloor: invalid request")
	ErrRefused     = errors.New("topfloor: refused by rule")
)

type Reward struct {
	ID             int64      `json:"id"`
	Range          int64      `json:"range"`
	DailyCrystal   int64      `json:"daily_crystal"`
	DailyMana      int64      `json:"daily_mana"`
	DailyArenaCoin int64      `json:"daily_arena_coin"`
	Items          [][2]int64 `json:"items"`
	FrameID        int64      `json:"frame_id"`
	// Source rank_reward_diamond_new in ten-thousandths, exact.
	BestRankRate int64 `json:"best_rank_rate"`
}

type VIP struct {
	Level     int64 `json:"level"`
	Purchases int64 `json:"purchases"`
	Reset     int64 `json:"reset"`
}

type RobotTeam struct {
	Level  int64   `json:"level"`
	Heroes []int64 `json:"heroes"`
}

type RobotHero struct {
	ID         int64   `json:"id"`
	Level      int64   `json:"level"`
	PartnerID  int64   `json:"partner_id"`
	Quality    int64   `json:"quality"`
	Star       int64   `json:"star"`
	EquipFlags []int64 `json:"equip_flags"`
}

type Catalog struct {
	SchemaVersion    int         `json:"schema_version"`
	ContractID       string      `json:"contract_id"`
	PolicyID         string      `json:"policy_id"`
	FunctionID       int64       `json:"function_id"`
	RequiredLevel    int64       `json:"required_level"`
	FreeTickets      int64       `json:"free_tickets"`
	BuyRestore       int64       `json:"buy_restore"`
	CooldownSeconds  int64       `json:"cooldown_seconds"`
	ResetCost        int64       `json:"reset_cost"`
	MatchHundredths  [3]int64    `json:"match_hundredths"`
	CutoffSeconds    int64       `json:"cutoff_seconds"`
	FreezeEndSeconds int64       `json:"freeze_end_seconds"`
	RecordsMax       int64       `json:"records_max"`
	MailTitle        string      `json:"mail_title"`
	MailText         string      `json:"mail_text"`
	MailSender       string      `json:"mail_sender"`
	RobotAvatarID    int64       `json:"robot_avatar_id"`
	RobotFrameID     int64       `json:"robot_frame_id"`
	Rewards          []Reward    `json:"rewards"`
	VIP              []VIP       `json:"vip"`
	BuyCosts         []int64     `json:"buy_costs"`
	Robots           []RobotTeam `json:"robots"`
	RobotHeroes      []RobotHero `json:"robot_heroes"`
	FirstNames       []string    `json:"first_names"`
	LastNames        []string    `json:"last_names"`
}

func (c Catalog) Validate() error {
	profile := c.SchemaVersion == 1 && c.ContractID == ContractID && c.PolicyID == PolicyID && c.FunctionID == 4 && c.RequiredLevel == 10 && c.FreeTickets == 5 && c.BuyRestore == 5 &&
		c.CooldownSeconds == 300 && c.ResetCost == 50 && c.MatchHundredths == [3]int64{30, 50, 98} && c.CutoffSeconds == 75600 && c.FreezeEndSeconds == 77400 && c.RecordsMax == 10 &&
		c.MailTitle != "" && c.MailText != "" && c.MailSender != "" && len(c.Rewards) == 30 && len(c.VIP) == 16 && len(c.BuyCosts) > 0 && len(c.Robots) == RobotTeams && len(c.FirstNames) > 0 && len(c.LastNames) > 0
	if !profile {
		return fmt.Errorf("%w: catalog profile", ErrUnavailable)
	}
	var previous int64
	for i, r := range c.Rewards {
		if r.ID != int64(i+1) || r.Range <= previous || r.DailyCrystal < 0 || r.DailyMana < 0 || r.DailyArenaCoin < 0 || r.BestRankRate < 0 {
			return fmt.Errorf("%w: reward row %d", ErrUnavailable, i+1)
		}
		previous = r.Range
	}
	for i, v := range c.VIP {
		if v.Level != int64(i) || v.Purchases < 0 || v.Reset < 0 || v.Reset > 1 {
			return fmt.Errorf("%w: vip row %d", ErrUnavailable, i)
		}
	}
	heroes := c.robotHeroIndex()
	for i, team := range c.Robots {
		if team.Level < 1 || len(team.Heroes) == 0 || len(team.Heroes) > DefenseSlots {
			return fmt.Errorf("%w: robot team %d", ErrUnavailable, i+1)
		}
		for _, id := range team.Heroes {
			if _, ok := heroes[id]; !ok {
				return fmt.Errorf("%w: robot team %d hero %d", ErrUnavailable, i+1, id)
			}
		}
	}
	return nil
}

func (c Catalog) robotHeroIndex() map[int64]RobotHero {
	out := make(map[int64]RobotHero, len(c.RobotHeroes))
	for _, h := range c.RobotHeroes {
		out[h.ID] = h
	}
	return out
}

// RewardFor is the arena_reward row whose range covers the rank (Arena.getRangeID).
func (c Catalog) RewardFor(rank int64) (Reward, bool) {
	index := c.rangeIndex(rank)
	if index < 0 {
		return Reward{}, false
	}
	return c.Rewards[index], true
}

func (c Catalog) rangeIndex(rank int64) int {
	var lower int64
	for i, r := range c.Rewards {
		if rank > lower && rank <= r.Range {
			return i
		}
		lower = r.Range
	}
	return -1
}

// BestRankReward is Arena.getRankReward over rank_reward_diamond_new with the
// source minimum of 1 and ceiling; ranks beyond the table pay the minimum.
func (c Catalog) BestRankReward(oldBest, newBest int64) int64 {
	from, to := c.rangeIndex(oldBest), c.rangeIndex(newBest)
	if from < 0 || to < 0 || newBest >= oldBest {
		return 1
	}
	rangeOf := func(i int) int64 {
		if i < 0 {
			return 0
		}
		return c.Rewards[i].Range
	}
	var total int64
	for i := from; i >= to; i-- {
		upper, lower := rangeOf(i), rangeOf(i-1)
		if i == from {
			upper = oldBest
		}
		if i == to {
			lower = newBest
		}
		if from == to {
			upper, lower = oldBest, newBest
		}
		total += (upper - lower) * c.Rewards[i].BestRankRate
	}
	crystal := (total + 9999) / 10000
	if crystal == 0 {
		return 1
	}
	return crystal
}

func (c Catalog) Privilege(level int64) VIP {
	if level < 0 || level >= int64(len(c.VIP)) {
		return VIP{Level: level}
	}
	return c.VIP[level]
}

// BuyCost is refreshCost:buyArenaCost(n) for the n-th purchase of the day.
func (c Catalog) BuyCost(n int64) int64 {
	if n < 1 {
		return 0
	}
	if n > int64(len(c.BuyCosts)) {
		return c.BuyCosts[len(c.BuyCosts)-1]
	}
	return c.BuyCosts[n-1]
}

func (c Catalog) Team(team int64) (RobotTeam, bool) {
	if team < 1 || team > int64(len(c.Robots)) {
		return RobotTeam{}, false
	}
	return c.Robots[team-1], true
}

// RobotName is the private-policy display name from random_name parts 0 and 1.
func (c Catalog) RobotName(team int64) string {
	first := c.FirstNames[team%int64(len(c.FirstNames))]
	last := c.LastNames[(team/int64(len(c.FirstNames)))%int64(len(c.LastNames))]
	return first + " " + last
}

// RobotHeroParams are the TEMPLATE populate params of one robot hero. Source
// equip flags have no recovered item mapping, so robots field no equipment.
func (c Catalog) RobotHeroParams(id int64) (map[string]any, bool) {
	h, ok := c.robotHeroIndex()[id]
	if !ok {
		return nil, false
	}
	return map[string]any{"player_id": 0, "partner_id": h.PartnerID, "table_id": h.PartnerID, "lev": h.Level, "star": h.Star, "color": h.Quality,
		"skin_ids": map[string]any{}, "spirit_equip": []any{}, "spirit_item": []any{}, "equips": []any{0, 0, 0, 0, 0, 0}, "fumos": []any{0, 0, 0, 0, 0, 0},
		"skills": []any{1, 1, 1, 1, 1, 1}}, true
}

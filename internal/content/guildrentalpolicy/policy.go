// Package guildrentalpolicy is the immutable guild rental policy (docs/i9/
// I9_GUILD_POLICY_V1.json, compiled by tools/guild_rental_policy.py).
package guildrentalpolicy

import (
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"errors"
)

//go:embed generated/guild_rental_policy.json
var builtinJSON []byte

type Money struct {
	PriceForceDivisor          int64 `json:"price_force_divisor"`
	PriceFloorMana             int64 `json:"price_floor_mana"`
	HourlyInterestForceDivisor int64 `json:"hourly_interest_force_divisor"`
	RecallMinimumSeconds       int64 `json:"recall_minimum_seconds"`
	LevelUpCeiling             int64 `json:"level_up_ceiling"`
	GuildSharePercent          int64 `json:"guild_share_percent"`
}

type VIPLimit struct {
	VIP     int64 `json:"vip"`
	Lend    int64 `json:"lend"`
	LevelUp int64 `json:"level_up"`
}

// Mode is one borrow_modes row. StarCap -1 means the mode is uncapped.
type Mode struct {
	Key           string  `json:"key"`
	CampaignTypes []int64 `json:"campaign_types"`
	Enabled       bool    `json:"enabled"`
	StarCap       int64   `json:"star_cap"`
}

type DepartureMail struct {
	Sender string `json:"sender"`
	Title  string `json:"title"`
	Body   string `json:"body"`
}

type Policy struct {
	PolicyID        string        `json:"policy_id"`
	PolicyVersion   int64         `json:"policy_version"`
	Money           Money         `json:"money"`
	VIPLimits       []VIPLimit    `json:"vip_limits"`
	Modes           []Mode        `json:"modes"`
	Departure       DepartureMail `json:"departure_mail"`
	SourceVipSHA256 string        `json:"source_vip_sha256"`
}

type Builtin struct {
	Policy   Policy
	Revision string
}

func LoadBuiltin() (Builtin, error) {
	var p Policy
	if err := json.Unmarshal(builtinJSON, &p); err != nil {
		return Builtin{}, err
	}
	if err := p.Validate(); err != nil {
		return Builtin{}, err
	}
	sum := sha256.Sum256(builtinJSON)
	return Builtin{Policy: p, Revision: hex.EncodeToString(sum[:])}, nil
}

func (p Policy) Validate() error {
	if p.PolicyID != "I9_GUILD_POLICY_V1" || p.PolicyVersion != 1 {
		return errors.New("guild rental policy identity")
	}
	m := p.Money
	if m.PriceForceDivisor <= 0 || m.PriceFloorMana <= 0 || m.HourlyInterestForceDivisor <= 0 || m.RecallMinimumSeconds <= 0 || m.LevelUpCeiling < 0 || m.LevelUpCeiling > 5 {
		return errors.New("guild rental policy money")
	}
	if m.GuildSharePercent != 0 {
		return errors.New("guild rental policy guild share")
	}
	if len(p.VIPLimits) != 16 {
		return errors.New("guild rental policy vip rows")
	}
	for index, row := range p.VIPLimits {
		if row.VIP != int64(index) || row.Lend <= 0 || row.LevelUp < 0 || row.LevelUp > m.LevelUpCeiling {
			return errors.New("guild rental policy vip row")
		}
	}
	if len(p.Modes) == 0 {
		return errors.New("guild rental policy modes")
	}
	seen := map[int64]bool{}
	for _, mode := range p.Modes {
		if mode.Key == "" || len(mode.CampaignTypes) == 0 || mode.StarCap < -1 || mode.StarCap > 3 {
			return errors.New("guild rental policy mode")
		}
		for _, campaignType := range mode.CampaignTypes {
			if campaignType <= 0 || seen[campaignType] {
				return errors.New("guild rental policy campaign type")
			}
			seen[campaignType] = true
		}
	}
	if p.Departure.Sender == "" || p.Departure.Title == "" || p.Departure.Body == "" || p.SourceVipSHA256 == "" {
		return errors.New("guild rental policy departure mail")
	}
	return nil
}

// ModeRules maps campaign type to the row that governs borrowing.
func (p Policy) ModeRules() map[int64]Mode {
	out := make(map[int64]Mode, len(p.Modes))
	for _, mode := range p.Modes {
		for _, campaignType := range mode.CampaignTypes {
			out[campaignType] = mode
		}
	}
	return out
}

// StarCap is the bound a winning fight settles at; 0 means no cap.
func (p Policy) StarCap(campaignType int64) int64 {
	for _, mode := range p.Modes {
		for _, kind := range mode.CampaignTypes {
			if kind == campaignType && mode.StarCap >= 0 {
				return mode.StarCap
			}
		}
	}
	return 0
}

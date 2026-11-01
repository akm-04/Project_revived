// Package guildcampaignpolicy is the immutable Guild Campaign policy (docs/i9/
// I9_GUILD_POLICY_V1.json guild_campaign, compiled by tools/guild_campaign_policy.py).
package guildcampaignpolicy

import (
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"errors"
)

//go:embed generated/guild_campaign_policy.json
var builtinJSON []byte

// NoticeMail is C13's only source of the open and reset notice.
type NoticeMail struct {
	Enabled    bool   `json:"enabled"`
	OpenTitle  string `json:"open_title"`
	OpenBody   string `json:"open_body"`
	ResetTitle string `json:"reset_title"`
	ResetBody  string `json:"reset_body"`
}

type Policy struct {
	PolicyID              string     `json:"policy_id"`
	PolicyVersion         int64      `json:"policy_version"`
	AttemptsPerChapterDay int64      `json:"attempts_per_chapter_day"`
	PrepareSeconds        int64      `json:"prepare_seconds"`
	BattleSeconds         int64      `json:"battle_seconds"`
	RestSecondsOfDay      [2]int64   `json:"rest_seconds_of_day"`
	ApplicationsPerDay    int64      `json:"applications_per_day"`
	BossDamageRankFactor  int64      `json:"boss_damage_rank_multiplier"`
	NoticeMail            NoticeMail `json:"notice_mail"`
	GuildLogRetentionDays int64      `json:"guild_log_retention_days"`
	SourceMiscSHA256      string     `json:"source_misc_sha256"`
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
		return errors.New("guild campaign policy identity")
	}
	if p.AttemptsPerChapterDay <= 0 || p.ApplicationsPerDay <= 0 || p.PrepareSeconds <= 0 || p.BattleSeconds <= 0 {
		return errors.New("guild campaign policy counts")
	}
	if p.RestSecondsOfDay[0] < 0 || p.RestSecondsOfDay[0] >= p.RestSecondsOfDay[1] || p.RestSecondsOfDay[1] > 86400 {
		return errors.New("guild campaign policy rest window")
	}
	if p.BossDamageRankFactor != 2 || p.GuildLogRetentionDays <= 0 || p.SourceMiscSHA256 == "" {
		return errors.New("guild campaign policy profile")
	}
	if p.NoticeMail.Enabled && (p.NoticeMail.OpenTitle == "" || p.NoticeMail.OpenBody == "" || p.NoticeMail.ResetTitle == "" || p.NoticeMail.ResetBody == "") {
		return errors.New("guild campaign policy notice mail")
	}
	return nil
}

// InRestWindow reports whether a server-time seconds-of-day falls in the
// 05:00-08:00 GMT+8 window of rule 7 (C5).
func (p Policy) InRestWindow(secondsOfDay int64) bool {
	return secondsOfDay >= p.RestSecondsOfDay[0] && secondsOfDay < p.RestSecondsOfDay[1]
}

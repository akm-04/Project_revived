// Package guildteapolicy is the immutable Tea Party policy (docs/i9/
// I9_GUILD_POLICY_V1.json, compiled by tools/guild_tea_policy.py).
package guildteapolicy

import (
	_ "embed"
	"encoding/json"
	"errors"
)

//go:embed generated/guild_tea_policy.json
var builtinJSON []byte

type Policy struct {
	PolicyID                  string `json:"policy_id"`
	PolicyVersion             int64  `json:"policy_version"`
	RequestsPerDay            int64  `json:"requests_per_day"`
	NormalNeed                int64  `json:"normal_need"`
	SXNeed                    int64  `json:"sx_need"`
	DonorFriendMedalPerScroll int64  `json:"donor_friend_medal_per_scroll"`
}

func LoadBuiltin() (Policy, error) {
	var p Policy
	if err := json.Unmarshal(builtinJSON, &p); err != nil {
		return Policy{}, err
	}
	return p, p.Validate()
}

func (p Policy) Validate() error {
	if p.PolicyID != "I9_GUILD_POLICY_V1" || p.PolicyVersion != 1 {
		return errors.New("guild tea policy identity")
	}
	if p.RequestsPerDay != 1 || p.NormalNeed != 3 || p.SXNeed != 2 {
		return errors.New("guild tea policy request profile")
	}
	if p.DonorFriendMedalPerScroll <= 0 {
		return errors.New("guild tea policy donor reward")
	}
	return nil
}

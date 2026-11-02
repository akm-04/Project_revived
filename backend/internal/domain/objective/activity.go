package objective

import (
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/grant"
)

type ActivityRule struct {
	Period    string `json:"period"`
	Index     int64  `json:"index"`
	Medal     int64  `json:"medal"`
	GiftEXP   int64  `json:"gift_exp"`
	GiftMarch int64  `json:"gift_march"`
}
type ActivityGift struct {
	ID           int64      `json:"id"`
	Plan         grant.Plan `json:"plan"`
	VIPThreshold int64      `json:"vip_threshold"`
	VIPBonus     int64      `json:"vip_bonus"`
}
type ActivityCatalog struct {
	Rules []ActivityRule `json:"rules"`
	Gifts []ActivityGift `json:"gifts"`
}

func (c ActivityCatalog) Validate() error {
	if len(c.Rules) != 7 || len(c.Gifts) != 12 {
		return errors.New("invalid activity catalog profile")
	}
	gifts := map[int64]bool{}
	for _, g := range c.Gifts {
		if g.ID <= 0 || gifts[g.ID] || g.Plan.Source.PolicyVersion != "I9_ACTIVITY_CHESTS_V1" || len(g.Plan.Lines) == 0 || g.VIPThreshold < 0 || g.VIPThreshold > 15 || g.VIPBonus < 0 || g.VIPBonus > 0 && g.VIPThreshold == 0 {
			return errors.New("invalid activity gift")
		}
		gifts[g.ID] = true
		for _, line := range g.Plan.Lines {
			if err := line.Validate(); err != nil {
				return err
			}
		}
	}
	seen := map[string]bool{}
	for _, r := range c.Rules {
		size := int64(5)
		if r.Period == "WEEK" {
			size = 2
		} else if r.Period != "DAY" {
			return errors.New("invalid activity period")
		}
		key := fmt.Sprintf("%s:%d", r.Period, r.Index)
		if r.Index < 1 || r.Index > size || r.Medal <= 0 || !gifts[r.GiftEXP] || !gifts[r.GiftMarch] || seen[key] {
			return errors.New("invalid activity rule")
		}
		seen[key] = true
	}
	return nil
}
func (c ActivityCatalog) Reward(period string, index, level, maximum, vip int64) (grant.Plan, int64, error) {
	if err := c.Validate(); err != nil {
		return grant.Plan{}, 0, err
	}
	if level < 1 || maximum < level || vip < 0 || vip > 15 {
		return grant.Plan{}, 0, errors.New("invalid activity observation")
	}
	for _, rule := range c.Rules {
		if rule.Period != period || rule.Index != index {
			continue
		}
		id := rule.GiftEXP
		if level == maximum {
			id = rule.GiftMarch
		}
		for _, gift := range c.Gifts {
			if gift.ID == id {
				plan := gift.Plan
				plan.Lines = append([]grant.Line(nil), plan.Lines...)
				if vip >= gift.VIPThreshold && gift.VIPBonus > 0 {
					plan.Lines = append(plan.Lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "guild_coin", Amount: gift.VIPBonus})
				}
				return plan, rule.Medal, nil
			}
		}
	}
	return grant.Plan{}, 0, errors.New("unknown activity chest")
}

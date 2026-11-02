package privilege

import (
	"errors"
	"strconv"

	"gxb.local/backend/v2/internal/domain/identity"
)

// I9_COMMERCE_CHARGE_V1: a tap is a PRIVATE_POLICY grant, no payment exists (D455).
const (
	TapPolicy = "I10_CHARGE_TAP_V1"
	TapClass  = "PLAYER_TAP_PRESERVATION"

	CardNone      = ""
	CardMonth     = "MONTH"
	CardPrivilege = "PRIVILEGE"

	TuningGrant    = "GRANT"
	TuningDisabled = "DISABLED"

	secondsPerDay = 86400
)

var ErrChargeRefused = errors.New("charge refused")

type ChargeProduct struct {
	ID                int64  `json:"id"`
	Diamond           int64  `json:"diamond"`
	ExtraDiamond      int64  `json:"extra_diamond"`
	FirstExtraDiamond int64  `json:"first_extra_diamond"`
	Card              string `json:"card"`
	CardDays          int64  `json:"card_days"`
}

// VipAward is the gift of one VIP level (C11: vip.lua reward_item through gift.lua).
type VipAward struct {
	Level    int64   `json:"level"`
	GiftID   int64   `json:"gift_id"`
	Items    []int64 `json:"items"`
	ItemNums []int64 `json:"item_nums"`
	Crystal  int64   `json:"crystal"`
}

type ChargeCatalog struct {
	Policy            string          `json:"policy"`
	PrivilegeSkillMax int64           `json:"privilege_skill_max"`
	Products          []ChargeProduct `json:"products"`
	VipAwards         []VipAward      `json:"vip_awards"`
}

func (c ChargeCatalog) Validate() error {
	if c.Policy != TapPolicy || c.PrivilegeSkillMax < 0 || len(c.Products) == 0 || len(c.VipAwards) != 15 {
		return ErrUnavailable
	}
	seen := make(map[int64]struct{}, len(c.Products))
	for _, p := range c.Products {
		_, repeated := seen[p.ID]
		negative := p.Diamond < 0 || p.ExtraDiamond < 0 || p.FirstExtraDiamond < 0 || p.CardDays < 0
		cardMismatch := (p.Card == CardNone) != (p.CardDays == 0)
		unknownCard := p.Card != CardNone && p.Card != CardMonth && p.Card != CardPrivilege
		if p.ID <= 0 || repeated || negative || cardMismatch || unknownCard {
			return ErrUnavailable
		}
		seen[p.ID] = struct{}{}
	}
	for index, award := range c.VipAwards {
		itemsValid := len(award.Items) == len(award.ItemNums) && len(award.Items) > 0
		if itemsValid {
			for i, item := range award.Items {
				if item <= 0 || award.ItemNums[i] <= 0 {
					itemsValid = false
					break
				}
			}
		}
		if award.Level != int64(index+1) || award.GiftID <= 0 || award.Crystal < 0 || !itemsValid {
			return ErrUnavailable
		}
	}
	return nil
}

func (c ChargeCatalog) Product(id int64) (ChargeProduct, bool) {
	for _, p := range c.Products {
		if p.ID == id {
			return p, true
		}
	}
	return ChargeProduct{}, false
}

// ChargeOverride replaces the source values of one product. A nil field keeps the source value.
type ChargeOverride struct {
	Crystal  *int64 `json:"crystal,omitempty"`
	VIPXP    *int64 `json:"vip_xp,omitempty"`
	CardDays *int64 `json:"card_days,omitempty"`
}

// ChargeTuning is the operator overlay; an invalid one leaves the source policy (I11 writes it).
type ChargeTuning struct {
	Version  int64                     `json:"version"`
	Mode     string                    `json:"mode"`
	Products map[string]ChargeOverride `json:"products"`
}

func (t ChargeTuning) Validate() error {
	if t.Version < 1 || (t.Mode != TuningGrant && t.Mode != TuningDisabled) {
		return ErrUnavailable
	}
	for _, o := range t.Products {
		for _, v := range []*int64{o.Crystal, o.VIPXP, o.CardDays} {
			if v != nil && *v < 0 {
				return ErrUnavailable
			}
		}
	}
	return nil
}

type ChargeGrant struct {
	Crystal  int64
	VIPXP    int64
	Card     string
	CardDays int64
}

// DecideGrant applies C5: the first-buy bonus only on a product's first purchase; VIP adds diamond alone (D456).
func DecideGrant(p ChargeProduct, priorCount int64, t ChargeTuning, tuned bool) (ChargeGrant, error) {
	out := ChargeGrant{Crystal: p.Diamond + p.ExtraDiamond, VIPXP: p.Diamond, Card: p.Card, CardDays: p.CardDays}
	if priorCount == 0 {
		out.Crystal += p.FirstExtraDiamond
	}
	if tuned && t.Validate() == nil {
		if t.Mode == TuningDisabled {
			return ChargeGrant{}, ErrChargeRefused
		}
		out = out.tuned(t.Products[strconv.FormatInt(p.ID, 10)])
	}
	if out.Crystal == 0 && (out.Card == CardNone || out.CardDays == 0) {
		return ChargeGrant{}, ErrChargeRefused
	}
	return out, nil
}

func (g ChargeGrant) tuned(o ChargeOverride) ChargeGrant {
	if o.Crystal != nil {
		g.Crystal = *o.Crystal
	}
	if o.VIPXP != nil {
		g.VIPXP = *o.VIPXP
	}
	if o.CardDays != nil {
		g.CardDays = *o.CardDays
	}
	return g
}

// Cards holds epoch seconds; 0 means never held and expiry needs no write.
type Cards struct {
	MonthCardStart   int64 `json:"month_card_start"`
	MonthCardEnd     int64 `json:"month_card_end"`
	PrivilegeCardEnd int64 `json:"privilege_card_end"`
}

// Purchase is the stock 354 row; times are epoch seconds.
type Purchase struct {
	ChargeID    int64 `json:"charge_id"`
	ChargeCount int64 `json:"charge_count"`
	LastBuyTime int64 `json:"last_buy_time"`
}

// PlayerCharge is the bounded other-player read of C16.
type PlayerCharge struct {
	PlayerID identity.PlayerID `json:"player_id"`
	Charge   int64             `json:"charge"`
	VIPLevel int64             `json:"vip_level"`
}

// Extended applies D463: a held card adds days.
func (c Cards) Extended(card string, days, now int64) Cards {
	switch card {
	case CardMonth:
		if c.MonthCardEnd <= now {
			c.MonthCardStart = now
		}
		c.MonthCardEnd = max(now, c.MonthCardEnd) + days*secondsPerDay
	case CardPrivilege:
		c.PrivilegeCardEnd = max(now, c.PrivilegeCardEnd) + days*secondsPerDay
	}
	return c
}

func (c Cards) PrivilegeActive(now int64) bool { return c.PrivilegeCardEnd > now }

// LeftDays rounds up: the client shows a card with any time left.
func LeftDays(end, now int64) int64 {
	if end <= now {
		return 0
	}
	return (end - now + secondsPerDay - 1) / secondsPerDay
}

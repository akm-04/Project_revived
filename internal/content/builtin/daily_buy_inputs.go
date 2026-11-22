package builtin

import (
	"errors"
	"fmt"
)

// DailyBuyInputCatalog is the I9-11B compiled source bundle. It carries every
// stock item row so an unknown request item fails closed, the gift rows an item
// can reference, and the dropbox groups those gifts draw.
type DailyBuyInputCatalog struct {
	SchemaVersion    int                      `json:"schema_version"`
	PolicyID         string                   `json:"policy_id"`
	SourceRowCounts  DailyBuySourceRowCounts  `json:"source_row_counts"`
	Items            []DailyBuyItem           `json:"items"`
	Gifts            []DailyBuyGift           `json:"gifts"`
	Dropboxes        []DailyBuyDropbox        `json:"dropboxes"`
	VIP              []DailyBuyVIP            `json:"vip"`
	MonthlyPrivilege DailyBuyMonthlyPrivilege `json:"monthly_privilege"`
	RefreshCost      []DailyBuyRefreshCost    `json:"refresh_cost"`
	Misc             DailyBuyMisc             `json:"misc"`
	DailyConsume     []DailyBuyDailyConsume   `json:"daily_consume"`
}

type DailyBuySourceRowCounts struct {
	Items               int `json:"items"`
	GiftRowsReferenced  int `json:"gift_rows_referenced"`
	GiftRowsMalformed   int `json:"gift_rows_malformed"`
	DropboxesReferenced int `json:"dropboxes_referenced"`
	VIP                 int `json:"vip"`
	RefreshCost         int `json:"refresh_cost"`
	DailyConsume        int `json:"daily_consume"`
}

type DailyBuyItem struct {
	ID          int64   `json:"id"`
	Type        int64   `json:"type"`
	SubType     int64   `json:"sub_type"`
	Stack       int64   `json:"stack"`
	Energy      int64   `json:"energy"`
	SkillPoint  int64   `json:"skill_point"`
	Mana        int64   `json:"mana"`
	Crystal     int64   `json:"crystal"`
	MagicEnergy int64   `json:"magic_energy"`
	MagicDust   int64   `json:"magic_dust"`
	MagicLiquid int64   `json:"magic_liquid"`
	Level       int64   `json:"level"`
	Gifts       []int64 `json:"gifts"`
	OneInMore   []int64 `json:"one_in_more"`
}

type DailyBuyGift struct {
	ID             int64   `json:"id"`
	Items          []int64 `json:"items"`
	ItemNums       []int64 `json:"item_nums"`
	Drops          []int64 `json:"drops"`
	Equip          string  `json:"equip"`
	SummonID       int64   `json:"summon_id"`
	Crystal        int64   `json:"crystal"`
	Mana           int64   `json:"mana"`
	Energy         int64   `json:"energy"`
	VipExp         int64   `json:"vip_exp"`
	ArenaCoin      int64   `json:"arena_coin"`
	MarchCoin      int64   `json:"march_coin"`
	LuckyCoin      int64   `json:"lucky_coin"`
	FriendshipCoin int64   `json:"friendship_coin"`
	SkinFragment   int64   `json:"skin_fragment"`
	Exp            int64   `json:"exp"`
	Badge          int64   `json:"badge"`
	Soul           int64   `json:"soul"`
	Vip            int64   `json:"vip"`
	ExBadge        int64   `json:"ex_badge"`
	TutorCoin      int64   `json:"tutor_coin"`
	SkinCoin       int64   `json:"skin_coin"`
	SpiritEnergy   int64   `json:"spirit_energy"`
}

type DailyBuyDropbox struct {
	ID    int64              `json:"id"`
	Rolls []DailyBuyDropRoll `json:"rolls"`
}

type DailyBuyDropRoll struct {
	ID       int64 `json:"id"`
	ItemID   int64 `json:"item_id"`
	ItemNum  int64 `json:"item_num"`
	Rate     int64 `json:"rate"`
	RollType int64 `json:"roll_type"`
}

type DailyBuyVIP struct {
	Level     int64 `json:"level"`
	NumEnergy int64 `json:"num_energy"`
	NumMidas  int64 `json:"num_midas"`
	SkillBuy  int64 `json:"skill_buy"`
	SkillMax  int64 `json:"skill_max"`
}

type DailyBuyMonthlyPrivilege struct {
	NumEnergy int64 `json:"num_energy"`
	NumMidas  int64 `json:"num_midas"`
}

type DailyBuyRefreshCost struct {
	ID                     int64 `json:"id"`
	BuyEnergyCost          int64 `json:"buy_energy_cost"`
	BuyManaCost            int64 `json:"buy_mana_cost"`
	BuySkillCost           int64 `json:"buy_skill_cost"`
	BuyManaRatioMillionths int64 `json:"buy_mana_ratio_millionths"`
}

type DailyBuyMisc struct {
	BuyEnergyNum              int64   `json:"buy_energy_num"`
	EnergyMaxLimit            int64   `json:"energy_max_limit"`
	MidasBase                 int64   `json:"midas_base"`
	MidasLevelIncrease        int64   `json:"midas_level_increase"`
	MidasFloatUpBasisPoints   int64   `json:"midas_float_up_basis_points"`
	MidasFloatDownBasisPoints int64   `json:"midas_float_down_basis_points"`
	MidasCritTypes            []int64 `json:"midas_crit_types"`
	MidasCritRates            []int64 `json:"midas_crit_rates"`
}

type DailyBuyDailyConsume struct {
	ID    int64 `json:"id"`
	Cost  int64 `json:"cost"`
	Num   int64 `json:"num"`
	Value int64 `json:"value"`
}

// QualifyDailyBuyInputs validates the compiled bundle against the source
// counts and the tunables the 11B rules depend on.
func (c DailyBuyInputCatalog) QualifyDailyBuyInputs() error {
	if c.SchemaVersion != 1 || c.PolicyID != "I9_11B_DAILY_BUY_INPUTS_V1" {
		return errors.New("daily buy inputs: unqualified policy")
	}
	counts := c.SourceRowCounts
	if len(c.Items) != counts.Items || counts.Items != 5838 ||
		len(c.Gifts) != counts.GiftRowsReferenced || counts.GiftRowsReferenced != 2361 ||
		counts.GiftRowsMalformed != 7 ||
		len(c.Dropboxes) != counts.DropboxesReferenced || counts.DropboxesReferenced != 188 ||
		len(c.VIP) != 16 || len(c.RefreshCost) != 330 || len(c.DailyConsume) != 10 {
		return fmt.Errorf("daily buy inputs: source row count drift %+v", counts)
	}
	if c.Misc.BuyEnergyNum != 120 || c.Misc.EnergyMaxLimit != 500 || c.Misc.MidasBase != 20000 ||
		c.Misc.MidasLevelIncrease != 100 || c.Misc.MidasFloatUpBasisPoints != 500 ||
		c.Misc.MidasFloatDownBasisPoints != 0 ||
		len(c.Misc.MidasCritTypes) != 5 || len(c.Misc.MidasCritRates) != 5 ||
		c.Misc.MidasCritTypes[0] != 1 || c.Misc.MidasCritTypes[4] != 10 ||
		c.Misc.MidasCritRates[0] != 8000 || c.Misc.MidasCritRates[4] != 100 {
		return errors.New("daily buy inputs: golden-hand tunable drift")
	}
	if c.MonthlyPrivilege.NumEnergy != 4 || c.MonthlyPrivilege.NumMidas != 30 {
		return errors.New("daily buy inputs: monthly privilege drift")
	}
	if c.VIP[0].Level != 0 || c.VIP[0].NumEnergy != 1 || c.VIP[0].NumMidas != 1 ||
		c.VIP[0].SkillBuy != 0 || c.VIP[0].SkillMax != 10 || c.VIP[1].SkillBuy != 0 ||
		c.VIP[2].SkillBuy != 1 || c.VIP[2].SkillMax != 10 ||
		c.VIP[15].Level != 15 || c.VIP[15].NumEnergy != 16 || c.VIP[15].NumMidas != 300 ||
		c.VIP[15].SkillBuy != 1 || c.VIP[15].SkillMax != 80 {
		return errors.New("daily buy inputs: VIP ladder drift")
	}
	if c.RefreshCost[0].ID != 1 || c.RefreshCost[0].BuyEnergyCost != 50 || c.RefreshCost[0].BuyManaCost != 10 ||
		c.RefreshCost[0].BuySkillCost != 10 || c.RefreshCost[0].BuyManaRatioMillionths != 1000000 ||
		c.RefreshCost[len(c.RefreshCost)-1].ID != 330 || c.RefreshCost[len(c.RefreshCost)-1].BuySkillCost != 300 {
		return errors.New("daily buy inputs: refresh cost ladder drift")
	}
	for _, level := range c.VIP {
		if level.SkillBuy < 0 || level.SkillBuy > 1 || level.SkillMax < 0 {
			return errors.New("daily buy inputs: VIP skill tunable out of range")
		}
	}
	for _, cost := range c.RefreshCost {
		if cost.BuySkillCost <= 0 {
			return errors.New("daily buy inputs: refresh cost lacks buy_skill_cost")
		}
	}
	if c.DailyConsume[0].ID != 1 || c.DailyConsume[0].Cost != 50 || c.DailyConsume[0].Num != 1 || c.DailyConsume[0].Value != 10 {
		return errors.New("daily buy inputs: daily consume row drift")
	}
	items := make(map[int64]struct{}, len(c.Items))
	for _, item := range c.Items {
		if item.ID <= 0 {
			return errors.New("daily buy inputs: invalid item id")
		}
		if _, exists := items[item.ID]; exists {
			return errors.New("daily buy inputs: duplicate item id")
		}
		items[item.ID] = struct{}{}
	}
	gifts := make(map[int64]struct{}, len(c.Gifts))
	for _, gift := range c.Gifts {
		if gift.ID <= 0 {
			return errors.New("daily buy inputs: invalid gift id")
		}
		if _, exists := gifts[gift.ID]; exists {
			return errors.New("daily buy inputs: duplicate gift id")
		}
		gifts[gift.ID] = struct{}{}
		if len(gift.Items) != len(gift.ItemNums) {
			return errors.New("daily buy inputs: gift item shape drift")
		}
	}
	for _, box := range c.Dropboxes {
		if box.ID <= 0 || len(box.Rolls) == 0 {
			return errors.New("daily buy inputs: empty dropbox")
		}
		for _, roll := range box.Rolls {
			if roll.ItemID <= 0 || roll.ItemNum <= 0 || roll.Rate < 0 || roll.RollType != 1 {
				return errors.New("daily buy inputs: unqualified dropbox row")
			}
		}
	}
	return nil
}

package builtin

import (
	"encoding/json"
	"errors"
)

type IllusionCatalog struct {
	Schema                  int               `json:"schema_version"`
	Contract                string            `json:"contract_id"`
	PolicyID                string            `json:"policy_id"`
	Policy                  int               `json:"policy_version"`
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
	Campaigns               []json.RawMessage `json:"campaigns"`
	PersonRewards           []json.RawMessage `json:"person_rewards"`
	CommunityRewards        []json.RawMessage `json:"community_rewards"`
	BuyCosts                []int64           `json:"buy_costs"`
	BuyCaps                 []int64           `json:"buy_caps"`
}

func (c IllusionCatalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_ILLUSION_V1" || c.PolicyID != "I9_ILLUSION_POLICY_V1" || c.Policy != 1 {
		return errors.New("illusion catalog")
	}
	if c.OpenLevel != 65 || c.FreeChances != 5 || c.ChancesPerBuy != 5 || c.DamageCap != 12000000 || c.OpenSecond != 28800 || c.CloseSecond != 79080 || c.SettleSecond != 79200 || c.TeamHeroLimit != 5 || c.TeamPowerLimit != 30 || c.RewardPercentHundredths != 20 {
		return errors.New("illusion catalog profile")
	}
	if len(c.Campaigns) != 12 || len(c.PersonRewards) != 30 || len(c.CommunityRewards) != 15 || len(c.BuyCaps) != 16 || len(c.BuyCosts) < 13 {
		return errors.New("illusion catalog census")
	}
	if c.BuyCaps[0] != 0 || c.BuyCaps[1] != 0 || c.BuyCaps[2] != 0 || c.BuyCaps[3] != 1 || c.BuyCaps[15] != 13 {
		return errors.New("illusion catalog buy cap")
	}
	for level := 1; level < len(c.BuyCaps); level++ {
		if c.BuyCaps[level] < c.BuyCaps[level-1] || len(c.BuyCosts) < int(c.BuyCaps[len(c.BuyCaps)-1]) {
			return errors.New("illusion catalog buy cap drift")
		}
	}
	return nil
}
